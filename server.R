
# Define server logic required to draw a histogram
function(input, output, session) {
  
  # Data Selection Module
  data_list = data_select_server("data_type")

  # Inputs Module
  input_list = input_server("inputs",
                            inputs = data_list)

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
             data = data_list,
             rasters = list(amp_raster = amp_raster,
                            bss_raster = bss_raster,
                            mask_water_raster = mask_water_raster,
                            rsl_raster = rsl_raster,
                            water_depth_raster = water_depth_raster), 
             map_proxy = map_proxy
             )
  
  
  # Click Events
  observe({
    
    # click input on map
    click = input$map_click
    
    # create time-series based on click and return the closest lat lon
    # in the dataset
    
    closest_lat_lon = time_series_server("time_series", 
                       map_click_obj = click, 
                       inputs = input_list, 
                       rsl_data = rsl, 
                       amp_data = amp_data
                       )
    
    # don't run proxy update without a click
    if (!is.null(closest_lat_lon)) {
      
      map_proxy() |> 
        leaflet::removeMarker(layerId = "click_mark") |>
        leaflet::addMarkers(lng = closest_lat_lon$lon, 
                            lat = closest_lat_lon$lat, 
                            layerId = "click_mark")
    }
  })

  
}
