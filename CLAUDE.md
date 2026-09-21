# CLAUDE.md

## What this is

A Shiny app for exploring paleotidal model outputs (tidal amplitude, stratification,
bed shear stress, tidal current) for NW Europe over the last 21k years. Rasters and
tidy tables are pre-processed; the app only reads them.

## Layout

- `global.R` — loads every dataset at startup into the global env (rasters via
  `readr::read_rds`, tables via `arrow::read_feather`, shapefiles via `sf::st_read`).
  Sourced automatically by Shiny before `ui.R`/`server.R`.
- `ui.R` / `server.R` — two-file Shiny app (no `app.R`). `server.R` is a bare
  `function(input, output, session)`.
- `R/` — auto-sourced by Shiny. `mod_*.R` are Shiny modules (`*_ui` / `*_server`
  pair using `moduleServer`); `fct_*.R` are plain helpers.
- `data/processed_data/` — the `.rds` / `.feather` files `global.R` expects.
  `data/raw_shape/` — shapefiles.
- `data_pre_processing/` — scripts that build `processed_data/`. Not run by the app.
- `notes/` — scratch experiments. Not loaded by the app. Ignore unless asked.
- `www/` — static assets (`style.css`, gifs, logos).

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

Loading all the data takes ~30s. Two bslib "Navigation containers expect..."
warnings are expected.

## Gotchas

- `.Renviron` holds AWS credentials and is gitignored. Never commit it or echo its
  contents.
- `global.R` loads everything eagerly, so startup is slow and memory-hungry. That's
  known; don't "fix" it as a side quest.
