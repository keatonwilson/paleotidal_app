
# Define server logic required to draw a histogram
function(input, output, session) {

  # Inputs Module
  input_list = input_server("inputs")
  
  # Data Summary Module
  data_summary_server("data_summary", 
                      inputs = input_list)
  
  # base map and proxy
  output$map = leaflet::renderLeaflet({
    leaflet::leaflet() |> 
      leaflet::setView(lng = -4, lat = 56, zoom = 5.25) |> 
      leaflet::addRasterImage(amp_raster$X21_elevation_amplitude, 
                              colors = "viridis") |> 
      leaflet::addPolygons(data = shape_1, weight = 0.5)
  })
  
  map_proxy = reactive(leaflet::leafletProxy("map"))

  # Map Module
  map_server("map_raster",
             inputs = input_list,
             rasters = list(amp_raster = amp_raster,
                            bss_raster = bss_raster,
                            mask_water_raster = mask_water_raster,
                            rsl_raster = rsl_raster,
                            water_depth_raster = water_depth_raster), 
             map_proxy = map_proxy
             )
  
  
  # Click Events
  observe({
    click = input$map_click
    print(click)
    
    #TODO Need function that grabs nearest points and plots time series
    
  })

  
}
