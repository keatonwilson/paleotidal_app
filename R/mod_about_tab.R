# these module functions could have better documentation via roxygen2
about_tab_ui <- function(id) {
  ns <- NS(id)

# Main Content for Tab ----------------------------------------------------
  shiny::tagList(

  ## Column 1 --------------------------------------------------------------
    bslib::layout_column_wrap(
      width = 1/2, 
      height = 300,
      
      # calls other module from mod_card.R
      card_ui(ns("how_to_use_card"), 
              "How to Use", 
              tagList(
                p(
                  "PALTIDE is on online web-based data portal tool with intuitive 
                  user interface to enable users to  visualise, interrogate and 
                  download datasets on relative sea level, palaeotidal amplitudes 
                  and other tide-dependant parameters.  The model domain is the 
                  northwest European continental shelf covering the period from 
                  the Last Glacial Maximum to the present day. The tool is based 
                  on the glacial isostatic adjustment (GIA) simulations in Bradley 
                  et al. (2011) and hydrodynamic simulations using the Regional 
                  Ocean Modelling System (ROMS) published by Ward et al. (2016). 
                  A technical description of the input simulations and visualisation 
                  software is provided by Scourse et al. (in press)."
                ), 
                p(
                  "On the “Explore Data Visualisations” tab, the “Maps” section 
                  enables visualisation of two-dimensional colour (raster) plots 
                  of tidal amplitude, stratification, peak bed stress and tidal 
                  current. Point-location data can be downloaded by moving the 
                  cursor and clicking on a chosen location; these data downloads 
                  are specific to the ocean model variable being viewed. Users can 
                  interrogate the maps using the “Interactive” tab and by sliding 
                  the age-scale, or can run a time-sequence animation under the 
                  “Animate” tab. A zoom function is available, and maps can be 
                  moved using click-and-grab functionality with the cursor. 
                  Further description of functionality is available in Scourse et 
                  al. (submitted). "
                )
              )
              ),

## Column 2 Nested ---------------------------------------------------------

      bslib::layout_column_wrap(
        width = 1, 
        heights_equal = "row",
        
        # re-uses modules like above
        card_ui(
          ns("ack"),
          "Acknowledgements",
          # items passed to the content argument in the card_ui function have 
          # to be wrapped in a tagList
          content = shiny::tagList(
            # lapply(lorem::ipsum(
            #   paragraphs = 3,
            #   sentences = c(5, 2, 5)
            # ),
            # tags$p),
            # example of inserting an image with a custom width, if you need 
            # complex layouts/combinations, you'll probably have to wrap in a 
            # div - check out https://rstudio.github.io/bslib/articles/cards/#multiple-columns
            shiny::img(src = "comb_logos.png", width = "80%"),
            htmltools::h6(
              "App designed by: ",
              htmltools::a("James Scourse", href = "mailto:J.Scourse@exeter.ac.uk", .noWS = "outside"),
              ", ",
              htmltools::a("Sophie Ward", href = "mailto:sophie.ward@bangor.ac.uk", .noWS = "outside")
            ),
            htmltools::h6("App developed by: Keaton Wilson, Jessica Guo")
          )
        ),
        card_ui(ns("how_to_cite"),
                "How to cite",
                tagList(
                  p("Data from this tool can be freely published with citation 
                    to the following three publications:"), 
                  tags$ol(
                    tags$li("Scourse JD, Ward SL, Wainwright A, Bradley SL, 
                            Wilson JK and Guo J (submitted). An interactive 
                            visualisation and data portal tool (PALTIDE) 
                            for relative sea level and palaeo-tidal simulations 
                            of the northwest European shelf seas since the 
                            Last Glacial Maximum.", 
                            tags$em("Journal of Quaternary Science.") 
                            ), 
                    tags$li("Ward SL, Neill SP, Scourse JD, Bradley SL and 
                            Uehara K 2016. Sensitivity of palaeotidal models of 
                            the northwest European shelf seas to glacial 
                            isostatic adjustment since the Last Glacial Maximum.", 
                            tags$em("Quaternary Science Reviews"), 
                            HTML('&nbsp;'),
                            tags$b("151"), 
                            ", 198-211."), 
                    tags$li("Bradley SL, Milne GA, Shennan I and Edwards R 
                            2011. An improved glacial isostatic adjustment model 
                            for the British Isles.", 
                            tags$em("Journal of Quaternary Science"), 
                            HTML('&nbsp;'),
                            tags$b("26"), 
                            ", 541-552.")
                  )
                )
                )
      )
    )
  )
}


about_tab_server <- function(id) {
  moduleServer(id, function(input, output, session) {
  # We don't need anything in the server for this module
    
  })
}



