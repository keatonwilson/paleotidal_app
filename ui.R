
# Define UI for application that draws a histogram
bslib::page_navbar(
  # theme = bslib::bs_theme(bootswatch = "solar",
  # base_font = bslib::font_google("Cormorant Garamond"),
  # base_font = bslib::font_google("Yanone Kaffeesatz"),
  # base_font = bslib::font_google("Playfair Display")),
                   theme = bslib::bs_theme(bootswatch = "lux",
                                           base_font = bslib::font_google("Cormorant Garamond")),
                   title = "Paleotidal Visualization", 
                   bslib::nav_panel("About", 
                                    about_tab_ui("about_tab_content")), 
                   bslib::nav_panel("Explore Data Visualizations", 
                                    bslib::layout_columns(
                                      col_widths = c(7, 5),
                                      bslib::layout_columns(
                                        col_widths = 12,
                                        row_heights = c(2,5),
                                        bslib::card(
                                          bslib::card_title("Overview"),
                                          data_summary_ui("data_summary")
                                        ),
                                        bslib::card(
                                          "Placeholder Text"
                                        )
                                      ),
                                      
                                      # dummy input card
                                      bslib::card(
                                        input_ui("inputs")
                                      )
                                    )
                                    ), 
                   bslib::nav_spacer(), 
                   bslib::nav_menu("Supporting Entities", 
                                   align = "right", 
                                   bslib::nav_item("Link 1"), 
                                   bslib::nav_item("Link 1"))
                   )
