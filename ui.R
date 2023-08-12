
# Define UI for application that draws a histogram
ui = bslib::page_navbar(

# Setup -------------------------------------------------------------------
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
      ),
    theme = bslib::bs_theme(bootswatch = "cosmo",
                            version = 5,
    ),
    title = "Paleotidal Visualization", 

# Nav Panels --------------------------------------------------------------
## About ------------------------------------------------------------------
    header =  # waiter load animations
      waiter::use_waiter(),
    bslib::nav_panel("About", 
                     about_tab_ui("about_tab_content")), 
## Data Viz ---------------------------------------------------------------
    bslib::nav_panel("Explore Data Visualizations", 
                     bslib::layout_columns(
                       col_widths = c(7, 5),
                       bslib::layout_columns(
                         col_widths = 12,
                         row_heights = c(1,5),
                         bslib::layout_columns(
                           col_widths = c(6, 6),
                           bslib::card(
                            data_select_ui("data_type")
                           ),
                           data_summary_ui("data_summary")
                         )
                         ,
                         bslib::card(
                           leaflet::leafletOutput("map")
                         )
                       ),
                       
                       # Inputs
                       bslib::layout_columns(
                         col_widths = 12,
                         row_heights = c(3,3),
                         bslib::card(
                           bslib::card_title("Inputs"),
                           input_ui("inputs")
                         ),
                         bslib::card(
                           time_series_ui("time_series"),
                           full_screen = TRUE
                         )
                       )
                     )
    ), 
    bslib::nav_spacer(), 
    bslib::nav_menu("Supporting Entities", 
                    align = "right", 
                    bslib::nav_item("Link 1"), 
                    bslib::nav_item("Link 1"))
  )


