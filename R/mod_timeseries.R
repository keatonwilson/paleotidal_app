time_series_ui <- function(id) {

  ns <- NS(id)
  bslib::card(
    bslib::card_body(
      bslib::as_fill_carrier(
        class = "justify-content-center align-items-center text-align center",
        shiny::uiOutput(ns("timeseries_plot"))
      )
    ),
    bslib::card_body(
      # hide initially
      shinyjs::hidden(shiny::downloadButton(ns("download_data"), "Download Data"))
    ),
    full_screen = TRUE
  )

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
  # depth is a map layer only for now, so this is the amplitude set
  `Water Depth` = c("longitude", "latitude", "year", "land_type",
                    "rsl", "elevation_amplitude")
)

time_series_server <- function(id,
                               click,
                               data
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

    output$timeseries_plot = shiny::renderUI({

      # Default is explanatory text
      #TODO Make this look better with some css
      if (is.null(statics[[data$region]]$xs)) {
        return(shiny::div(class = "font-italic text-secondary",
                          "(No time series for this region yet)"))
      }
      if (is.null(click())) {
        return(shiny::div(class = "font-italic text-secondary",
                          "(Click anywhere on the map to generate timeseries)"))
      }

      closest_lat = cell_data()$y[1]
      closest_lon = cell_data()$x[1]

      rsl_filtered = cell_data() |>
        dplyr::filter(land_type != "land") |>
        dplyr::mutate(value = rsl)

      amp_filtered = cell_data() |>
        dplyr::mutate(value = elevation_amplitude)

      ay <- list(
        tickfont = list(color = "black"),
        overlaying = "y",
        side = "right",
        title = list(text = "Tidal Amplitude (m)",
                     font = list(color = "#33a02c"),
                     standoff = 10L),
        range = c(0,6),
        fixedrange = TRUE)
      # title w lat/lon
      title = glue::glue("Relative Sea Level & Tidal Amplitude @ {closest_lat}, {closest_lon}")
      plotly::plot_ly() |>
        plotly::add_markers(x = ~rsl_filtered$year,
                            y = ~rsl_filtered$value,
                            symbol = ~rsl_filtered$land_type,
                            name = "Relative Sea Level",
                            yaxis = "y1",
                            mode = "markers",
                            type = "scatter",
                            symbols = c(16,18,1),
                            # line = list(color = "#1f77b4"),
                            marker = list(color = "#1f77b4",
                                          size = 8),
                            hoverinfo = "text",
                            text = ~paste('</br> RSL: ', rsl_filtered$value,
                                          '</br> Year: ', rsl_filtered$year, "K BP",
                                          '</br> Landtype: ', stringr::str_to_title(rsl_filtered$land_type))) |>
        plotly::add_markers(x = ~amp_filtered$year,
                            y = ~amp_filtered$value,
                            symbol = ~amp_filtered$land_type,
                            name = "Tidal Amplitude",
                            yaxis = "y2",
                            mode = "markers",
                            type = "scatter",
                            symbols = c(16,18,1),
                            # line = list(color = "#33a02c"),
                            marker = list(color = "#33a02c",
                                          size = 8),
                            hoverinfo = "text",
                            text = ~paste('</br> Tidal Amp: ', amp_filtered$value,
                                          '</br> Year: ', amp_filtered$year, "K BP",
                                          '</br> Landtype: ', stringr::str_to_title(amp_filtered$land_type))) |>
        plotly::add_lines(x = ~rsl_filtered$year,
                          y = ~rsl_filtered$value,
                          name = "Relative Sea Level",
                          yaxis = "y1",
                          line = list(color = "#1f77b4")
        ) |>
        plotly::add_lines(x = ~amp_filtered$year,
                          y = ~amp_filtered$value,
                          name = "Tidal Amplitude",
                          yaxis = "y2",
                          line = list(color = "#33a02c")
        ) |>
        plotly::layout(
          margin = list(r = 75),
          title = title,
          yaxis2 = ay,
          xaxis = list(title = "Thousand Years BP",
                       range = c(22,0)),
          yaxis = list(title = list(text = "Relative Sea Level (m)",
                                    font = list(color = "#1f77b4")),
                       range = c(-120,120),
                       tickvals = list(-120, -80, -40, 0, 40, 80, 120)),
          showlegend = FALSE
        ) |>
        plotly::config(displayModeBar = FALSE)
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
        write.csv(to_download[download_cols[[data$datatype]]], file, row.names = FALSE)
      }
    )

    # returns closest lat lon out of it - this will make it easy to
    # plop on a marker for folks to know where they clicked.
    reactive({
      list(lat = cell_data()$y[1],
           lon = cell_data()$x[1])
    })

  })
}
