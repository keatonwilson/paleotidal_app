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
  `Peak Bed Stress (90th pct)` = list(prefix = "bss90",
                                      title = "Peak Bed Stress, 90th pct (N/m<sup>2</sup>)",
                                      domain = c(0, 5), values = c(0, 5), bins = 5),
  `Spring Tidal Range` = list(prefix = "range",
                              title = "Spring Tidal Range (m)",
                              domain = c(0, 11), values = c(0, 11), bins = 5),
  `Stratification` = list(prefix = "strat"),
  `Water Depth` = list(prefix = "depth",
                       title = "Water Depth (m, capped at 500)",
                       domain = c(0, 500), values = c(0, 500), bins = 5),
  `Relative Sea Level` = list(prefix = "rsl",
                              title = "Relative Sea Level (m)",
                              palette = "RdBu",
                              domain = c(-150, 150), values = c(-150, 150), bins = 6),
  `Ice Thickness` = list(prefix = "icethk",
                         title = "Ice Thickness (m)",
                         palette = "Blues",
                         domain = c(0, 2500), values = c(0, 2500), bins = 5)
)

# Stratification classes 1-3 (mixed, frontal/transitional, stratified), by
# model run. PALTIDE2 follows the colours its modellers use (parula ends and
# middle); PALTIDE1 keeps the colours baked into its layers.
strat_cols = list(PALTIDE1 = c("#43A2CA", "#A8DDB5", "#f1ffed"),
                  PALTIDE2 = c("#3E26A8", "#13BEB9", "#F9FB15"))
strat_labels = list(PALTIDE1 = c("Mixed", "Frontal", "Stratified"),
                    PALTIDE2 = c("Mixed", "Transitional", "Stratified"))

map_server <- function(id,
                       inputs,
                       data,
                       map_proxy) {
  moduleServer(id, function(input, output, session) {

    layer_url = function(prefix, year) {
      sprintf("layers/%s/%s_%02d.png", data$region, prefix, as.integer(year))
    }

    # show a pre-rendered file in a raster slot; www/map_layers.js swaps it in
    # over the previous image so there is no blank frame in between
    add_layer = function(prefix, year, slot, z_index) {
      static = statics[[data$region]]
      session$sendCustomMessage("swap-layer", list(
        slot = slot,
        url = layer_url(prefix, year),
        bounds = static$bounds[[prefix]],
        options = utils::modifyList(static$raster_opts, list(zIndex = z_index))
      ))
    }

    # Layers: region, data type or year changed
    observe({
      req(data$datatype)

      # holds everything below until the map exists
      map_proxy()
      region = data$region
      years = statics[[region]]$years
      prefix = map_layers[[data$datatype]]$prefix

      # after a region or data type change the other inputs take a moment to
      # catch up; wait for a combination that has a layer
      req(inputs$yearBP %in% years[[prefix]])

      add_layer(prefix, inputs$yearBP, "data", 1)
      # the ice thickness layer is its own ice cover
      if (inputs$yearBP %in% years$ice && prefix != "icethk") {
        add_layer("ice", inputs$yearBP, "ice", 2)
      } else {
        # no url empties the slot
        session$sendCustomMessage("swap-layer", list(slot = "ice"))
      }

      # bed stress arrows are drawn by www/map_layers.js from a file per year
      arrow_url = function(year) {
        sprintf("layers/%s/arrows_%02d.bin", region, as.integer(year))
      }
      session$sendCustomMessage("arrows", if (prefix == "bss") {
        list(url = arrow_url(inputs$yearBP),
             axes = sprintf("layers/%s/arrow_axes.json", region),
             # a list, so that one year is still sent as an array
             preload = as.list(arrow_url(years$bss)))
      } else {
        list()
      })
    })

    # Legends: region or data type changed
    observe({
      req(data$datatype)

      layer = map_layers[[data$datatype]]
      years = statics[[data$region]]$years
      req(years[[layer$prefix]])

      mp = map_proxy() |>
        leaflet::clearControls() |>
        leaflet::addLegend("topright", colors = c("#bebebe", "aliceblue"),
                           labels = c("Land", "Ice"),
                           opacity = 1)

      if (layer$prefix == "strat") {
        model = statics[[data$region]]$model
        leaflet::addLegend(mp, "bottomright",
                           colors = strat_cols[[model]],
                           labels = strat_labels[[model]],
                           title = "Stratification",
                           opacity = 1)
      } else {
        addLegend_decreasing(mp, "bottomright",
                             pal = leaflet::colorNumeric(palette = layer$palette %||% "viridis",
                                                         domain = layer$domain,
                                                         na.color = "#bebebe"),
                             values = layer$values, bins = layer$bins,
                             title = layer$title,
                             opacity = 1,
                             decreasing = TRUE)
      }

      # have the browser fetch every year for this data type now, so the
      # slider and play button never wait on the network
      session$sendCustomMessage("preload", as.list(c(layer_url(layer$prefix, years[[layer$prefix]]),
                                                     layer_url("ice", years$ice))))
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
