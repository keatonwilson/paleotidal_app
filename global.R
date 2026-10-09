
# Data load ---------------------------------------------------------------

# Everything read here is built by data_pre_processing/build_backend.R.
# One folder per region; the first is the one shown at startup.
regions = list.files("data/app")

# per region: map layer bounds and years, coastline, and the grid axes if it
# has a cube
statics = lapply(setNames(regions, regions), function(region) {
  readRDS(file.path("data/app", region, "static.rds"))
})

# per-cell values for the timeseries and download, looked up on click
con = DBI::dbConnect(duckdb::duckdb())
# keeps the parquet footer between queries; halves lookup time
DBI::dbExecute(con, "SET parquet_metadata_cache = true")
for (region in regions) {
  cube_path = file.path("data/app", region, "cube.parquet")
  if (file.exists(cube_path)) {
    DBI::dbExecute(con, glue::glue("CREATE VIEW cube_{region} AS SELECT * FROM read_parquet('{cube_path}')"))
  }
}
shiny::onStop(function() DBI::dbDisconnect(con, shutdown = TRUE))
