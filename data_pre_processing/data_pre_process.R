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
  
  purrr::map(files_to_read, function(file) {
    # extracting year
    year = stringr::str_extract(file, "(\\d{2})(?=\\.[^.]+$)") |> 
      as.numeric()
    
    # reading file and appending 
    data = readr::read_tsv(file, 
                           col_names = c("x", "y", "value"), 
                           show_col_types = FALSE) |> 
      dplyr::mutate(year = year, 
                    datatype = datatype)
    
    # return
    return(data)
    
  }) |> 
    dplyr::bind_rows()

}



## Combining Data ----------------------------------------------------------

amp_data = combine_all_years("./data/raw_lat_lon/ampM2/", "elevation_amplitude")
rsl = combine_all_years("./data/raw_lat_lon/rsl/", "rsl")
mask_water = combine_all_years("./data/raw_lat_lon/mask_water/", "mask_water")
water_depth = combine_all_years("./data/raw_lat_lon/waterdepth/", "water_depth")
bss



