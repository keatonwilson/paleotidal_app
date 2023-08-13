
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
  
  # setup waiter for loading animations
  start_w = waiter::Waiter$new(
    id = "map",
    html = waiter::spin_3(),
    color = waiter::transparent(.5)
  )
  
  # base map and proxy
  
  # set color legend for proxy map
  pal <- leaflet::colorNumeric(palette = "viridis",
                               domain = c(0, 4),
                               na.color = "gray30") 
  
  output$map = leaflet::renderLeaflet({
    
    # show load screen on iniitial load
    start_w$show()
    
    leaflet::leaflet() |> 
      leaflet::setView(lng = -4, lat = 56, zoom = 5.25) |> 
      # Base amp raster
      leaflet::addRasterImage(amp_raster$X21_elevation_amplitude, 
                              colors = "viridis") |> 
      # # base water
      # leaflet::addRasterImage(mask_water_raster$X21_mask_water) |> 
      # base ice
      leaflet::addRasterImage(ice_raster$X21_ice, colors = "aliceblue") |> 
      # base current shoreline
      leaflet::addPolygons(data = shape_1, 
                           weight = 0.5, 
                           opacity = 1,
                           color = "black",
                           fillOpacity = 0) |> 
      # add basemap legend
      leaflet::addLegend("topright", colors = c("gray", "aliceblue"),
                labels = c("land", "ice"),
                opacity = 1) |> 
      leaflet::addLegend("bottomright", pal = pal, values = c(0, 4), bins = 5,
                title = "Tidal Amplitude",
                labFormat = leaflet::labelFormat(suffix = " m"), 
                opacity = 1)
  })
  
  map_proxy = reactive(leaflet::leafletProxy("map"))

  # Map Module
  map_server("map_raster",
             inputs = input_list,
             data = data_list,
             rasters = list(amp_raster = amp_raster,
                            bss_raster = bss_raster,
                            # mask_water_raster = mask_water_raster,
                            rsl_raster = rsl_raster,
                            strat_raster = strat_raster,
                            vel_raster = vel_raster,
                            water_depth_raster = water_depth_raster), 
             ice_raster = ice_raster,
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
                       rsl_data = rsl_data, 
                       amp_data = amp_data,
                       data = data_list,
                       remaining_data = list(
                                      strat_data = strat_data,
                                      bss_data = bss_data,
                                      vel_data = vel_data)
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
