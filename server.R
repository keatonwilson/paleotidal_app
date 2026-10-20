
# Define server logic required to draw a histogram
function(input, output, session) {

  # About modal: shown on every session start, and reopened from the navbar
  shiny::showModal(about_modal())
  shiny::observeEvent(input$show_about, {
    shiny::showModal(about_modal())
  })

  # Data Selection Module
  data_list = data_select_server("data_type")

  # Inputs Module
  input_list = input_server("inputs",
                            inputs = data_list)

  # Collapsible selection card (summary text shown when collapsed)
  selection_card_server("selection_card",
                        data = data_list,
                        inputs = input_list)

  # base map and proxy

  # only the parts that never change; the region observer below and mod_map.R
  # add everything else
  output$map = leaflet::renderLeaflet({
    view = statics[[1]]$view
    leaflet::leaflet() |>
      leaflet::setView(lng = view$lng, lat = view$lat, zoom = view$zoom) |>
      leaflet::addScaleBar("bottomleft",
                           options = leaflet::scaleBarOptions(imperial = FALSE)) |>
      # "Reset view" button; the click is handled by the observer below
      leaflet::addEasyButton(leaflet::easyButton(
        icon = "fa-crosshairs",
        title = "Reset view",
        onClick = htmlwidgets::JS(
          "function(btn, map) { Shiny.setInputValue('map_reset', Date.now()); }"
        )
      ))
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
    proxy = map_proxy()

    # extent of every layer, padded; bounds are list(list(lat, lng), list(lat, lng))
    pts = unlist(static$bounds)
    lats = range(pts[c(TRUE, FALSE)]) + c(-2, 2)
    lngs = range(pts[c(FALSE, TRUE)]) + c(-2, 2)
    # moves the map too (www/map_layers.js), so the limits never apply to the
    # old region's view
    session$sendCustomMessage("region-view", list(
      view = static$view,
      bounds = list(list(lats[1], lngs[1]), list(lats[2], lngs[2]))
    ))

    proxy |>
      leaflet::clearGroup("coast") |>
      leaflet::addPolygons(data = static$coast,
                           group = "coast",
                           weight = 0.5,
                           opacity = 1,
                           color = "black",
                           fillOpacity = 0,
                           options = leaflet::pathOptions(clickable = FALSE)) |>
      leaflet::removeMarker(layerId = "click_mark") |>
      leaflet::removeShape(layerId = "click_cell")
  })

  # Reset view button: back to the selected region's start view
  observeEvent(input$map_reset, {
    view = statics[[data_list$region]]$view
    map_proxy() |>
      leaflet::setView(lng = view$lng, lat = view$lat, zoom = view$zoom)
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

  # clicking the pin (the "x") clears the selection
  observeEvent(input$map_marker_click, {
    req(identical(input$map_marker_click$id, "click_mark"))
    click(NULL)
  })

  # Time-series Module - returns the grid point closest to the last map click
  closest_lat_lon = time_series_server("time_series",
                                       click = click,
                                       data = data_list)

  # Click marker
  observe({

    # no selection: remove the pin
    if (is.null(click())) {
      map_proxy() |>
        leaflet::removeMarker(layerId = "click_mark") |>
        leaflet::removeShape(layerId = "click_cell")
      return()
    }

    # grid spacing of the region's cube
    static = statics[[data_list$region]]
    dx = diff(static$xs[1:2])
    dy = diff(static$ys[1:2])

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
                                 icon = icons) |>
      # outline the grid cell the time series comes from; clicks pass through
      leaflet::addRectangles(lng1 = closest_lat_lon()$lon - dx / 2,
                             lng2 = closest_lat_lon()$lon + dx / 2,
                             lat1 = closest_lat_lon()$lat - dy / 2,
                             lat2 = closest_lat_lon()$lat + dy / 2,
                             layerId = "click_cell",
                             weight = 2,
                             color = "#f59e0b",
                             fillOpacity = 0.15,
                             options = leaflet::pathOptions(interactive = FALSE))
  })


}
