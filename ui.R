
# Define UI for application that draws a histogram
ui = bslib::page_navbar(
    # theme = bslib::bs_theme(bootswatch = "solar",
    # base_font = bslib::font_google("Cormorant Garamond"),
    # base_font = bslib::font_google("Yanone Kaffeesatz"),
    # base_font = bslib::font_google("Playfair Display")),
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
      ),
    theme = bslib::bs_theme(bootswatch = "cosmo",
                            version = 5,
                            # base_font = bslib::font_google("Cormorant Garamond")
    ),
    title = "Paleotidal Visualization", 
    bslib::nav_panel("About", 
                     about_tab_ui("about_tab_content")), 
    bslib::nav_panel("Explore Data Visualizations", 
                     bslib::layout_columns(
                       col_widths = c(7, 5),
                       bslib::layout_columns(
                         col_widths = 12,
                         row_heights = c(1,5),
                         bslib::layout_columns(
                           col_widths = c(4, 8),
                           bslib::card(
                            data_select_ui("data_type")
                           ),
                           data_summary_ui("data_summary")
                         )
                         # bslib::card(
                         #   bslib::layout_column_wrap(
                         #     width = 1 / 3,
                         #     data_select_ui("data_type"),
                         #     data_summary_ui("data_summary")
                         #   )
                         # )
                         ,
                         bslib::card(
                           leaflet::leafletOutput("map")
                         )
                       ),
                       
                       # dummy input card
                       bslib::layout_columns(
                         col_widths = 12,
                         row_heights = c(4,2),
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


