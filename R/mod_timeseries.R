time_series_ui <- function(id) {
  
  ns <- NS(id)
  plotly::plotlyOutput(ns("timeseries_plot"))
  
}


time_series_server <- function(id, 
                               map_click_obj, 
                               inputs, 
                               rsl_data, 
                               amp_data
                               ) {
  moduleServer(id, function(input, output, session) {
    req(map_click_obj)
    
    # find closest lat/lon to clicked point
    closest_lat = unique(rsl_data$y)[which.min(abs(unique(rsl_data$y) - map_click_obj$lat))]
    closest_lon = unique(rsl_data$x)[which.min(abs(unique(rsl_data$x) - map_click_obj$lng))]
    
    # filter by closest
    rsl_filtered = rsl_data |>
      dplyr::filter(y == closest_lat & x == closest_lon)
    
    amp_filtered = amp_data |> 
      dplyr::filter(y == closest_lat & x == closest_lon)
    
    ay <- list(
      tickfont = list(color = "black"),
      overlaying = "y",
      side = "right",
      title = list(text = "Tidal Amplitude",
                   font = list(color = "#33a02c")))
    
    # title w lat/lon
    title = glue::glue("Relative Sea Level & Tidal Amplitude @ {closest_lat}, {closest_lon}")
    
    # render plotly
    output$timeseries_plot = plotly::renderPlotly({
      plotly::plot_ly() |> 
        plotly::add_trace(x = ~rsl_filtered$year, 
                          y = ~rsl_filtered$value, 
                          name = "Relative Sea Level", 
                          yaxis = "y1", 
                          mode = "lines+markers", 
                          type = "scatter",
                          line = list(color = "#1f77b4"),
                          marker = list(color = "#1f77b4")) |> 
        plotly::add_trace(x = ~amp_filtered$year, 
                          y = ~amp_filtered$value, 
                          name = "Tidal Amplitude", 
                          yaxis = "y2", 
                          mode = "lines+markers", 
                          type = "scatter",
                          line = list(color = "#33a02c"),
                          marker = list(color = "#33a02c")) |> 
        plotly::layout(
          title = title, yaxis2 = ay,
          xaxis = list(title = "Thousand Years BP", 
                       autorange = "reversed"),
          yaxis = list(title = list(text = "Relative Sea Level",
                                    font = list(color = "#1f77b4"))),
          showlegend = FALSE
        )
    })
    
    # function returns closest lat lon out of it - this will make it easy to 
    # plop on a marker for folks to know where they clicked. 
    return(list(lat = closest_lat, 
                lon = closest_lon))
    
  })
}