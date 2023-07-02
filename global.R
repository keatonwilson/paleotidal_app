
# Data load ---------------------------------------------------------------


amp_raster = readr::read_rds("./data/processed_data/amp_raster.rds")
bss_raster = readr::read_rds("./data/processed_data/bss_raster.rds")
mask_water_raster = readr::read_rds("./data/processed_data/mask_water_raster.rds")
rsl_raster = readr::read_rds("./data/processed_data/rsl_raster.rds")
water_depth_raster = readr::read_rds("./data/processed_data/water_depth_raster.rds")