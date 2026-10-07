map_ui <- function(id) {

  # ns <- NS(id)
  # leaflet::leafletOutput(ns("map"))

}

# What differs between data types: the layer file prefix and the legend.
# The colours themselves are baked into the pre-rendered layers by
# data_pre_processing/build_backend.R, so the domains here must match it.
map_layers = list(
  `Tidal Amplitude` = list(prefix = "amp",
                           title = "Tidal Amplitude (m)",
                           domain = c(0, 5), values = c(0, 4), bins = 5),
  `Tidal Current` = list(prefix = "vel",
                         title = "Tidal Current (m/s)",
                         domain = c(0, 2.5), values = c(0, 1.6), bins = 4),
  `Peak Bed Stress` = list(prefix = "bss",
                           title = "Peak Bed Stress (N/m<sup>2</sup>)",
                           domain = c(0, 15), values = c(0, 15), bins = 4),
  `Stratification` = list(prefix = "strat")
)

map_server <- function(id,
                       inputs,
                       data,
                       map_proxy) {
  moduleServer(id, function(input, output, session) {

    layer_url = function(prefix, year) {
      sprintf("layers/%s/%s_%02d.png", region, prefix, as.integer(year))
    }

    # show a pre-rendered file in a raster slot; www/map_layers.js swaps it in
    # over the previous image so there is no blank frame in between
    add_layer = function(prefix, year, slot, z_index) {
      session$sendCustomMessage("swap-layer", list(
        slot = slot,
        url = layer_url(prefix, year),
        bounds = static$bounds[[prefix]],
        options = utils::modifyList(static$raster_opts, list(zIndex = z_index))
      ))
    }

    # Layers: data type or year changed
    observe({
      req(data$datatype)

      # holds everything below until the map exists
      map_proxy()
      prefix = map_layers[[data$datatype]]$prefix

      add_layer(prefix, inputs$yearBP, "data", 1)
      add_layer("ice", inputs$yearBP, "ice", 2)

      # bed stress arrows are drawn by www/map_layers.js from a file per year
      arrow_url = function(year) {
        sprintf("layers/%s/arrows_%02d.bin", region, as.integer(year))
      }
      session$sendCustomMessage("arrows", if (prefix == "bss") {
        list(url = arrow_url(inputs$yearBP),
             axes = sprintf("layers/%s/arrow_axes.json", region),
             preload = arrow_url(0:21))
      } else {
        list()
      })
    })

    # Legends: data type changed
    observe({
      req(data$datatype)

      layer = map_layers[[data$datatype]]

      mp = map_proxy() |>
        leaflet::clearControls() |>
        leaflet::addLegend("topright", colors = c("#bebebe", "aliceblue"),
                           labels = c("Land", "Ice"),
                           opacity = 1)

      if (layer$prefix == "strat") {
        leaflet::addLegend(mp, "bottomright",
                           colors = c("#43A2CA",
                                      "#A8DDB5",
                                      "#f1ffed"),
                           labels = c("Mixed", "Frontal", "Stratified"),
                           title = "Stratification",
                           opacity = 1)
      } else {
        addLegend_decreasing(mp, "bottomright",
                             pal = leaflet::colorNumeric(palette = "viridis",
                                                         domain = layer$domain,
                                                         na.color = "#bebebe"),
                             values = layer$values, bins = layer$bins,
                             title = layer$title,
                             opacity = 1,
                             decreasing = TRUE)
      }

      # have the browser fetch every year for this data type now, so the
      # slider and play button never wait on the network
      session$sendCustomMessage("preload", c(layer_url(layer$prefix, 0:21),
                                             layer_url("ice", 0:21)))
    })

    # Modern coastline toggle
    observe({
      if (isTRUE(inputs$coast_current)) {
        leaflet::showGroup(map_proxy(), "coast")
      } else {
        leaflet::hideGroup(map_proxy(), "coast")
      }
    })

  })
}
