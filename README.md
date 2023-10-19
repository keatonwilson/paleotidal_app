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
   - `raw/` contains data layers used by the app. Each file is numbered from 0-21, indicating thousands of years before present and contains a 431 by 313 matrix
     - `alt/` contains 22 .txt files of  
     - `amp/` contains 22 .txt files of tidal amplitude of M2 constituent
     - `bss/` contains 42 .txt files of bed shear stress
       - 22 files of the V component (positive eastward)
       - 22 files of the U component (positive northward)
     - `ice/` contains 22 .txt files of the ice mask
     - `str/` contains 22 .txt files of stratification using M2 constituent
     - `vel/` contains 22 .txt files of tidal velocity of M2 constituent
     
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
