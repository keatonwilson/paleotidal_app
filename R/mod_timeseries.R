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
      # fixed height (no fill) so the card never squeezes it and adds a scrollbar
      fill = FALSE,
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
ts_plot = function(df, colour, label, title, yaxis) {
  plotly::plot_ly() |>
    plotly::add_lines(x = ~df$year,
                      y = ~df$value,
                      line = list(color = colour),
                      hoverinfo = "none") |>
    plotly::add_markers(x = ~df$year,
                        y = ~df$value,
                        symbol = ~df$land_type,
                        symbols = c(16,18,1),
                        marker = list(color = colour, size = 8),
                        hoverinfo = "text",
                        text = ~paste('</br>', paste0(label, ': '), df$value,
                                      '</br> Year: ', df$year, "K BP",
                                      '</br> Landtype: ', stringr::str_to_title(df$land_type))) |>
    plotly::layout(
      title = title,
      xaxis = list(title = "Thousand Years BP", range = c(22,0)),
      yaxis = yaxis,
      showlegend = FALSE
    ) |>
    plotly::config(displayModeBar = FALSE)
}

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

      # the cube only holds cells with model output
      if (nrow(cell_data()) == 0) {
        return(shiny::div(class = "font-italic text-secondary",
                          "(No model data at this point)"))
      }

      closest_lat = cell_data()$y[1]
      closest_lon = cell_data()$x[1]

      rsl_filtered = cell_data() |>
        dplyr::filter(land_type != "land") |>
        dplyr::mutate(value = rsl)

      amp_filtered = cell_data() |>
        dplyr::mutate(value = elevation_amplitude)

      shiny::tagList(
        ts_plot(rsl_filtered, "#1f77b4", "RSL",
                glue::glue("Relative Sea Level @ {closest_lat}, {closest_lon}"),
                list(title = list(text = "Relative Sea Level (m)",
                                  font = list(color = "#1f77b4")),
                     range = c(-120,120),
                     tickvals = list(-120, -80, -40, 0, 40, 80, 120))),
        ts_plot(amp_filtered, "#33a02c", "Tidal Amp",
                glue::glue("Tidal Amplitude @ {closest_lat}, {closest_lon}"),
                list(title = list(text = "Tidal Amplitude (m)",
                                  font = list(color = "#33a02c")),
                     range = c(0,6),
                     fixedrange = TRUE))
      )
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
