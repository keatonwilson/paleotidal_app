# Build the app's runtime data for one region
#
# Turns the long feather tables and raster bricks written by data_pre_process.R
# into what the app actually reads:
#   data/app/<region>/cube.parquet  one row per (cell, year), one column per variable
#   data/app/<region>/static.rds    grid axes, layer bounds, coastline, bss arrows
#   www/layers/<region>/*.png       one pre-rendered map image per variable and year
#
# The nw_europe inputs (data/processed_data/) were removed from the repo when
# this script was introduced; they are in git history (LFS) up to that commit.
#
# Run from the project root: Rscript data_pre_processing/build_backend.R

library(raster) # needed for `[[` on the saved RasterBrick objects

build_region = function(region, in_dir, view) {

  data_dir = file.path("data/app", region)
  layer_dir = file.path("www/layers", region)
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(layer_dir, recursive = TRUE, showWarnings = FALSE)

  # Cube --------------------------------------------------------------------

  read_tbl = function(file) arrow::read_feather(file.path(in_dir, file))
  amp = read_tbl("amp_data.feather")
  rsl = read_tbl("rsl.feather")
  vel = read_tbl("vel.feather")
  strat = read_tbl("strat.feather")
  bss = read_tbl("bss.feather")

  # the tables share one row order, so the wide table is a column bind
  for (tbl in list(rsl, vel, strat, bss)) {
    stopifnot(identical(tbl$x, amp$x), identical(tbl$y, amp$y), identical(tbl$year, amp$year))
  }
  stopifnot(identical(rsl$land_type, amp$land_type), identical(vel$land_type, amp$land_type))

  xs = sort(unique(amp$x))
  ys = sort(unique(amp$y))

  cube = tibble::tibble(
    cell = (match(amp$y, ys) - 1L) * length(xs) + match(amp$x, xs),
    x = amp$x,
    y = amp$y,
    year = as.integer(amp$year),
    land_type = amp$land_type,
    elevation_amplitude = amp$value,
    rsl = rsl$value,
    vel = vel$value,
    strat = strat$value,
    BSS_u = bss$u,
    BSS_v = bss$v,
    BSS_magnitude = bss$uv
  ) |>
    dplyr::arrange(cell, year)

  # sorted by cell with small row groups, so a one-cell lookup reads one group
  cube_path = file.path(data_dir, "cube.parquet")
  arrow::write_parquet(cube, cube_path, compression = "zstd", chunk_size = 22L * 4096L)

  # Map layers --------------------------------------------------------------

  # Renders a layer as the app used to on every slider move, and keeps the PNG
  # instead of sending it. Numeric domains are fixed and must match the legend
  # domains in map_layers (R/mod_map.R).
  bounds = list()
  raster_opts = NULL
  render_layers = function(prefix, brick, pal_for) {
    for (year in 0:21) {
      layer = brick[[grep(glue::glue("^X{year}_"), names(brick))]]
      call = leaflet::addRasterImage(leaflet::leaflet(), layer, colors = pal_for(layer))$x$calls[[1]]
      png = jsonlite::base64_dec(sub("^data:image/png;base64,", "", call$args[[1]]))
      writeBin(png, file.path(layer_dir, sprintf("%s_%02d.png", prefix, year)))
      bounds[[prefix]] <<- call$args[[2]]
      raster_opts <<- call$args[[5]]
    }
  }
  read_brick = function(file) readr::read_rds(file.path(in_dir, file))

  render_layers("amp", read_brick("amp_raster.rds"), function(layer) {
    leaflet::colorNumeric(palette = "viridis", domain = c(0, 5), na.color = "#bebebe")
  })
  render_layers("vel", read_brick("vel_raster.rds"), function(layer) {
    leaflet::colorNumeric(palette = "viridis", domain = c(0, 2.5), na.color = "#bebebe")
  })
  render_layers("strat", read_brick("strat_raster.rds"), function(layer) {
    leaflet::colorFactor(palette = rev(c("#43A2CA", "#A8DDB5", "#f1ffed")),
                         domain = raster::values(layer),
                         na.color = "#bebebe",
                         reverse = TRUE)
  })
  render_layers("bss", read_brick("bss_raster.rds"), function(layer) {
    leaflet::colorNumeric(palette = "viridis", domain = c(0, 15), na.color = "#bebebe")
  })
  render_layers("ice", read_brick("ice_raster.rds"), function(layer) "aliceblue")

  # Static bits -------------------------------------------------------------

  # modern coastline, cropped to the region plus a margin for panning
  sf::sf_use_s2(FALSE)
  margin = 30
  coast = sf::st_read("./data/raw_shape/coastline/GSHHS_l_L1.shp", quiet = TRUE) |>
    sf::st_make_valid() |>
    sf::st_crop(xmin = max(min(xs) - margin, -180), xmax = min(max(xs) + margin, 180),
                ymin = max(min(ys) - margin, -85), ymax = min(max(ys) + margin, 85))

  # bss arrows: one sf of two-point lines per year, so the app adds them in one call
  polylines = read_tbl("bss_polylines.feather")
  arrows = purrr::map(0:21, function(yr) {
    one_year = polylines[polylines$year == yr, ]
    lines = split(one_year[, c("x", "y")], droplevels(one_year$id)) |>
      purrr::map(function(pts) sf::st_linestring(as.matrix(pts)))
    sf::st_sf(geometry = sf::st_sfc(lines, crs = 4326))
  })

  saveRDS(list(xs = xs,
               ys = ys,
               bounds = bounds,
               raster_opts = raster_opts,
               coast = coast,
               view = view,
               arrows = arrows),
          file.path(data_dir, "static.rds"))

  # Checks ------------------------------------------------------------------

  con = DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  stopifnot(DBI::dbGetQuery(con, glue::glue("SELECT count(*) AS n FROM read_parquet('{cube_path}')"))$n == nrow(amp))

  # random source rows must come back unchanged, looked up by coordinate
  for (i in sample(nrow(amp), 500)) {
    got = DBI::dbGetQuery(con,
                          glue::glue("SELECT * FROM read_parquet('{cube_path}') WHERE x = ? AND y = ? AND year = ?"),
                          params = list(amp$x[i], amp$y[i], amp$year[i]))
    stopifnot(nrow(got) == 1,
              identical(got$land_type, amp$land_type[i]),
              identical(c(got$elevation_amplitude, got$rsl, got$vel, got$strat, got$BSS_u, got$BSS_v, got$BSS_magnitude),
                        c(amp$value[i], rsl$value[i], vel$value[i], strat$value[i], bss$u[i], bss$v[i], bss$uv[i])))
  }
  stopifnot(length(list.files(layer_dir, pattern = "\\.png$")) == 5 * 22,
            sum(purrr::map_int(arrows, nrow)) == nrow(polylines) / 2)

  message(region, ": built ", cube_path, " (", round(file.size(cube_path) / 1e6, 1), " MB)")
}

build_region("nw_europe",
             in_dir = "./data/processed_data",
             view = list(lng = -4, lat = 56, zoom = 5.25))
