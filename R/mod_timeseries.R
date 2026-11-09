time_series_ui <- function(id) {

  ns <- NS(id)
  bslib::card(
    bslib::card_header(
      class = "d-flex align-items-center gap-2",
      "Time series",
      shiny::uiOutput(ns("location"), inline = TRUE),
      # hidden until there is a selection
      shinyjs::hidden(shiny::downloadButton(
        ns("download_data"),
        label = NULL,
        icon = bsicons::bs_icon("download"),
        class = "btn-sm btn-outline-primary ms-auto",
        title = "Download CSV",
        `aria-label` = "Download CSV"
      ))
    ),
    bslib::card_body(
      # tighter than bslib's default gap between legend and graph
      style = "gap: 0.25rem;",
      # only rendered while a graph is showing
      shiny::uiOutput(ns("marker_legend")),
      bslib::as_fill_carrier(
        class = "justify-content-center align-items-center",
        shiny::uiOutput(ns("timeseries_plot"))
      )
    ),
    full_screen = TRUE
  )

}

# centred icon and muted text for when there is no graph to show
empty_state = function(icon, text) {
  shiny::div(class = "empty-state text-center text-body-secondary",
             bsicons::bs_icon(icon, size = "2rem"),
             shiny::p(class = "mt-2 mb-0", text))
}

# key to the marker shapes on the graphs (matches the symbols in ts_plot);
# drawn in the current text colour so it follows light/dark mode
marker_legend = function() {
  svg = function(shape) {
    shiny::HTML(paste0(
      "<svg width='14' height='14' viewBox='0 0 14 14' aria-hidden='true' ",
      "style='vertical-align:-2px' fill='currentColor' stroke='currentColor'>",
      shape, "</svg>"))
  }
  item = function(shape, label) {
    shiny::span(class = "d-inline-flex align-items-center gap-1", svg(shape), label)
  }
  shiny::div(
    class = "d-flex justify-content-center flex-wrap gap-3 small text-body-secondary",
    item("<circle cx='7' cy='7' r='4' stroke-width='0'/>", "Water"),
    item("<polygon points='7,1.5 12.5,7 7,12.5 1.5,7' stroke-width='0'/>", "Land"),
    item("<rect x='3' y='3' width='8' height='8' fill='none' stroke-width='2'/>", "Ice")
  )
}

# columns in the downloaded csv, by data type
download_cols = list(
  `M₂ Elevation Amplitude` = c("longitude", "latitude", "year", "land_type",
                        "rsl", "elevation_amplitude"),
  `Tidal Current` = c("longitude", "latitude", "year", "land_type",
                      "vel", "rsl", "elevation_amplitude"),
  `Seasonal Stratification` = c("longitude", "latitude", "year", "land_type",
                       "strat", "rsl", "elevation_amplitude"),
  `Peak Bed Stress` = c("longitude", "latitude", "year", "rsl",
                        "elevation_amplitude", "BSS_u", "BSS_v",
                        "BSS_magnitude", "land_type"),
  `Water Depth` = c("longitude", "latitude", "year", "land_type",
                    "depth", "rsl", "elevation_amplitude"),
  # PALTIDE2 only
  `Peak Bed Stress (90th pct)` = c("longitude", "latitude", "year", "land_type",
                              "BSS_magnitude", "rsl", "elevation_amplitude"),
  `Spring Tidal Range` = c("longitude", "latitude", "year", "land_type",
                           "spring_range", "rsl", "elevation_amplitude"),
  `Relative Sea Level` = c("longitude", "latitude", "year", "land_type",
                           "rsl", "elevation_amplitude"),
  `Ice Thickness` = c("longitude", "latitude", "year", "land_type",
                      "ice_thickness", "rsl", "elevation_amplitude")
)

# metres of padding above and below the plotted RSL range
RSL_PAD = 10

# y-axis limits for the data range: padded by RSL_PAD, then rounded outward to
# a multiple of the tick step so both ends of the axis carry a label
rsl_axis_limits = function(data_range) {
  padded = data_range + c(-RSL_PAD, RSL_PAD)
  steps = c(5, 10, 20, 25, 50, 100, 200)
  step = steps[which(diff(padded) / steps <= 6)[1]]
  if (is.na(step)) step = max(steps)
  list(range = c(floor(padded[1] / step), ceiling(padded[2] / step)) * step,
       dtick = step)
}

