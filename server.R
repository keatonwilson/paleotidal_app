
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

  # only the parts that never change; mod_map.R adds layers and legends
  output$map = leaflet::renderLeaflet({

    leaflet::leaflet() |>
      leaflet::setView(lng = static$view$lng, lat = static$view$lat,
                       zoom = static$view$zoom) |>
      # current shoreline
      leaflet::addPolygons(data = static$coast,
                           group = "coast",
                           weight = 0.5,
                           opacity = 1,
                           color = "black",
                           fillOpacity = 0,
                           options = leaflet::pathOptions(clickable = FALSE))
  })

  # The map sits on a tab that is hidden at startup, and proxy calls made
  # before it has rendered are dropped. Hold them until it reports a zoom.
  map_ready = reactiveVal(FALSE)
  observeEvent(input$map_zoom, map_ready(TRUE), once = TRUE)

  map_proxy = reactive({
    req(map_ready())
    leaflet::leafletProxy("map")
  })

  # Map Module
  map_server("map_raster",
             inputs = input_list,
             data = data_list,
             map_proxy = map_proxy
             )

  # Time-series Module - returns the grid point closest to the last map click
  closest_lat_lon = time_series_server("time_series",
                                       click = reactive(input$map_click),
                                       data = data_list)

  # Click marker
  observe({

    icons <- leaflet::awesomeIcons(
      icon = 'ios-close',
      iconColor = 'white',
      library = 'ion',
      markerColor = "green"
    )

    map_proxy() |>
      leaflet::removeMarker(layerId = "click_mark") |>
      leaflet::addAwesomeMarkers(lng = closest_lat_lon()$lon,
                                 lat = closest_lat_lon()$lat,
                                 layerId = "click_mark",
                                 icon = icons)
  })


}
