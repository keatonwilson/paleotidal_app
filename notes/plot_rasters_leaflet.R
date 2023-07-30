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
  addRasterImage(amp_raster[[21]], opacity = 0.8, colors = pal) |> 
  addRasterImage(ice_raster[[21]], colors = "aliceblue") |>
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
# strat_raster = readr::read_rds("./data/processed_data/stratlog10_raster.rds")

strat = arrow::read_feather("./data/processed_data/stratlog10.feather")

#  min 1.9, max 2.9, front 2.1, radius 0.08

# Function to return statistical mode
Mode <- function(x, ...) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

raster_list <- strat |> 
  mutate(cat = case_when(value < 1.9 ~ "mixed",
                         value >= 1.9 & value <= 2.9 ~ "frontal",
                         value > 2.9 ~ "stratified"),
         cat = factor(cat, levels = c("mixed", "frontal", "stratified"))) |> 
  dplyr::group_by(year) |> 
  dplyr::group_split() |> 
  purrr::map(function(list_item) {
    
    # getting dims for raster transformation
    ncol = length(unique(list_item$x))
    nrow = length(unique(list_item$y))
    
    extent = extent(list_item[,(1:2)])
    r = raster(extent, ncol = ncol, nrow = nrow)
    
    # rasterize
    r_new = terra::rasterize(list_item[,1:2], r, list_item[,6], fun = Mode)
    crs(r_new) = "+proj=longlat +datum=WGS84"
    
    return(r_new)
  }, .progress = list(name = "Building Rasters"))

# turn into a stack
stack_out = raster::stack(raster_list)
  

pal <- colorFactor(palette = "GnBu",
                   domain = values(strat_raster[[21]]),
                   na.color = "gray30", 
                   reverse = TRUE)

strat_vec <- c("mixed", "frontal", "stratified")

leaflet() |> 
  leaflet::setView(lng = -4, lat = 56, zoom = 4.5) |> 
  addRasterImage(strat_raster[[21]], opacity = 0.8, colors = pal) |> 
  addPolygons(data = shape_1, color = "black", weight = 1,
              opacity = 1, fillOpacity = 0) |>
  addRasterImage(ice_raster[[21]], colors = "aliceblue") |> 
  addLegend("topright", colors = c("gray", "aliceblue"),
            labels = c("land", "ice"),
            opacity = 1)
  addLegend("bottomright", pal = pal, values = 1:3, 
            labFormat = labelFormat(transform = function(x) {
              # see https://stackoverflow.com/questions/59110756/failed-to-add-a-categorical-legend-in-leaflet-in-r-using-addlegendlabels
            }),
            title = "Stratification", 
            opacity = 1)