# one variable through time at the clicked cell: markers by land type on a line
ts_plot = function(df, colour, label, yaxis) {
  plotly::plot_ly(df, x = ~year, y = ~value) |>
    plotly::add_lines(line = list(color = colour, width = 2),
                      hoverinfo = "skip") |>
    plotly::add_markers(# symbols are set per point: plotly ignores the
                        # `symbols` argument when a lines trace comes first
                        # land slightly larger; ice drawn with a heavier
                        # outline so the hollow marker reads clearly
                        marker = list(color = colour,
                                      symbol = unname(c(water = "circle",
                                                        land = "diamond",
                                                        ice = "square-open")[as.character(df$land_type)]),
                                      size = ifelse(df$land_type == "land", 8.5, 8),
                                      line = list(color = colour,
                                                  width = ifelse(df$land_type == "ice", 2, 0))),
                        text = ~stringr::str_to_title(land_type),
                        hovertemplate = paste0(label, ": %{y} m<br>",
                                               "%{x}K BP · %{text}<extra></extra>")) |>
    plotly::layout(yaxis = yaxis)
}

# graph colours for the app's light/dark mode
ts_colours = function(dark) {
  if (dark) list(ink = "#cbd5e1", grid = "rgba(255,255,255,0.08)", accent = "#5eead4")
  else list(ink = "#334155", grid = "rgba(15,23,42,0.08)", accent = "#0b6e7f")
}

# dashed line through both graphs at the year on the map, labelled above
year_marker = function(year, dark) {
  colour = ts_colours(dark)$accent
  list(
    shapes = list(list(type = "line", xref = "x", yref = "paper",
                       x0 = year, x1 = year, y0 = 0, y1 = 1,
                       line = list(color = colour, width = 1.5, dash = "dash"))),
    annotations = list(list(text = paste0(year, "K BP"), showarrow = FALSE,
                            xref = "x", yref = "paper", x = year, y = 1,
                            yanchor = "bottom",
                            font = list(color = colour, size = 11)))
  )
}

# shared look for the stacked graphs, following the app's light/dark mode
ts_layout = function(p, dark) {
  ink = ts_colours(dark)$ink
  grid = ts_colours(dark)$grid
  p |>
    plotly::layout(
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor = "rgba(0,0,0,0)",
      font = list(family = "Inter, system-ui, sans-serif", size = 12, color = ink),
      xaxis = list(title = "Thousand years BP", range = c(22,0),
                   gridcolor = grid, zeroline = FALSE,
                   # guide line at the cursor's year
                   showspikes = TRUE, spikemode = "across", spikesnap = "cursor",
                   spikethickness = 1, spikedash = "dot", spikecolor = ink),
      yaxis = list(gridcolor = grid, zerolinecolor = grid),
      yaxis2 = list(gridcolor = grid, zerolinecolor = grid),
      hoverlabel = list(font = list(family = "Inter, system-ui, sans-serif")),
      # room above and to the right for the year marker's label
      margin = list(l = 10, r = 24, t = 24, b = 10),
      showlegend = FALSE
    ) |>
    plotly::config(displayModeBar = FALSE)
}

