library(raster)
library(terra)
library(tidyverse)
# library(sp)
library(leaflet)

# Sandbox to make leaflet plots locally before connecting to app

ice_raster = readr::read_rds("./data/processed_data/ice_raster.rds")

# Start with veolocity
vel_raster = readr::read_rds("./data/processed_data/vel_raster.rds")
shape_1 = sf::st_read("./data/raw_shape/coastline/GSHHS_l_L1.shp")

leaflet() |> 
  leaflet::setView(lng = -4, lat = 56, zoom = 4.5) |> 
  addTiles() |> 
  addRasterImage(vel_raster[[21]], opacity = 0.8, colors = "viridis") |> 
  addRasterImage(ice_raster[[21]]) |>
  addPolygons(data = shape_1, color = "black", weight = 1,
              opacity = 1, fillOpacity = 0) |> 
  clearShapes()

# Test strat
strat_raster = readr::read_rds("./data/processed_data/strat_raster.rds")

color_vec <- rev(RColorBrewer::brewer.pal(3, "GnBu"))
RColorBrewer::display.brewer.pal(3, "GnBu")

pal <- colorFactor(palette = "GnBu",
                   domain = values(strat_raster[[1]]),
                   na.color = "black")

leaflet() |> 
  addTiles() |> 
  addRasterImage(strat_raster[[5]], opacity = 0.8, colors = pal) |> 
  addPolygons(data = shape_1, color = "black", weight = 1,
              opacity = 1, fillOpacity = 0)

