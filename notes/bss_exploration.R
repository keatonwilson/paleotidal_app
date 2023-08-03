# Packages ----------------------------------------------------------------

library(raster)
library(terra)
library(tidyverse)
library(sp)
library(leaflet)


# data
bss_raster = readr::read_rds("./data/processed_data/bss_raster.rds")
bss = arrow::read_feather("./data/processed_data/bss.feather")

bss_wide = bss |> 
  tidyr::pivot_wider(names_from = type, values_from = value) |>
  mutate(quadrant = dplyr::case_when(u > 1 & v > 1 ~ 1, 
                                     u > 1 & v < 1 ~ 2, 
                                     u < 1 & v > 1 ~ 3,
                                     u == 0 | v == 0 ~ NA,
                                     .default = 4)) |> 
  filter(year == 0)

# polyline calculations
mag_mult = 0.05
polylines_df_base = bss_wide |> 
  filter(!is.na(quadrant) & uv > 8 & uv < 11) |> 
  mutate(id = row_number())

polylines_end = bss_wide |> 
  filter(!is.na(quadrant) & uv > 8 & uv < 11) |>
  mutate(x = x+(u*mag_mult), 
         y = y+(v*mag_mult)) |> 
  mutate(id = row_number())

to_plot = bind_rows(polylines_df_base, polylines_end) |> 
  mutate(id = factor(id))

map = leaflet() |> 
  addTiles()

for(group in levels(to_plot$id)){
  map = leaflet.extras2::addArrowhead(map,
                       lng= ~x,
                       lat= ~y,
                       data = to_plot[to_plot$id==group,],
                       weight = 1)
}


# getting dims for raster transformation
ncol = length(unique(bss_wide$x))
nrow = length(unique(bss_wide$y))

extent = extent(bss_wide[,(1:2)])
r = raster(extent, ncol = ncol, nrow = nrow)

# rasterize
r_new = rasterize(bss_wide[,1:2], r, bss_wide[,8], fun=mean)
crs(r_new) = "+proj=longlat +datum=WGS84"


# testing on map
leaflet() |> 
  addRasterImage(r_new, opacity = 0.8)
