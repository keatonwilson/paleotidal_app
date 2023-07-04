
# Define server logic required to draw a histogram
function(input, output, session) {

  # this is reactive
  input_list = input_server("inputs")
  
  print(input_list)

  # hard code amplitude for now because it's easy
  map_server("map",
             inputs = input_list,
             rasters = list(amp_raster = amp_raster,
                            bss_raster = bss_raster,
                            mask_water_raster = mask_water_raster,
                            rsl_raster = rsl_raster,
                            water_depth_raster = water_depth_raster))
  

  
}
