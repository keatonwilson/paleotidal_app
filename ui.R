
# Define UI for application that draws a histogram
bslib::page_navbar(theme = bslib::bs_theme(bootswatch = "yeti"),
                   title = "Paleotidal Visualization", 
                   bslib::nav_panel("About", 
                                    about_tab_ui("about_tab_content")), 
                   bslib::nav_panel("Explore Data Visualizations",
                                    # map_ui("map") # module version, still not working
                                    layout_column_wrap(
                                      width = 1/2, 
                                      card(full_screen = TRUE,
                                           card_header("Map"),
                                           plotOutput("map"))
                                    )
                   ), 
                   bslib::nav_spacer(), 
                   bslib::nav_menu("Supporting Entities", 
                                   align = "right", 
                                   bslib::nav_item("Link 1"), 
                                   bslib::nav_item("Link 1"))
                   )