time_series_server <- function(id,
                               click,
                               data,
                               inputs,
                               dark_mode
                               ) {
  moduleServer(id, function(input, output, session) {

    is_dark = reactive(identical(dark_mode(), "dark"))

# Calculations ------------------------------------------------------------

    # every variable at all 22 time steps for the grid cell closest to the
    # clicked point - feeds both the plot and the download
    cell_data = reactive({
      req(click())

      # the view name comes from the folder names in data/app, not from input
      region = match.arg(data$region, names(statics))
      static = statics[[region]]

      ix = which.min(abs(static$xs - click()$lng))
      iy = which.min(abs(static$ys - click()$lat))

      DBI::dbGetQuery(con,
                      glue::glue("SELECT * FROM cube_{region} WHERE cell = ? ORDER BY year"),
                      params = list((iy - 1L) * length(static$xs) + ix)) |>
        dplyr::mutate(land_type = factor(land_type,
                                         levels = c("water",
                                                    "land",
                                                    "ice")))
    })

# Render Plotly Timeseries ------------------------------------------------

    # location of the cell behind the graphs, as a badge in the card header
    output$location = shiny::renderUI({
      req(!is.null(statics[[data$region]]$xs), click(), nrow(cell_data()) > 0)
      shiny::span(class = "badge rounded-pill bg-body-tertiary text-body border fw-normal",
                  sprintf("%.2f, %.2f", cell_data()$y[1], cell_data()$x[1]))
    })

    output$marker_legend = shiny::renderUI({
      req(!is.null(statics[[data$region]]$xs), click(), nrow(cell_data()) > 0)
      marker_legend()
    })

    output$timeseries_plot = shiny::renderUI({

      if (is.null(statics[[data$region]]$xs)) {
        return(empty_state("hourglass", "No time series for this region yet"))
      }
      if (is.null(click())) {
        return(empty_state("geo-alt", "Click the map to see a time series"))
      }

      # the cube only holds cells with model output
      if (nrow(cell_data()) == 0) {
        return(empty_state("water", "No model data at this point"))
      }

      rsl_data = cell_data() |>
        dplyr::mutate(value = rsl)

      amp_data = cell_data() |>
        dplyr::mutate(value = elevation_amplitude)

      # y-axis fits the plotted RSL, padded; falls back to the old fixed range
      # when the cell has no finite RSL values
      rsl_axis = if (any(is.finite(rsl_data$value))) {
        rsl_axis_limits(range(rsl_data$value, na.rm = TRUE))
      } else {
        list(range = c(-120, 120), dtick = 40)
      }

      # drawn at the current year; the observer below moves it after that, so
      # a year step doesn't redraw the graphs
      marker = isolate(year_marker(as.numeric(inputs$yearBP), is_dark()))

      plotly::subplot(
        ts_plot(rsl_data, "#1f77b4", "RSL",
                list(title = "Relative sea level (m)",
                     range = rsl_axis$range,
                     tick0 = 0, dtick = rsl_axis$dtick)),
        ts_plot(amp_data, "#33a02c", "M₂ amp",
                list(title = "M₂ elevation amplitude (m)",
                     range = c(0,6),
                     fixedrange = TRUE)),
        nrows = 2, shareX = TRUE, titleY = TRUE, margin = 0.06
      ) |>
        ts_layout(dark = is_dark()) |>
        # one shape, not a list of them: after subplot() plotly drops a list
        plotly::layout(shapes = marker$shapes[[1]], annotations = marker$annotations)
    })

    # move the year marker (www/map_layers.js) as the slider or animation steps
    observe({
      req(inputs$yearBP)
      session$sendCustomMessage("ts-year", c(
        # held until the map shows this year (www/map_layers.js)
        list(id = session$ns("timeseries_plot"), year = as.numeric(inputs$yearBP)),
        year_marker(as.numeric(inputs$yearBP), is_dark())
      ))
    })

# Download ----------------------------------------------------------------

    # show button while there is something to download
    observe(shinyjs::toggle("download_data", condition = !is.null(click())))

    output$download_data = shiny::downloadHandler(
      filename = function() {
        # Use the selected dataset as the suggested file name
        paste0(gsub("₂", "2", data$datatype), ".csv")
      },
      content = function(file) {
        to_download = cell_data() |>
          dplyr::rename(longitude = x, latitude = y) |>
          dplyr::mutate(strat = dplyr::case_when(strat == 1 ~ "mixed",
                                                 strat == 2 ~ "frontal",
                                                 strat == 3 ~ "stratified"))

        # Write the dataset to the `file` that will be downloaded
        # the two model runs have different columns
        cols = intersect(download_cols[[data$datatype]], names(to_download))
        write.csv(to_download[cols], file, row.names = FALSE)
      }
    )

    # returns closest lat lon out of it - this will make it easy to
    # plop on a marker for folks to know where they clicked.
    reactive({
      req(nrow(cell_data()) > 0)
      list(lat = cell_data()$y[1],
           lon = cell_data()$x[1])
    })

  })
}
