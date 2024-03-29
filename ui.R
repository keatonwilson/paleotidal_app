
# Define UI for application that draws a histogram
ui = bslib::page_navbar(

# Setup -------------------------------------------------------------------
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
      ),
    tags$style(type = "text/css", ".irs-grid-pol.small {height: 0px;}"),
    theme = bslib::bs_theme(bootswatch = "cosmo",
                            version = 5),
    title = "Paleotidal Visualization", 

# Nav Panels --------------------------------------------------------------
## About ------------------------------------------------------------------
    header =  # waiter load animations
      shiny::tagList(waiter::use_waiter()),
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
                         ),
                         bslib::navset_card_tab(
                           full_screen = TRUE,
                           title = "Maps",
                           bslib::nav_panel(
                             "Interactive",
                             leaflet::leafletOutput("map")
                           ),
                           bslib::nav_panel(
                             "Animated",
                             animations_ui("animations")
                           )
                       )
                       ),
                       
                       # Inputs
                       bslib::layout_columns(
                         col_widths = 12,
                         row_heights = c(2,3),
                         bslib::card(
                           bslib::card_title("Inputs"),
                           input_ui("inputs")
                         ),
                        time_series_ui("time_series"),

                       )
                     )
    ), 
    bslib::nav_spacer()
  )


