# Build the app's runtime data for one region
#
# Turns the long feather tables and raster bricks written by data_pre_process.R
# into what the app actually reads:
#   data/app/<region>/cube.parquet  one row per (cell, year), one column per variable
#   data/app/<region>/static.rds    grid axes, layer bounds, coastline
#   www/layers/<region>/*.png       one pre-rendered map image per variable and year
#   www/layers/<region>/arrows_*    bed stress arrows per year, drawn by www/map_layers.js
#
# There is one folder per region and model run. build_region() does all of that
# for the first run (Paltide1, nw_europe). The second run (Paltide2) arrives as
# x/y/value ascii files in data/raw/Transfer2/, one per variable and year;
# build_paltide2() turns those into a region (nw_europe_p2, patagonia).
#
# The nw_europe inputs (data/processed_data/) were removed from the repo when
# this script was introduced; they are in git history (LFS) up to that commit.
#
# Run from the project root: Rscript data_pre_processing/build_backend.R

library(raster) # needed for `[[` on the saved RasterBrick objects
source("R/mod_map.R") # strat_cols, shared with the map legend

# modern coastline, cropped to the region plus the map's 10 degree pan margin. GSHHS
# intermediate resolution (~1 km): finer detail would not line up with the
# model's grid cells and only adds weight to every region switch.
crop_coast = function(xs, ys, margin = 10) {
  sf::sf_use_s2(FALSE)
  sf::st_read("./data/raw_shape/coastline/GSHHS_i_L1.shp", quiet = TRUE) |>
    sf::st_make_valid() |>
    sf::st_crop(xmin = max(min(xs) - margin, -180), xmax = min(max(xs) + margin, 180),
                ymin = max(min(ys) - margin, -85), ymax = min(max(ys) + margin, 85)) |>
    # the crop can leave stray points and lines on its edge
    sf::st_collection_extract("POLYGON")
}

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

  # Bed stress arrows -------------------------------------------------------

  # Every 2nd grid cell in each direction with stress above 0.1; the browser
  # thins these further when zoomed out. Four little-endian int16 per arrow:
  # 0-based column, 0-based row, u * 100, v * 100.
  arrow_stride = 2L
  arrow_cells = cube |>
    dplyr::mutate(ix = (cell - 1L) %% length(xs), iy = (cell - 1L) %/% length(xs)) |>
    dplyr::filter(ix %% arrow_stride == 0, iy %% arrow_stride == 0,
                  !is.na(BSS_u), !is.na(BSS_v), BSS_magnitude > 0.1)
  for (yr in 0:21) {
    one_year = arrow_cells[arrow_cells$year == yr, ]
    values = rbind(one_year$ix, one_year$iy, round(one_year$BSS_u * 100), round(one_year$BSS_v * 100))
    stopifnot(abs(values) < 2^15)
    writeBin(as.integer(values), file.path(layer_dir, sprintf("arrows_%02d.bin", yr)),
             size = 2, endian = "little")
  }
  jsonlite::write_json(list(xs = xs, ys = ys, stride = arrow_stride),
                       file.path(layer_dir, "arrow_axes.json"),
                       auto_unbox = TRUE, digits = NA)

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

  saveRDS(list(label = "NW European Shelf",
               model = "PALTIDE1",
               xs = xs,
               ys = ys,
               bounds = bounds,
               years = lapply(bounds, function(b) 0:21),
               raster_opts = raster_opts,
               coast = crop_coast(xs, ys),
               view = view),
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
            sum(file.size(list.files(layer_dir, pattern = "^arrows_.*\\.bin$", full.names = TRUE))) == nrow(arrow_cells) * 8)

  message(region, ": built ", cube_path, " (", round(file.size(cube_path) / 1e6, 1), " MB)")
}

