library(raster)
library(terra)
library(tidyverse)
# library(sp)
library(leaflet)

# Sandbox to make leaflet plots locally before connecting to app
shape_1 = sf::st_read("./data/raw_shape/coastline/GSHHS_l_L1.shp")
ice_raster = readr::read_rds("./data/processed_data/ice_raster.rds")

# Start with amp
amp_raster = readr::read_rds("./data/processed_data/amp_raster.rds")

pal <- colorNumeric(palette = "viridis",
                    domain = c(0, 4),
                    na.color = "gray20")

leaflet() |> 
  leaflet::setView(lng = -4, lat = 56, zoom = 4.5) |> 
  addRasterImage(amp_raster[[21]], opacity = 0.8, colors = pal) |> 
  # addRasterImage(ice_raster[[21]], colors = "aliceblue") |>
  addPolygons(data = shape_1, color = "black", weight = 1,
              opacity = 1, fillOpacity = 0) 

# Try with veolocity
vel_raster = readr::read_rds("./data/processed_data/vel_raster.rds")
maxes <- c()
for(i in 1:22) {
  maxes[i] <- min(vel_raster[[i]]@data@values, na.rm = T)
}

pal <- colorNumeric(palette = "viridis",
                    domain = c(0, 1.6),
                   na.color = "gray20")

leaflet() |> 
  leaflet::setView(lng = -4, lat = 56, zoom = 4.5) |> 
  addRasterImage(vel_raster[[21]], opacity = 0.8, colors = pal) |> 
  # addRasterImage(ice_raster[[21]], colors = "aliceblue") |>
  addPolygons(data = shape_1, color = "black", weight = 1,
              opacity = 1, fillOpacity = 0) 

# Test strat
strat_raster = readr::read_rds("./data/processed_data/strat_raster.rds")

# color_vec <- rev(RColorBrewer::brewer.pal(3, "GnBu"))
# RColorBrewer::display.brewer.pal(3, "GnBu")

pal <- colorFactor(palette = "GnBu",
                   domain = 1:3,
                   na.color = "gray20", 
                   reverse = TRUE)

leaflet() |> 
  leaflet::setView(lng = -4, lat = 56, zoom = 4.5) |> 
  addRasterImage(strat_raster[[21]], opacity = 0.8, colors = pal) |> 
  addPolygons(data = shape_1, color = "black", weight = 1,
              opacity = 1, fillOpacity = 0) |>
  addRasterImage(ice_raster[[21]], colors = "aliceblue")

