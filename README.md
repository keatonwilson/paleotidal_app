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
