# CLAUDE.md

## What this is

A Shiny app for exploring paleotidal model outputs (tidal amplitude, stratification,
bed shear stress, tidal current) for NW Europe over the last 21k years. Map images and
a per-cell table are pre-built; the app only reads them.

## Layout

- `global.R` — sets `region`, reads `static` (grid axes, layer bounds, coastline) and
  opens `con`, a DuckDB connection with a `cube` view over the region's
  parquet file. Sourced automatically by Shiny before `ui.R`/`server.R`.
- `ui.R` / `server.R` — two-file Shiny app (no `app.R`). `server.R` is a bare
  `function(input, output, session)`.
- `R/` — auto-sourced by Shiny. `mod_*.R` are Shiny modules (`*_ui` / `*_server`
  pair using `moduleServer`); `fct_*.R` are plain helpers.
- `data/app/<region>/` — `cube.parquet` (one row per grid cell and year, one column
  per variable, sorted by `cell`) and `static.rds`. `data/raw_shape/` — shapefiles.
- `www/layers/<region>/` — one pre-rendered PNG per variable and year
  (`amp_00.png` … `ice_21.png`) and the bed stress arrows per year
  (`arrows_00.bin` …, plus `arrow_axes.json`), served as static files.
- `data_pre_processing/` — not run by the app. `build_backend.R` builds `data/app/` and
  `www/layers/` from the long tables and raster bricks that `data_pre_process.R`
  writes. Those inputs are no longer in the repo (git history only).
- `notes/` — scratch experiments. Not loaded by the app. Ignore unless asked.
- `www/` — static assets (`style.css`, `map_layers.js`, logos).

## Conventions

- Namespace-qualify package calls (`bslib::card()`, `leaflet::leaflet()`) rather than
  `library()`. `shiny` itself is the exception — its functions are used bare.
- Native pipe `|>`, and `=` for assignment in app code (`<-` appears in older helpers;
  match the file you're in).
- New UI piece → new `R/mod_<name>.R` with a `<name>_ui(id)` / `<name>_server(id, ...)`
  pair, wired up in `ui.R` and `server.R`. Modules pass reactives to each other as
  arguments, not via the global env.
- The map is one `leaflet` output owned by `server.R`; `mod_map.R` updates it through
  the `map_proxy` reactive it's handed. Don't create a second map output.
- Map layers are swapped by URL, not rendered in R. The swap happens in
  `www/map_layers.js`, which keeps the old image up until the new one has loaded.
  The same file draws the bed stress arrows on a canvas, thinning them by zoom.
  Layer colours are baked into the PNGs, so a palette change means editing
  `build_backend.R` and rebuilding, and keeping the legend domains in `map_layers`
  (`R/mod_map.R`) in step.
- Per-cell data comes from one query, `SELECT * FROM cube WHERE cell = ?`. Don't read
  the parquet file into memory.

## R and packages

R 4.6.1, dependencies pinned with renv.

- After cloning or pulling a new `renv.lock`: `renv::restore()`.
- After adding a package: `renv::snapshot()` and commit `renv.lock`.
- Check state with `renv::status()`; it should say the project is consistent.
- `renv/library/` is not committed. `renv.lock`, `renv/activate.R`, and
  `renv/settings.json` are.

## Checks

There is no test suite. Before committing, confirm the app still loads:

```sh
Rscript -e 'library(shiny); source("global.R"); invisible(lapply(list.files("R", full.names=TRUE), source)); source("ui.R"); stopifnot(is.function(source("server.R")$value))'
```

It takes a few seconds. Two bslib "Navigation containers expect..." warnings and a
DuckDB note about `~/.duckdb` are expected.

## Gotchas

- `.Renviron` holds AWS credentials and is gitignored. Never commit it or echo its
  contents.
- The map tab is hidden at startup, so `map_proxy` waits for `input$map_zoom` before
  it resolves. Proxy calls made earlier would be silently dropped.
