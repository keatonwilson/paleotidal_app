
# Define UI for application that draws a histogram
ui = bslib::page_navbar(

# Setup -------------------------------------------------------------------
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
      tags$script(src = "map_layers.js")
      ),
    tags$style(type = "text/css", ".irs-grid-pol.small {height: 0px;}"),
    theme = bslib::bs_theme(bootswatch = "zephyr",
                            version = 5),
    title = "Paleotidal Visualization", 

# Nav Panels --------------------------------------------------------------
## About ------------------------------------------------------------------
    bslib::nav_panel("About", 
                     about_tab_ui("about_tab_content")), 
## Data Viz ---------------------------------------------------------------
    bslib::nav_panel("Explore Data Visualizations", 
                     bslib::layout_columns(
                       col_widths = c(7, 5),
                       bslib::layout_columns(
                         col_widths = 12,
                         # top row sizes to its content; map takes the rest
                         row_heights = list("auto", 1),
                         bslib::layout_columns(
                           col_widths = c(5, 7),
                           bslib::card(
                            class = "compact-card",
                            data_select_ui("data_type")
                           ),
                           input_ui("inputs")
                         ),
                         bslib::card(
                           full_screen = TRUE,
                           bslib::card_header("Map"),
                           leaflet::leafletOutput("map")
                         )
                       ),
                       
                       # Time series
                       time_series_ui("time_series")
                     )
    ), 
    bslib::nav_spacer()
  )


