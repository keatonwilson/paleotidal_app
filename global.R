
# Data load ---------------------------------------------------------------

# Everything read here is built by data_pre_processing/build_backend.R.
# One region for now; when a second arrives this becomes an input.
region = "nw_europe"

# grid axes, map layer bounds, coastline, bss arrows
static = readRDS(file.path("data/app", region, "static.rds"))

# per-cell values for the timeseries and download, looked up on click
con = DBI::dbConnect(duckdb::duckdb())
# keeps the parquet footer between queries; halves lookup time
DBI::dbExecute(con, "SET parquet_metadata_cache = true")
DBI::dbExecute(con, glue::glue("CREATE VIEW cube AS SELECT * FROM read_parquet('data/app/{region}/cube.parquet')"))
shiny::onStop(function() DBI::dbDisconnect(con, shutdown = TRUE))
