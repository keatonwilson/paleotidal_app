
# Data load ---------------------------------------------------------------

# TODO: testing aggregate (downsample) for all rasters - leaving non mapping 
# rasters at full resolution

# rasters
amp_raster = readr::read_rds("./data/processed_data/amp_raster.rds")
bss_raster = readr::read_rds("./data/processed_data/bss_raster.rds")
# mask_water_raster = readr::read_rds("./data/processed_data/mask_water_raster.rds")
rsl_raster = readr::read_rds("./data/processed_data/rsl_raster.rds")
strat_raster = readr::read_rds("./data/processed_data/strat_raster.rds")
vel_raster = readr::read_rds("./data/processed_data/vel_raster.rds")
water_depth_raster = readr::read_rds("./data/processed_data/water_depth_raster.rds")
ice_raster = readr::read_rds("./data/processed_data/ice_raster.rds")

# tidy data
amp_data = arrow::read_feather("./data/processed_data/amp_data.feather")
bss_data = arrow::read_feather("./data/processed_data/bss.feather")
# mask_water_data = arrow::read_feather("./data/processed_data/mask_water.feather")
rsl_data = arrow::read_feather("./data/processed_data/rsl.feather")
strat_data = arrow::read_feather("./data/processed_data/strat.feather")
vel_data = arrow::read_feather("./data/processed_data/vel.feather")
water_depth_data = arrow::read_feather("./data/processed_data/water_depth.feather")

# shapefiles
shape_1 = sf::st_read("./data/raw_shape/coastline/GSHHS_l_L1.shp")

strat_contours = list.files("./data/raw_shape/strat/", full.names = TRUE)[stringr::str_detect(list.files("./data/raw_shape/strat/"), ".shp")] |>
  purrr::map(function(shapefile) {
  sf::st_read(shapefile)
})

