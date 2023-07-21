library(raster)
# library(terra)
library(tidyverse)
# library(sp)
library(leaflet)

# Sandbox to make leaflet plots locally before connecting to app

# Start with veolocity
strat_raster = readr::read_rds("./data/processed_data/strat_raster.rds")

vel_raster = readr::read_rds("./data/processed_data/vel_raster.rds")
leaflet() |> 
  addTiles() |> 
  addRasterImage(strat_raster[[22]], opacity = 0.8)

test = read_tsv("./data/raw_lat_lon/ampM2/amp_M2_00.ascii", 
                col_names = c("x", "y", "value"))
test = read_tsv("./data/raw_lat_lon/stratification/log10_strat_123_00.ascii", 
                col_names = c("x", "y", "value")) %>%
  mutate(value = if_else(is.nan(value), NA, value),
         value = if_else(is.infinite(value), NA, value))
test = read_tsv("./data/raw_lat_lon/stratification/strat_00.ascii", 
                col_names = c("x", "y", "value"))

test = read_tsv("./data/raw_lat_lon/vel/velM2_00.ascii", 
                col_names = c("x", "y", "value"))

# getting dims for raster transformation
ncol = length(unique(test$x))
nrow = length(unique(test$y))

extent = extent(test[,(1:2)])
r = raster(extent, ncol = ncol, nrow = nrow)

# rasterize
r_new = rasterize(test[,1:2], r, test[,3], fun=mean)
crs(r_new) = "+proj=longlat +datum=WGS84"

# testing on map
leaflet() |> 
  addTiles() |> 
  addRasterImage(r_new, opacity = 0.8, )
