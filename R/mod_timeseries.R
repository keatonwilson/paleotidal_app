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

# columns in the downloaded csv, by data type
download_cols = list(
  `Tidal Amplitude` = c("longitude", "latitude", "year", "land_type",
                        "rsl", "elevation_amplitude"),
  `Tidal Current` = c("longitude", "latitude", "year", "land_type",
                      "vel", "rsl", "elevation_amplitude"),
  `Stratification` = c("longitude", "latitude", "year", "land_type",
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

# one variable through time at the clicked cell: markers by land type on a line
ts_plot = function(df, colour, label, yaxis) {
  plotly::plot_ly(df, x = ~year, y = ~value) |>
    plotly::add_lines(line = list(color = colour, width = 2),
                      hoverinfo = "skip") |>
    plotly::add_markers(symbol = ~land_type,
                        symbols = c(16,18,1),
                        marker = list(color = colour, size = 8),
                        text = ~stringr::str_to_title(land_type),
                        hovertemplate = paste0(label, ": %{y} m<br>",
                                               "%{x}K BP · %{text}<extra></extra>")) |>
    plotly::layout(yaxis = yaxis)
}

# dashed line through both graphs at the year on the map, labelled above
year_marker = function(year, dark) {
  colour = if (dark) "#5eead4" else "#0b6e7f"
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
  ink = if (dark) "#cbd5e1" else "#334155"
  grid = if (dark) "rgba(255,255,255,0.08)" else "rgba(15,23,42,0.08)"
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

      rsl_filtered = cell_data() |>
        dplyr::filter(land_type != "land") |>
        dplyr::mutate(value = rsl)

      amp_filtered = cell_data() |>
        dplyr::mutate(value = elevation_amplitude)

      # drawn at the current year; the observer below moves it after that, so
      # a year step doesn't redraw the graphs
      marker = isolate(year_marker(as.numeric(inputs$yearBP),
                                   identical(dark_mode(), "dark")))

      plotly::subplot(
        ts_plot(rsl_filtered, "#1f77b4", "RSL",
                list(title = "Relative sea level (m)",
                     range = c(-120,120),
                     tickvals = list(-120, -80, -40, 0, 40, 80, 120))),
        ts_plot(amp_filtered, "#33a02c", "Tidal amp",
                list(title = "Tidal amplitude (m)",
                     range = c(0,6),
                     fixedrange = TRUE)),
        nrows = 2, shareX = TRUE, titleY = TRUE, margin = 0.06
      ) |>
        ts_layout(dark = identical(dark_mode(), "dark")) |>
        # one shape, not a list of them: after subplot() plotly drops a list
        plotly::layout(shapes = marker$shapes[[1]], annotations = marker$annotations)
    })

    # move the year marker (www/map_layers.js) as the slider or animation steps
    observe({
      req(inputs$yearBP)
      session$sendCustomMessage("ts-year", c(
        list(id = session$ns("timeseries_plot")),
        year_marker(as.numeric(inputs$yearBP), identical(dark_mode(), "dark"))
      ))
    })

# Download ----------------------------------------------------------------

    # show button while there is something to download
    observe(shinyjs::toggle("download_data", condition = !is.null(click())))

    output$download_data = shiny::downloadHandler(
      filename = function() {
        # Use the selected dataset as the suggested file name
        paste0(data$datatype, ".csv")
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