# Map layers and cube for a Paltide2 region, from the ascii transfer in `dir`
# (x/y/value, one file per variable and year, e.g. ascii_bss/bss_07.ascii).
# The land/ice/water mask, ice thickness and RSL cover the whole grid;
# hydrodynamic output is cut to water >= 5 m on the shelf and sits on the same
# grid.
build_paltide2 = function(region, label, view, dir) {

  data_dir = file.path("data/app", region)
  layer_dir = file.path("www/layers", region)
  unlink(c(data_dir, layer_dir), recursive = TRUE)
  dir.create(data_dir, recursive = TRUE)
  dir.create(layer_dir, recursive = TRUE)

  read_var = function(folder, stem, year) {
    data.table::fread(file.path(dir, folder, sprintf("%s_%02d.ascii", stem, year)),
                      col.names = c("x", "y", "value"))
  }

  mask0 = read_var("ascii_landicewater", "mask_landicewater", 0)
  xs = sort(unique(mask0$x))
  ys = sort(unique(mask0$y))
  # coordinates are printed to 4 decimals, so match them as text, not floats
  cell_of = function(xyz) {
    (match(sprintf("%.4f", xyz$y), sprintf("%.4f", ys)) - 1L) * length(xs) +
      match(sprintf("%.4f", xyz$x), sprintf("%.4f", xs))
  }
  n_cells = length(xs) * length(ys)
  stopifnot(nrow(mask0) == n_cells)
  grid = data.frame(x = rep(xs, times = length(ys)), y = rep(ys, each = length(xs)))

  # Colours are baked in here; numeric domains must match map_layers (R/mod_map.R).
  # Values above a cap take the top colour. Land is grey (marked by a sentinel,
  # as NaN would not survive the raster round trip), off-shelf water with no
  # output is transparent.
  land = -9999
  land_col = "#bebebe"
  none_col = "#00000000"
  numeric_cols = function(palette, domain) {
    pal = leaflet::colorNumeric(palette = palette, domain = domain)
    function(v) {
      out = rep(none_col, length(v))
      ok = !is.na(v) & v != land
      out[ok] = pal(pmin(pmax(v[ok], domain[1]), domain[2]))
      out[!is.na(v) & v == land] = land_col
      out
    }
  }
  layers = list(
    bss90 = list(folder = "ascii_bss", stem = "bss", cols = numeric_cols("viridis", c(0, 5))),
    strat = list(folder = "ascii_stratification", stem = "strat",
                 cols = function(v) {
                   ifelse(is.na(v), none_col,
                          ifelse(v == land, land_col, strat_cols$PALTIDE2[pmax(v, 1)]))
                 }),
    amp = list(folder = "ascii_m2amplitude", stem = "m2amplitude", cols = numeric_cols("viridis", c(0, 5))),
    range = list(folder = "ascii_springtidalrange", stem = "springtidalrange", cols = numeric_cols("viridis", c(0, 11))),
    depth = list(folder = "ascii_water_depth", stem = "h", cols = numeric_cols("viridis", c(0, 500))),
    # RSL covers land too, so no grey
    rsl = list(folder = "ascii_rsl", stem = "rsl", cols = numeric_cols("RdBu", c(-150, 150))),
    icethk = list(folder = "ascii_mask_ice", stem = "mask_ice", cols = numeric_cols("Blues", c(0, 2500)))
  )

  bounds = list()
  raster_opts = NULL
  render = function(prefix, year, values, colors) {
    layer = raster::rasterFromXYZ(cbind(grid, value = values), crs = "EPSG:4326")
    # nearest neighbour keeps the coast and the categories sharp
    call = leaflet::addRasterImage(leaflet::leaflet(), layer, colors = colors,
                                   method = "ngb", maxBytes = Inf)$x$calls[[1]]
    png = jsonlite::base64_dec(sub("^data:image/png;base64,", "", call$args[[1]]))
    writeBin(png, file.path(layer_dir, sprintf("%s_%02d.png", prefix, year)))
    bounds[[prefix]] <<- call$args[[2]]
    raster_opts <<- call$args[[5]]
  }

  # The cube holds every cell on the shelf (with model output) in at least one
  # year, with all its years, so its timeseries is complete. Ice and off-shelf
  # cells are left out to keep the file small enough for git (< 100 MB).
  wet_cells = sort(unique(unlist(lapply(0:21, function(year) {
    cell_of(read_var("ascii_water_depth", "h", year))
  }))))

  cube = vector("list", 22)
  checks = vector("list", 22)
  for (year in 0:21) {
    xyz = read_var("ascii_landicewater", "mask_landicewater", year)
    mask = rep(NA_integer_, n_cells)
    mask[cell_of(xyz)] = as.integer(xyz$value)
    stopifnot(!anyNA(mask), mask %in% 1:3)
    full = list()
    for (prefix in names(layers)) {
      xyz = read_var(layers[[prefix]]$folder, layers[[prefix]]$stem, year)
      v = rep(NA_real_, n_cells)
      v[cell_of(xyz)] = xyz$value
      full[[prefix]] = v[wet_cells]
      # ice thickness 0 means no ice
      shown = if (prefix == "icethk") ifelse(v > 0, v, NA) else v
      if (prefix != "rsl") shown[mask == 1 & is.na(shown)] = land
      render(prefix, year, shown, layers[[prefix]]$cols)
      checks[[year + 1]][[prefix]] = xyz[sample(nrow(xyz), 50)]
    }
    render("ice", year, ifelse(mask == 3, 1, NA),
           function(v) ifelse(is.na(v), none_col, "aliceblue"))

    cube[[year + 1]] = data.table::data.table(
      cell = wet_cells, year = year,
      land_type = c("land", "water", "ice")[mask[wet_cells]],
      elevation_amplitude = full$amp,
      spring_range = full$range,
      rsl = full$rsl,
      strat = as.integer(full$strat),
      BSS_magnitude = full$bss90,
      ice_thickness = full$icethk,
      depth = full$depth
    )
    message(region, ": year ", year, " done")
  }

  # Cube --------------------------------------------------------------------

  cube = data.table::rbindlist(cube)
  data.table::setorder(cube, cell, year)
  cube[, `:=`(x = xs[(cell - 1L) %% length(xs) + 1L], y = ys[(cell - 1L) %/% length(xs) + 1L])]
  data.table::setcolorder(cube, c("cell", "x", "y", "year"))

  # cm (or 0.1 m) precision as float32 halves the file, again for git's limit
  digits = c(elevation_amplitude = 2, spring_range = 2, rsl = 2, BSS_magnitude = 2,
             ice_thickness = 1, depth = 1)
  for (col in names(digits)) data.table::set(cube, j = col, value = round(cube[[col]], digits[[col]]))
  tbl = arrow::arrow_table(cube)
  for (col in names(digits)) tbl[[col]] = tbl[[col]]$cast(arrow::float32())
  cube_path = file.path(data_dir, "cube.parquet")
  arrow::write_parquet(tbl, cube_path, compression = "zstd", chunk_size = 22L * 4096L)
  n_rows = nrow(cube)
  rm(cube, tbl)
  gc()

  # Static bits -------------------------------------------------------------

  saveRDS(list(label = label,
               model = "PALTIDE2",
               xs = xs,
               ys = ys,
               bounds = bounds,
               years = lapply(bounds, function(b) 0:21),
               raster_opts = raster_opts,
               coast = crop_coast(xs, ys),
               view = view),
          file.path(data_dir, "static.rds"))

  # Checks ------------------------------------------------------------------

  con = DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  stopifnot(DBI::dbGetQuery(con, glue::glue("SELECT count(*) AS n FROM read_parquet('{cube_path}')"))$n == n_rows)

  # random source values must come back from the cube, looked up by cell
  cube_col = c(bss90 = "BSS_magnitude", strat = "strat", amp = "elevation_amplitude",
               range = "spring_range", depth = "depth", rsl = "rsl", icethk = "ice_thickness")
  for (year in 0:21) {
    for (prefix in names(cube_col)) {
      src = checks[[year + 1]][[prefix]]
      src$cell = cell_of(src)
      src = src[src$cell %in% wet_cells, ]
      for (i in seq_len(nrow(src))) {
        got = DBI::dbGetQuery(con,
                              glue::glue("SELECT * FROM read_parquet('{cube_path}') WHERE cell = ? AND year = ?"),
                              params = list(src$cell[i], year))
        stopifnot(nrow(got) == 1,
                  abs(got$x - src$x[i]) < 1e-6, abs(got$y - src$y[i]) < 1e-6,
                  abs(got[[cube_col[[prefix]]]] - src$value[i]) <= 0.05 + 1e-4 * abs(src$value[i]))
      }
    }
  }
  stopifnot(length(list.files(layer_dir, pattern = "\\.png$")) == (length(layers) + 1) * 22)

  message(region, ": built ", cube_path, " (", round(file.size(cube_path) / 1e6, 1), " MB, ",
          n_rows, " rows)")
}

# the nw_europe inputs are no longer in the repo, see the top of this file
if (dir.exists("./data/processed_data")) {
  build_region("nw_europe",
               in_dir = "./data/processed_data",
               view = list(lng = -4, lat = 56, zoom = 5.25))
}

transfer2 = "./data/raw/Transfer2"

build_paltide2("nw_europe_p2", "NW European Shelf",
               view = list(lng = -4, lat = 56, zoom = 5.25),
               dir = file.path(transfer2, "NWESS"))

build_paltide2("patagonia", "Patagonian Shelf",
               view = list(lng = -62, lat = -46, zoom = 4.5),
               dir = file.path(transfer2, "Patagonia"))
