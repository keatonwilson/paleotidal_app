# Data Pre-Processing
# Keaton Wilson
# keatonwilson@me.com 
# 2023-06-27


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



# Combining All Years -----------------------------------------------------


#' Combine multiple data files for separate years
#'
#' This function takes a directory path and a datatype label and combines all of
#' the files within the directory into a single dataframe that is tidy, and 
#' includes columns designating the year (0-21) and datatype. These dataframes 
#' are typically large (~11.8 million rows) and may need to be modified/saved 
#' in a different file format for quick access in the app. 
#' 
#' @param data_dir character string denoting the directory containing the files
#' to be combined
#' @param datatype character string denoting the data type being combined 
#'
#' @return
#' @export
#'
#' @examples
combine_all_years = function(data_dir, 
                             datatype
                             ) {
  # files to read in
  files_to_read = list.files(data_dir, full.names = TRUE)
  
  # bss requires special processing
  is_bss = all(stringr::str_detect(files_to_read, "bss"))
  
  if (!is_bss) {
    purrr::map(files_to_read, function(file) {
      # extracting year
      year = stringr::str_extract(file, "(\\d{2})(?=\\.[^.]+$)") |> 
        as.numeric()
      
      # reading file and appending 
      data = readr::read_tsv(file, 
                             col_names = c("x", "y", "value"), 
                             show_col_types = FALSE, 
                             progress = FALSE) |> 
        dplyr::mutate(year = year, 
                      datatype = datatype)
      
      # return
      return(data)
      
    }, .progress = list(name = "Spatial Data Pre-Processing")) |> 
      dplyr::bind_rows()
    
  } else {
    
    # group split
    files_df = tibble::tibble(filename = files_to_read) |> 
      dplyr::mutate(type = dplyr::case_when(stringr::str_detect(filename, "_v_") ~ "v", 
                                            stringr::str_detect(filename, "_u_") ~ "u", 
                                            stringr::str_detect(filename, "_uv_") ~ "uv")) |> 
      group_split(type)
    
      purrr::map(files_df, function(file_group) {
        purrr::map2(file_group$filename, 
                    file_group$type, function(file, type) {
          # extracting year
          year = stringr::str_extract(file, "(\\d{2})(?=\\.[^.]+$)") |> 
            as.numeric()
          
          # reading file and appending 
          data = readr::read_tsv(file, 
                                 col_names = c("x", "y", "value"), 
                                 show_col_types = FALSE, 
                                 progress = FALSE) |> 
            dplyr::mutate(year = year, 
                          datatype = datatype, 
                          type = type)
          
          # return
          return(data)
          
        }) |> 
          dplyr::bind_rows()
      }, .progress = list(name = "Spatial Data Pre-Processing")) |>
        dplyr::bind_rows()
    
  }
  


}



## Combining Data ----------------------------------------------------------

# creating objects
amp_data = combine_all_years("./data/raw_lat_lon/ampM2/", "elevation_amplitude")
rsl = combine_all_years("./data/raw_lat_lon/rsl/", "rsl")
mask_water = combine_all_years("./data/raw_lat_lon/mask_water/", "mask_water")
water_depth = combine_all_years("./data/raw_lat_lon/waterdepth/", "water_depth")
bss = combine_all_years("./data/raw_lat_lon/bss/", "bss")


# Make a list of raster objects by year -----------------------------------

make_raster_list = function(data, ...) {
  
  # split data by year (or more) vars
  data_split = data |> 
    dplyr::group_by(...) |> 
    dplyr::group_split()
  
  # setting names
  names = data_split |> 
    purrr::map(function(list_item) {

      one_row = list_item |> 
        dplyr::select(..., datatype) |> 
        dplyr::distinct() |> 
        dplyr::slice(1) |> 
        as.character()
      
      out = paste(one_row, collapse = "_")
      return(out)
      
    })
  
  setNames(data_split, names)
  
  # make raster out of each list-component
  raster_list = data_split |>
    purrr::map(function(list_item) {

      # getting dims for raster transformation
      ncol = length(unique(list_item$x))
      nrow = length(unique(list_item$y))

      extent = extent(list_item[,(1:2)])
      r = raster(extent, ncol = ncol, nrow = nrow)

      # rasterize
      r_new = rasterize(list_item[,1:2], r, list_item[,3], fun=mean)
      crs(r_new) = "+proj=longlat +datum=WGS84"

      return(r_new)
    }, .progress = list(name = "Building Rasters"))
  
  # turn into a stack
  stack_out = raster::stack(raster_list)
  
  names(stack_out) = names
  
  return(stack_out)
  
}


# generating raster stacks for each data type
amp_raster = make_raster_list(amp_data, year)
rsl_raster = make_raster_list(rsl, year)
mask_water_raster = make_raster_list(mask_water, year)
water_depth_raster = make_raster_list(water_depth, year)
bss_raster = make_raster_list(bss, year, type)



# writing to rds files
arrow::write_feather(amp_data, "./data/processed_data/amp_data.feather")
arrow::write_feather(rsl, "./data/processed_data/rsl.feather")
arrow::write_feather(mask_water, "./data/processed_data/mask_water.feather")
arrow::write_feather(water_depth, "./data/processed_data/water_depth.feather")
arrow::write_feather(bss, "./data/processed_data/bss.feather")
