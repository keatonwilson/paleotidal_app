
# Data load ---------------------------------------------------------------

# rasters
amp_raster = readr::read_rds("./data/processed_data/amp_raster.rds")
bss_raster = readr::read_rds("./data/processed_data/bss_raster.rds")
mask_water_raster = readr::read_rds("./data/processed_data/mask_water_raster.rds")
rsl_raster = readr::read_rds("./data/processed_data/rsl_raster.rds")
water_depth_raster = readr::read_rds("./data/processed_data/water_depth_raster.rds")

# tidy data
amp_data = arrow::read_feather("./data/processed_data/amp_data.feather")
bss = arrow::read_feather("./data/processed_data/bss.feather")
rsl = arrow::read_feather("./data/processed_data/rsl.feather")
mask_water = arrow::read_feather("./data/processed_data/mask_water.feather")
water_depth = arrow::read_feather("./data/processed_data/water_depth.feather")

# coastline shape files
shape_1 = sf::st_read("./data/raw_shape/coastline/GSHHS_i_L1.shp")

