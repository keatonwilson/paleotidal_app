library(raster)
library(terra)
library(tidyverse)
# library(sp)
library(leaflet)

# Sandbox to make leaflet plots locally before connecting to app
shape_1 = sf::st_read("./data/raw_shape/coastline/GSHHS_l_L1.shp")
ice_raster = readr::read_rds("./data/processed_data/ice_raster.rds")

# Start with veolocity
vel_raster = readr::read_rds("./data/processed_data/vel_raster.rds")


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

# color_vec <- rev(RColorBrewer::brewer.pal(3, "GnBu"))
# RColorBrewer::display.brewer.pal(3, "GnBu")

pal <- colorFactor(palette = "GnBu",
                   domain = 1:3,
                   na.color = "gray20", 
                   reverse = TRUE)

leaflet() |> 
  addRasterImage(strat_raster[[21]], opacity = 0.8, colors = pal) |> 
  addPolygons(data = shape_1, color = "black", weight = 1,
              opacity = 1, fillOpacity = 0) |>
  addRasterImage(ice_raster[[21]], colors = "aliceblue")

