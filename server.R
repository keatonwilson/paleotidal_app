
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

  # only the parts that never change; the region observer below and mod_map.R
  # add everything else
  output$map = leaflet::renderLeaflet({
    view = statics[[1]]$view
    leaflet::leaflet() |>
      leaflet::setView(lng = view$lng, lat = view$lat, zoom = view$zoom)
  })

  # The map sits on a tab that is hidden at startup, and proxy calls made
  # before it has rendered are dropped. Hold them until it reports a zoom.
  map_ready = reactiveVal(FALSE)
  observeEvent(input$map_zoom, map_ready(TRUE), once = TRUE)

  map_proxy = reactive({
    req(map_ready())
    leaflet::leafletProxy("map")
  })

  # Region: move the map there and swap the current shoreline
  observe({
    static = statics[[data_list$region]]

    map_proxy() |>
      leaflet::setView(lng = static$view$lng, lat = static$view$lat,
                       zoom = static$view$zoom) |>
      leaflet::clearGroup("coast") |>
      leaflet::addPolygons(data = static$coast,
                           group = "coast",
                           weight = 0.5,
                           opacity = 1,
                           color = "black",
                           fillOpacity = 0,
                           options = leaflet::pathOptions(clickable = FALSE)) |>
      leaflet::removeMarker(layerId = "click_mark")
  })

  # Last map click. Only regions with a cube have anything to look up, and a
  # click does not carry over to another region. The reset runs ahead of the
  # outputs so none of them looks the old click up in the new region.
  click = reactiveVal()
  observeEvent(input$map_click, {
    if (!is.null(statics[[data_list$region]]$xs)) click(input$map_click)
  })
  observeEvent(data_list$region, click(NULL), priority = 10)

  # Map Module
  map_server("map_raster",
             inputs = input_list,
             data = data_list,
             map_proxy = map_proxy
             )

  # Time-series Module - returns the grid point closest to the last map click
  closest_lat_lon = time_series_server("time_series",
                                       click = click,
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
