# Data Pre-Processing
# Keaton Wilson
# keatonwilson@me.com 
# 2023-06-25


# Packages ----------------------------------------------------------------

library(raster)
library(terra)
library(tidyverse)
library(sp)
library(leaflet)

# Testing Sandbox ---------------------------------------------------------

test = read_tsv("./data/raw_lat_lon/ampM2/amp_M2_00.ascii", 
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
  addRasterImage(r_new, opacity = 0.8)
