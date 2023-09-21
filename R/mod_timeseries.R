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


time_series_server <- function(id, 
                               map_click_obj, 
                               inputs, 
                               rsl_data, 
                               amp_data,
                               data,
                               remaining_data
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
  
# Calculations ------------------------------------------------------------
      # find closest lat/lon to clicked point
      closest_lat = unique(rsl_data$y)[which.min(abs(unique(rsl_data$y) - map_click_obj$lat))]
      closest_lon = unique(rsl_data$x)[which.min(abs(unique(rsl_data$x) - map_click_obj$lng))]
      
      # filter by closest
      rsl_filtered = rsl_data |>
        dplyr::filter(y == closest_lat & x == closest_lon) |> 
        dplyr::mutate(land_type = factor(land_type, 
                                         levels = c("water", 
                                                    "land", 
                                                    "ice")))
      
      amp_filtered = amp_data |> 
        dplyr::filter(y == closest_lat & x == closest_lon) |> 
        dplyr::mutate(land_type = factor(land_type, 
                                         levels = c("water", 
                                                    "land", 
                                                    "ice")))
      

# Render Plotly Timeseries ------------------------------------------------


      output$timeseries_plot = shiny::renderUI({
       
        
          ay <- list(
            tickfont = list(color = "black"),
            overlaying = "y",
            side = "right",
            title = list(text = "Tidal Amplitude (m)",
                         font = list(color = "#33a02c"),
                         standoff = 10L))
          # title w lat/lon
          title = glue::glue("Relative Sea Level & Tidal Amplitude @ {closest_lat}, {closest_lon}")
          plotly::plot_ly() |> 
            plotly::add_markers(x = ~rsl_filtered$year, 
                              y = ~rsl_filtered$value, 
                              symbol = ~amp_filtered$land_type,
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
                                        font = list(color = "#1f77b4"))),
              showlegend = FALSE
            ) |> 
            plotly::config(displayModeBar = FALSE)
      })
      
      # hide loading  
      timeseries_w$hide()
      
      # Download Data Wrangling -------------------------------------------------
      
      # show button
      shinyjs::show("download_data")
      
      
      # Show button
      output$download_data = shiny::downloadHandler(
        filename = function() {
          # Use the selected dataset as the suggested file name
          paste0(data$datatype, ".csv")
        },
        content = function(file) {
          
          shiny::withProgress(message = "Preparing data for download", 
                              min = 0, 
                              max = 5,
                              value = 1, {
            # combine all data and filter for points clicked points identfied above
            # drastically reduces data size and makes for faster computations
            all_data_in_list = purrr::list_modify(remaining_data, 
                                                  rsl_data = rsl_data, 
                                                  amp_data = amp_data) |> 
              purrr::map(function(data) {
                data |> 
                  dplyr::filter(y == closest_lat & x == closest_lon)
              })
            
            shiny::incProgress(2)
            
            
  
            
            # move wrangling to download handler so it doesn't happen unless it 
            # needs to
            
            data_to_include = switch(data$datatype, 
                                     "Tidal Amplitude" = c("amp_data", "rsl_data"),
                                     "Stratification" = c("amp_data", "rsl_data", "strat_data"), 
                                     "Peak Bed Stress" = c("amp_data", "rsl_data", "bss_data"), 
                                     "Tidal Current" = c("amp_data", "rsl_data", "vel_data")
            )
            shiny::incProgress(3)
            
            
     
            # keep appropriate data and bind
            
            if(data$datatype %in% c("Tidal Amplitude", "Tidal Current")) {
              to_download = purrr::keep_at(all_data_in_list, 
                                           ~.x %in% data_to_include) |> 
                dplyr::bind_rows() |> 
                tidyr::pivot_wider(names_from = datatype, values_from = value)
            } else if (data$datatype == "Stratification") {
              to_download = purrr::keep_at(all_data_in_list, 
                                           ~.x %in% data_to_include) |> 
                dplyr::bind_rows() |> 
                tidyr::pivot_wider(names_from = datatype, values_from = value) |> 
                dplyr::mutate(strat = dplyr::case_when(strat == 1 ~ "mixed",
                                                strat == 2 ~ "frontal",
                                                strat == 3 ~ "stratified"))
              
            } else if (data$datatype == "Peak Bed Stress") {
              init = purrr::keep_at(all_data_in_list, 
                                    ~.x %in% data_to_include) |> 
                dplyr::bind_rows() |>
                dplyr::filter(datatype != "bss") |> 
                tidyr::pivot_wider(id_cols = 1:3, names_from = datatype,
                                   values_from = value)
              
              bss = purrr::keep_at(all_data_in_list, 
                                   ~.x %in% data_to_include) |> 
                dplyr::bind_rows() |>
                dplyr::filter(datatype == "bss") |>
                dplyr::select(u:quadrant)
              
              to_download = dplyr::bind_cols(init, bss)
            }
            
            shiny::incProgress(4)
            
            
            
            # Write the dataset to the `file` that will be downloaded
            write.csv(to_download, file)
            shiny::incProgress(5)
          
          })

        }
      )
      
      
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
        shiny::div(class = "font-italic text-secondary",
                   "(Click anywhere on the map to generate timeseries)")
      })
      
      return(NULL)
    }
    

  })
}