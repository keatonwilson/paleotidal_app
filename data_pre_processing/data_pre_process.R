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

# test = read_tsv("./data/raw_lat_lon/ampM2/amp_M2_00.ascii", 
#                 col_names = c("x", "y", "value"))
# test = read_tsv("./data/raw_lat_lon/stratification/log10_strat_10.ascii", 
#                 col_names = c("x", "y", "value")) %>%
#   mutate(value = if_else(is.nan(value), NA, value),
#          value = if_else(is.infinite(value), NA, value))
# test = read_tsv("./data/raw_lat_lon/stratification/strat_00.ascii", 
#                 col_names = c("x", "y", "value"))
# test = read_tsv("./data/raw_lat_lon/vel/velM2_00.ascii", 
#                 col_names = c("x", "y", "value"))

# getting dims for raster transformation
# ncol = length(unique(test$x))
# nrow = length(unique(test$y))
# 
# extent = extent(test[,(1:2)])
# r = raster(extent, ncol = ncol, nrow = nrow)
# 
# # rasterize
# r_new = rasterize(test[,1:2], r, test[,3], fun=mean)
# crs(r_new) = "+proj=longlat +datum=WGS84"
# 
# # testing on map
# leaflet() |> 
#   addTiles() |> 
#   addRasterImage(r_new, opacity = 0.8)

