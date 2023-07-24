# Set local or deloyment mode --------------------------------------------
is_deployment = FALSE


# Data load ---------------------------------------------------------------
if (is_deployment == FALSE) {
  # rasters
  amp_raster = readr::read_rds("./data/processed_data/amp_raster.rds")
  bss_raster = readr::read_rds("./data/processed_data/bss_raster.rds")
  mask_water_raster = readr::read_rds("./data/processed_data/mask_water_raster.rds")
  rsl_raster = readr::read_rds("./data/processed_data/rsl_raster.rds")
  strat_raster = readr::read_rds("./data/processed_data/strat_raster.rds")
  vel_raster = readr::read_rds("./data/processed_data/vel_raster.rds")
  water_depth_raster = readr::read_rds("./data/processed_data/water_depth_raster.rds")
  ice_raster = readr::read_rds("./data/processed_data/ice_raster.rds")
  
  # tidy data
  amp_data = arrow::read_feather("./data/processed_data/amp_data.feather")
  bss = arrow::read_feather("./data/processed_data/bss.feather")
  mask_water = arrow::read_feather("./data/processed_data/mask_water.feather")
  rsl = arrow::read_feather("./data/processed_data/rsl.feather")
  strat = arrow::read_feather("./data/processed_data/strat.feather")
  vel = arrow::read_feather("./data/processed_data/vel.feather")
  water_depth = arrow::read_feather("./data/processed_data/water_depth.feather")
  
  # shapefiles
  shape_1 = sf::st_read("./data/raw_shape/coastline/GSHHS_l_L1.shp")
  
  strat_contours = list.files("./data/raw_shape/strat/", full.names = TRUE)[stringr::str_detect(list.files("./data/raw_shape/strat/"), ".shp")] |>
    purrr::map(function(shapefile) {
    sf::st_read(shapefile)
  })

} else {
  
  # load files from bucket into memory
  amp_raster = aws.s3::s3readRDS("processed_data/amp_raster.rds", 
                                 bucket = "paleotidal-data-storage")
  bss_raster = aws.s3::s3readRDS("processed_data/bss_raster.rds", 
                                 bucket = "paleotidal-data-storage")
  mask_water_raster = aws.s3::s3readRDS("processed_data/mask_water_raster.rds", 
                                        bucket = "paleotidal-data-storage")
  rsl_raster = aws.s3::s3readRDS("processed_data/rsl_raster.rds", 
                                 bucket = "paleotidal-data-storage")
  strat_raster = aws.s3::s3readRDS("processed_data/strat_raster.rds", 
                                   bucket = "paleotidal-data-storage")
  vel_raster = aws.s3::s3readRDS("processed_data/vel_raster.rds", 
                                 bucket = "paleotidal-data-storage")
  water_depth_raster = aws.s3::s3readRDS("processed_data/water_depth_raster.rds", 
                                         bucket = "paleotidal-data-storage")
  ice_raster = aws.s3::s3readRDS("processed_data/ice_raster.rds", 
                                 bucket = "paleotidal-data-storage")
  
  # raw data
  amp_data = aws.s3::get_object("processed_data/amp_data.feather", 
                                bucket = "paleotidal-data-storage") |> 
    arrow::read_feather()
  
  bss = aws.s3::get_object("processed_data/bss.feather", 
                           bucket = "paleotidal-data-storage") |> 
    arrow::read_feather()
  
  mask_water = aws.s3::get_object("processed_data/mask_water.feather", 
                                  bucket = "paleotidal-data-storage") |> 
    arrow::read_feather()
  
  rsl = aws.s3::get_object("processed_data/rsl.feather", 
                           bucket = "paleotidal-data-storage") |> 
    arrow::read_feather()
  
  strat = aws.s3::get_object("processed_data/strat.feather", 
                             bucket = "paleotidal-data-storage") |> 
    arrow::read_feather()
  
  vel = aws.s3::get_object("processed_data/vel.feather", 
                           bucket = "paleotidal-data-storage") |> 
    arrow::read_feather()
  
  water_depth = aws.s3::get_object("processed_data/water_depth.feather", 
                                   bucket = "paleotidal-data-storage") |> 
    arrow::read_feather()
  
  
  # shape files
  bucketfiles = aws.s3::get_bucket_df("paleotidal-data-storage")
  
  # coastline objects to save
  coastline_objs = bucketfiles |> 
    dplyr::filter(stringr::str_detect(Key, "coastline")) |> 
    dplyr::pull(Key)
  
  # saving
  coastline_objs |> 
    purrr::map(function(coastline_file) {
      name = glue::glue("./data/{stringr::str_remove(coastline_file, 'coastline/')}")
      aws.s3::save_object(coastline_file, 
                          bucket = "paleotidal-data-storage", 
                          file = name)
    })
  
  # loading from save
  shape_1 = sf::st_read("./data/GSHHS_l_L1.shp")
  
  strat_files = bucketfiles |> 
    dplyr::filter(stringr::str_detect(Key, "strat/")) |> 
    dplyr::pull(Key)
  
  # saving
  strat_files |> 
    purrr::map(function(strat_file) {
      name = glue::glue("./data/{stringr::str_remove(strat_file, 'strat/')}")
      aws.s3::save_object(strat_file, 
                          bucket = "paleotidal-data-storage", 
                          file = name)
    })
  
  # loading from file
  nums = seq(from = 0, to = 21) |> stringr::str_pad(width = 2, side = "left", pad = "0")
  strat_objects = glue::glue("./data/log10_strat_contour_{nums}.shp")
  
  strat_contours = strat_objects |> 
    purrr::map(function(shapefile) {
      sf::st_read(shapefile)
    })
}
