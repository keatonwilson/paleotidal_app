time_series_ui <- function(id) {
  
  ns <- NS(id)
  tagList(
    shiny::uiOutput(ns("timeseries_plot"))
  )
  
  
  
}


time_series_server <- function(id, 
                               map_click_obj, 
                               inputs, 
                               rsl_data, 
                               amp_data,
                               data, 
                               tibbles
                               ) {
  moduleServer(id, function(input, output, session) {

  ns = session$ns
# Loading Animation -------------------------------------------------------

    # setup waiter for loading animations
    timeseries_w = waiter::Waiter$new(
      id = ns("timeseries_plot"),
      html = waiter::spin_3(),
      color = waiter::transparent(.5)
    )
    
    # only run if a click happens, else display text
    if (!is.null(map_click_obj)) {
      
      # show loading  
      timeseries_w$show()
      
# Prepare long data to download
      tibble_selected = switch(data$datatype,
                               `Tidal Amplitude` = tibbles$amp_data, 
                               `Stratification` = tibbles$strat_data,
                               `Peak Bed Stress` = tibbles$bss_data,
                               `Tidal Current` = tibbles$vel_data
      )
     
     if (data$datatype == `Stratification`) {
       tibble_selected <- tibble_selected |> 
         dplyr::rename(strat_log10 = value) |> 
         dplyr::select(-datatype) 
     } else if (data$datatype == `Peak Bed Stress`) {
       tibble_selected <- tibble_selected |> 
         dplyr::select(-datatype)
     } else if (data$datatype == `Tidal Current`) {
       tibble_selected <- tibble_selected |> 
         dplyr::rename(vel_m2 = value) |> 
         dplyr::select(-datatype) 
     } else if (data$datatype == `Tidal Amplitude`) {
       tibble_selected <- tibble_selected |> 
         dplyr::select(-datatype, -value)
     }
     
     to_download = rsl_data |> 
       dplyr::rename(rsl_m = value) |> 
       dplyr::select(-datatype) |> 
       dplyr::relocate(year) |> 
       dplyr::left_join(amp_data, by = c("x", "y", "year")) |> 
       dplyr::rename(amp_m = value) |> 
       dplyr::select(-datatype) |> 
       dplyr::left_join(tibble_selected, by = c("x", "y", "year"))
     
# Calculations ------------------------------------------------------------
      # find closest lat/lon to clicked point
      closest_lat = unique(rsl_data$y)[which.min(abs(unique(rsl_data$y) - map_click_obj$lat))]
      closest_lon = unique(rsl_data$x)[which.min(abs(unique(rsl_data$x) - map_click_obj$lng))]
      
      # filter by closest
      rsl_filtered = rsl_data |>
        dplyr::filter(y == closest_lat & x == closest_lon)
      
      amp_filtered = amp_data |> 
        dplyr::filter(y == closest_lat & x == closest_lon)
      

# Render Plotly Timeseries ------------------------------------------------

      output$timeseries_plot = shiny::renderUI({
       
        
          ay <- list(
            tickfont = list(color = "black"),
            overlaying = "y",
            side = "right",
            title = list(text = "Tidal Amplitude",
                         font = list(color = "#33a02c"),
                         standoff = 10L))
          
          # title w lat/lon
          title = glue::glue("Relative Sea Level & Tidal Amplitude @ {closest_lat}, {closest_lon}")
          
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
              margin = list(r = 75),
              title = title, yaxis2 = ay,
              xaxis = list(title = "Thousand Years BP", 
                           autorange = "reversed"),
              yaxis = list(title = list(text = "Relative Sea Level",
                                        font = list(color = "#1f77b4"))),
              showlegend = FALSE
            ) |> 
            plotly::config(displayModeBar = FALSE)
      })
      
      # show loading  
      timeseries_w$hide()
      
      # function returns closest lat lon out of it - this will make it easy to 
      # plop on a marker for folks to know where they clicked. 
      return(list(lat = closest_lat, 
                  lon = closest_lon))
      


    } else {

# Default is explanatory text ---------------------------------------------
      
      #TODO Make this look better with some css      
      output$timeseries_plot = shiny::renderUI({
        # show loading  
        timeseries_w$hide()
        shiny::h2("Click anywhere on the map to generate timeseries.")
      })
      
      return(NULL)
    }
    

  })
}