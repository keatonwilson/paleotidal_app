# Paleotidal Visualization Shiny Application

[![DOI](https://zenodo.org/badge/649434353.svg)](https://zenodo.org/doi/10.5281/zenodo.10020155)


A tool built in shiny to explore ocean-based models going back 21k
years.

## Description

Generally, this app is designed to allow users to explore four main
datasets in a spatial/map format that represent the outputs of modeled
data. Users can visualize how different modeled outputs have changed
over time by using slider controls or through an animation, which
trigger updates on the map portion of the app. In addition, users can
zoom to a particular area of the map, click individual cells to get more
granular data, and choose some specifics/thresholds associated with
particular data sets. The app will serve as a visualization
tool for nonmodelers.

## Test deployment

A preview of `main` runs at <https://keatonwilson-paltide-v2.hf.space>
(Hugging Face Space: <https://huggingface.co/spaces/keatonwilson/paltide_v2>).
It redeploys on every push to `main`, and the first visit after it has
been idle takes about a minute to wake up.

## Outstanding issues (PALTIDE2 round 2)

Status as of 2026-11-23. Round 2 is waiting on corrected files and answers from
Sophie. The questions below are in an email drafted to her on 2026-11-20.

### Where the data is

The PALTIDE2 transfer delivered on 2026-11-19 is in `data/raw/Transfer2/{NWESS,Patagonia}`.
That folder is gitignored and exists on Keaton's machine only. Each region has the
8 `ascii_*` folders that `build_paltide2()` reads (22 years each) and an
`ascii_bssvectors/` folder of bed stress vectors (lon/lat/u/v, 22 years each).
The vectors come from the second OneDrive download (`OneDrive_1_11-19-2026-2`),
because the first download had only years 00-17 for Patagonia.

### Blocked on Sophie

- **#114 NWESS 10 ka BP slice.** The delivered files are not the corrected slice.
  Year 10 water depth has 463,543 wet cells and a mean depth of 150.4 m, the same as
  year 8. The count should fall between year 9 (430,689) and year 11 (399,620).
  The year 10 depth, bss, amplitude and stratification match the committed
  `nw_europe_p2` cube to rounding. The NWESS bed stress vectors show the same jump
  at year 10. Nothing was rebuilt.
- **NWESS RSL at 20 ka BP** (no issue yet). About 416,000 cells move more than 50 m
  between years 19 and 20, and about 1% move 120-190 m. Year 21 reverses most of it.
  The regional mean goes -56, -38, -47 m. Question for Sophie: is this real?
- **#115 Patagonia land mask.** The diagonal streak is in the input
  `mask_landicewater`. It's a line of cells deep inland that are marked water
  (value 2) but have no depth. One runs from about (-69.2, -42.0) to
  (-67.0, -39.7), and there are about 3,000 in the box we checked. A rebuild from
  the current files is byte-identical to what's committed. One possible stopgap is
  to treat these cells as land in the build. It hasn't been applied, because it
  would be our workaround and not the model's correction. The `issue-115-patagonia-mask`
  branch has an unpushed commit that stops `build_paltide2()` when input folders
  are missing, and lets `build_backend.R` take region names as arguments.
- **Patagonia vector gaps** (#113, PR #118, merged). The vector files leave out 1.5% (0 ka)
  to 6% (21 ka) of the shelf cells that have bss90 values. About 80% of those cells
  are above the 0.1 arrow threshold, and some reach 20-25 N/m². Question for Sophie:
  are these left out on purpose?

### Merged, not yet viewed in a browser

PRs #116, #117, #118 and #120 are merged into `main`. The load check passes on `main`,
but none of this has been looked at in a running app yet.

- **#116 (#112), strat colours.** The pixel check passes. A corrected NWESS delivery
  means a rebuild, which uses the new `strat_cols`.
- **#117 (#111), white ice and hatched no-output cells.** The hatch (`#d3d3d3` on
  `#ddd`) may be too faint, and the hatched legend swatch is untested. Everything
  outside the model grid is hatched too. The technique for #109 (ice on the RSL tab)
  is still open, and dropping the ice overlay there avoids the question.
- **#118 (#113), PALTIDE2 bed stress arrows.** The vector signs were kept. PALTIDE2's
  u, v point opposite to PALTIDE1's on shared cells (median 180°), so the build
  negates them. The NWESS 10 ka arrows come from the bad slice. If
  `ascii_bssvectors/` is missing, `build_paltide2()` writes no arrows and doesn't
  fail, so check that it's present before any rebuild.
- **#120 (#107, #108), selection card layout and time series markers.** The coastline
  toggle is absolutely positioned to line up with the play button, so check it at
  narrow widths and in dark mode. Issues #107 and #108 are still open on GitHub
  because #120 doesn't close them. #109 was not addressed.

### When Sophie's files arrive

1. Compare the new files with `data/raw/Transfer2` before replacing anything. For
   NWESS, check the year 10 wet-cell count and RSL years 19-21. For Patagonia,
   check the mask along the streak above.
2. Replace the affected folders. Keep `ascii_bssvectors/` in place, or replace it
   if new vectors come with the delivery.
3. Rebuild with `Rscript data_pre_processing/build_backend.R` (with the #115
   branch merged, you can pass `nw_europe_p2` or `patagonia` to build just one),
   then rerun the load check in `CLAUDE.md`.
4. Check the Patagonia PNGs for the streak, and check that the arrows still exist
   for every year.

## Getting Started

```         
git clone https://github.com/keatonwilson/paleotidal_app.git
```

### Dependencies

-   Package dependencies (and R) are handled via
    [renv](https://rstudio.github.io/renv/index.html). Run
    `renv::restore()` to get started after cloning.
    
### File structure

`data/`
   - `app/<region>/` is everything the app reads at runtime, built by `data_pre_processing/build_backend.R`
     - `cube.parquet` holds one row per grid cell and time step (0-21 thousand years before present) with a column per model variable. It is queried with DuckDB when the map is clicked.
     - `static.rds` holds the grid axes and coastline
   - `raw_shape/` contains the source shapefiles

`www/layers/<region>/` contains one pre-rendered map image per variable and time step, and the bed stress arrows for each time step

`R/`
   - `mod_about_tab.R`
   - `mod_card.R`
   - `mod_example.R`
   
`server.R`

`ui.R`

### Deployed App

The app is not currently deployed. Testing version on shinyapps.io will
be linked here when ready.

### Help & Authors

For help, contact [Keaton Wilson](mailto:keatonwilson@me.com) or [Jessica
Guo](mailto:jessicaguo@arizona.edu).

### Version History

-   0.1 - in development
    -   See [commit
        change](https://github.com/keatonwilson/paleotidal_app/commits/main)
        or [release
        history](https://github.com/keatonwilson/paleotidal_app/releases)

### License

This project is current licensed privately, and is not available for
distribution.

### Acknowledgments

Inspiration, code snippets, etc. \*
[awesome-readme](https://github.com/matiassingers/awesome-readme)