# Read and re_calculate lat/lon to better match 
# 
# test = readr::read_tsv("./data/raw_lat_lon/stratification/log10_strat_123_00.ascii",
#                             col_names = c("x", "y", "value"),
#                             show_col_types = FALSE,
#                             progress = FALSE)
# 
# x <- unique(test$x)
# y <- unique(test$y)
# xdiff <- c()
# ydiff <- c()
# for(i in 1:length(x)){
#  xdiff[i] <- (x[i+1] - x[i])/2
# }
# xdiff[625] <- xdiff[624]
# 
# for(i in 1:length(y)){
#   ydiff[i] <- (y[i+1] - y[i])/2
# }
# ydiff[861] <- ydiff[860]
# 
# # create tables to match
# x_recal <- data.frame(x, xdiff) |>
#   dplyr::mutate(x_new = x + xdiff) |>
#   dplyr::select(-xdiff)
# y_recal <- data.frame(y, ydiff) |>
#   dplyr::mutate(y_new = y + ydiff) |>
#   dplyr::select(-ydiff)
# 
# # write out
# readr::write_rds(x_recal, "./data/x_lon_recal.RDS")
# readr::write_rds(y_recal, "./data/y_lat_recal.RDS")

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
    out = purrr::map(files_to_read, function(file) {
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
    
  } else if(is_bss) {
    
    # group split
    files_df = tibble::tibble(filename = files_to_read) |> 
      dplyr::mutate(type = dplyr::case_when(stringr::str_detect(filename, "_v_") ~ "v", 
                                            stringr::str_detect(filename, "_u_") ~ "u", 
                                            stringr::str_detect(filename, "_uv_") ~ "uv")) |> 
      dplyr::group_split(type)
    
      out = purrr::map(files_df, function(file_group) {
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
  
  # ice requires special processing
  is_ice = all(stringr::str_detect(files_to_read, "ice"))
  if(is_ice) {
    out = out |> 
      dplyr::mutate(value = dplyr::case_when(value == 0 ~ NA, 
                                             .default = 1))
  }
    
  # water mask special processing
  is_water = all(stringr::str_detect(files_to_read, "mask_water"))
  if(is_water) {
    out = out |> 
      dplyr::mutate(value = dplyr::case_when(value == 0 ~ NA, 
                                             .default = 2))
  }
  
  # amp and vel require special processing
  is_amp_vel = all(stringr::str_detect(files_to_read, "amp") |
                     stringr::str_detect(files_to_read, "vel"))
  if(is_amp_vel) {
    out = out |> 
      dplyr::mutate(value = dplyr::if_else(value == 0, NA, value))
  }
  
  
  # join with recalculate lat lon
  out2 <- out |> 
    dplyr::left_join(x_recal) |> 
    dplyr::left_join(y_recal) |> 
    dplyr::select(-x, -y) |> 
    dplyr::rename(x = x_new, y = y_new) |> 
    dplyr::relocate(x, y)
  
  # return 
  return(out2)
}



## Combining Data ----------------------------------------------------------

# load recalculated lat/lon
x_recal <- readr::read_rds("./data/x_lon_recal.RDS")
y_recal <- readr::read_rds("./data/y_lat_recal.RDS")

# creating objects
amp_data = combine_all_years("./data/raw_lat_lon/ampM2/", "elevation_amplitude")
rsl = combine_all_years("./data/raw_lat_lon/rsl/", "rsl")
mask_water = combine_all_years("./data/raw_lat_lon/mask_water/", "mask_water")
water_depth = combine_all_years("./data/raw_lat_lon/waterdepth/", "water_depth")
strat = combine_all_years("./data/raw_lat_lon/stratification/", "strat")

# additional strat processing
# adding land NAs to strat data from water
strat = strat |> 
  dplyr::left_join(mask_water |> 
                     dplyr::select(x, y, water_value = value, year)) |> 
  dplyr::mutate(value = dplyr::case_when(is.na(water_value) ~ NA, 
                                      .default = value)) |> 
  dplyr::select(-water_value)


# bss pre-processing is special
bss = combine_all_years("./data/raw_lat_lon/bss/", "bss") |> 
  tidyr::pivot_wider(names_from = type, values_from = value) |>
  dplyr::mutate(quadrant = dplyr::case_when(u > 0 & v > 0 ~ 1, 
                                     u > 0 & v < 0 ~ 2, 
                                     u < 0 & v > 0 ~ 3,
                                     u == 0 & v == 0 ~ NA,
                                     u == 0 & v != 0 ~ 0, 
                                     u != 0 & v == 0 ~ 0,
                                     .default = 4))

# adding land NAs to BSS data from water
bss = bss |> 
  dplyr::left_join(mask_water |> 
              dplyr::select(x, y, water_value = value, year)) |> 
  dplyr::mutate(uv = dplyr::case_when(is.na(water_value) ~ NA, 
                                               .default = uv)) |> 
  dplyr::select(-water_value)

# Make BSS polylines df
bss_arrows = bss |> 
  dplyr::group_by(year, y) |> 
  dplyr::slice(which(dplyr::row_number() %% 10 == 1)) |> 
  dplyr::ungroup() |> 
  dplyr::group_by(year, x) |> 
  dplyr::slice(which(dplyr::row_number() %% 10 == 1)) |> 
  ungroup() |> 
  dplyr::filter(!is.na(uv)) |> 
  dplyr::filter(uv > 0.5)

# mag multiplier
mag_mult = 0.09
polylines_df_base = bss_arrows |> 
  dplyr::mutate(id = dplyr::row_number())

polylines_end = bss_arrows |> 
  dplyr::mutate(x = x+(u*mag_mult*-1), 
                y = y+(v*mag_mult*-1)) |> 
  dplyr::mutate(id = dplyr::row_number())

all_bss_polylines = dplyr::bind_rows(polylines_df_base, polylines_end) |> 
  dplyr::mutate(id = factor(id))



ice = combine_all_years("./data/raw_lat_lon/ice/", "ice")
vel = combine_all_years("./data/raw_lat_lon/vel/", "vel")

# write feather files
arrow::write_feather(amp_data, "./data/processed_data/amp_data.feather")
arrow::write_feather(rsl, "./data/processed_data/rsl.feather")
# arrow::write_feather(mask_water, "./data/processed_data/mask_water.feather")
arrow::write_feather(water_depth, "./data/processed_data/water_depth.feather")
arrow::write_feather(bss, "./data/processed_data/bss.feather")
arrow::write_feather(all_bss_polylines, "./data/processed_data/bss_polylines.feather")
arrow::write_feather(ice, "./data/processed_data/ice.feather")
arrow::write_feather(strat, "./data/processed_data/strat.feather")
arrow::write_feather(vel, "./data/processed_data/vel.feather")


# Make a list of raster objects by year -----------------------------------

make_raster_list = function(data, 
                            ...) {
  
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
      
      if (all(list_item$datatype != "bss") &
          all(list_item$datatype != "strat")) { # use mean to rasterize
        # getting dims for raster transformation
        ncol = length(unique(list_item$x))
        nrow = length(unique(list_item$y))
  
        extent = extent(list_item[,(1:2)])
        r = raster(extent, ncol = ncol, nrow = nrow)
  
        # rasterize
        r_new = rasterize(list_item[,1:2], r, list_item[,3], fun=mean)
        crs(r_new) = "+proj=longlat +datum=WGS84"
      
      } else if (all(list_item$datatype == "strat")) { # use first to rasterize
        # getting dims for raster transformation
        ncol = length(unique(list_item$x))
        nrow = length(unique(list_item$y))
        
        extent = extent(list_item[,(1:2)])
        r = raster(extent, ncol = ncol, nrow = nrow)
        
        # rasterize
        r_new = rasterize(list_item[,1:2], r, list_item[,3], fun='first', na_rm = TRUE)
        crs(r_new) = "+proj=longlat +datum=WGS84"
        
      } else {
        # bss is special
        # getting dims for raster transformation
        ncol = length(unique(list_item$x))
        nrow = length(unique(list_item$y))
        
        extent = extent(list_item[,(1:2)])
        r = raster(extent, ncol = ncol, nrow = nrow)
        
        # rasterize - column 6 is the magnitude
        r_new = rasterize(list_item[,1:2], r, list_item[,6], fun='first')
        r_new[r_new == Inf] = NA
        crs(r_new) = "+proj=longlat +datum=WGS84"
        
      }

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
# mask_water_raster = make_raster_list(mask_water, year)
water_depth_raster = make_raster_list(water_depth, year)
bss_raster = make_raster_list(bss, year)
ice_raster = make_raster_list(ice, year)
strat_raster = make_raster_list(strat, year)
vel_raster = make_raster_list(vel, year)


# bss testing
pal = colorNumeric(palette = "viridis",
                  domain = values(bss_raster$X0_bss),
                  na.color = "gray30", 
                  reverse = FALSE)
## This could be an altnerative to a regular grid
## It's also faster

# Sampling - this seems to to work well - 
# this is all the raw data we need for all years - much smaller than the 
# full data set - though we'd need to full data set for the time-series/data 
# # data download
bss_filt = bss_data |> 
  dplyr::filter(year == 0) |> 
  dplyr::group_by(y) |> 
  dplyr::slice(which(dplyr::row_number() %% 12 == 1)) |> 
  dplyr::ungroup() |> 
  dplyr::group_by(x) |> 
  dplyr::slice(which(dplyr::row_number() %% 12 == 1)) |> 
  ungroup() |> 
  dplyr::filter(!is.na(uv)) |> 
  dplyr::filter(uv > 0)

# mag multiplier
mag_mult = 0.09
polylines_df_base = bss_filt |> 
  dplyr::mutate(id = dplyr::row_number())

polylines_end = bss_filt |> 
  dplyr::mutate(x = x+(u*mag_mult*-1), 
                y = y+(v*mag_mult*-1)) |> 
  dplyr::mutate(id = dplyr::row_number())

to_plot = dplyr::bind_rows(polylines_df_base, polylines_end) |> 
  dplyr::mutate(id = factor(id))

to_plot = bss_polylines |> 
  filter(year == 0)

mp = leaflet() |> 
  addRasterImage(bss_raster$X0_bss, 
                 colors = pal) 

for(group in unique(to_plot$id)){
  mp = leaflet.extras2::addArrowhead(mp,
                                     lng= ~x,
                                     lat= ~y,
                                     data = to_plot[to_plot$id==group,],
                                     weight = 2, 
                                     color = "white")
}
# strat testing
pal = colorFactor(palette = "GnBu",
                  domain = unique(values(strat_raster$X0_strat)),
                  na.color = "gray30", 
                  reverse = TRUE)
leaflet() |> 
  addRasterImage(strat_raster$X0_strat, 
                 colors = pal,
                 project = FALSE) 

# writing raster stacks to rds files
readr::write_rds(amp_raster, "./data/processed_data/amp_raster.rds")
readr::write_rds(rsl_raster, "./data/processed_data/rsl_raster.rds")
# readr::write_rds(mask_water_raster, "./data/processed_data/mask_water_raster.rds")
readr::write_rds(water_depth_raster, "./data/processed_data/water_depth_raster.rds")
readr::write_rds(bss_raster, "./data/processed_data/bss_raster.rds")
readr::write_rds(ice_raster, "./data/processed_data/ice_raster.rds")
readr::write_rds(strat_raster, "./data/processed_data/strat_raster.rds")
readr::write_rds(vel_raster, "./data/processed_data/vel_raster.rds")


## Make list of paleocoast shapefiles

fn <- as.character(sprintf("palcoast_%02d", 1:21))
shape_list <- list()
for(i in 1:length(fn)) {
  temp <- sf::st_read(glue::glue("./data/raw_shape/coastline/shpfile_palcoasts/{fn[i]}.shp"))
  shape_list[[i]] <- temp
}

saveRDS(shape_list, "data/processed_data/palcoast_list.RDS")
