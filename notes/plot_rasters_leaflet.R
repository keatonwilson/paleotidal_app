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
                    na.color = "gray30")

leaflet() |> 
  leaflet::setView(lng = -4, lat = 56, zoom = 4.5) |> 
  # leaflet::setMaxBounds(-15, 45, 11, 65.0125) |> 
  addRasterImage(amp_raster[[1]], opacity = 0.8, colors = pal) |> 
  # addRasterImage(ice_raster[[21]], colors = "aliceblue") |>
  addPolygons(data = shape_1, color = "black", weight = 1,
              opacity = 1, fillOpacity = 0) |> 
  addLegend("topright", colors = c("gray", "aliceblue"),
            labels = c("land", "ice"),
            opacity = 1) |> 
  addLegend("bottomright", pal = pal, values = c(0, 4), bins = 5,
            title = "Tidal Amplitude",
            labFormat = labelFormat(suffix = " m"), 
            opacity = 1)


# Try with veolocity
vel_raster = readr::read_rds("./data/processed_data/vel_raster.rds")

pal <- colorNumeric(palette = "viridis",
                    domain = c(0, 1.6),
                   na.color = "gray30")

leaflet() |> 
  leaflet::setView(lng = -4, lat = 56, zoom = 4.5) |> 
  addRasterImage(vel_raster[[15]], opacity = 0.8, colors = pal) |> 
  addRasterImage(ice_raster[[15]], colors = "aliceblue") |>
  addPolygons(data = shape_1, color = "black", weight = 1,
              opacity = 1, fillOpacity = 0) |> 
  addLegend("topright", colors = c("gray", "aliceblue"),
            labels = c("land", "ice"),
            opacity = 1) |> 
  addLegend("bottomright", pal = pal, values = c(0, 1.6), bins = 4,
            title = "Tidal Current",
            labFormat = labelFormat(suffix = " m/s"), 
            opacity = 1)

# Test strat
strat_raster = readr::read_rds("./data/processed_data/strat_raster.rds")

pal <- colorFactor(palette = "GnBu",
                   domain = values(strat_raster[[21]]),
                   na.color = "gray30", 
                   reverse = TRUE)

strat_vec <- c()

leaflet() |> 
  leaflet::setView(lng = -4, lat = 56, zoom = 4.5) |> 
  addRasterImage(strat_raster[[21]], opacity = 0.8, colors = pal) |> 
  addPolygons(data = shape_1, color = "black", weight = 1,
              opacity = 1, fillOpacity = 0) |>
  addRasterImage(ice_raster[[21]], colors = "aliceblue") |> 
  addLegend("topright", colors = c("gray", "aliceblue"),
            labels = c("land", "ice"),
            opacity = 1) |> 
  addLegend(colors = c("#43A2CA", 
                       "#A8DDB5", 
                       "#E0F3DB"),
            labels = c("mixed", "frontal", "stratified"),
            title = "Stratification",
            opacity = 1)


