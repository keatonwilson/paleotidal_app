
# Define server logic required to draw a histogram
function(input, output, session) {

  # Inputs Module
  input_list = input_server("inputs")
  
  # Data Summary Module
  data_summary_server("data_summary", 
                      inputs = input_list)

  # Map Module
  map_server("map",
             inputs = input_list,
             rasters = list(amp_raster = amp_raster,
                            bss_raster = bss_raster,
                            mask_water_raster = mask_water_raster,
                            rsl_raster = rsl_raster,
                            water_depth_raster = water_depth_raster))
  

  
}
