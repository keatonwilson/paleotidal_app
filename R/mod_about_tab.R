# these module functions could have better documentation via roxygen2
about_tab_ui <- function(id) {
  ns <- NS(id)

# Main Content ------------------------------------------------------------
  # three full-width cards stacked vertically
  bslib::layout_column_wrap(
    width = 1,
    fill = FALSE,

    ## How to Use ------------------------------------------------------------
    # calls other module from mod_card.R
    card_ui(ns("how_to_use_card"), 
            "How to Use", 
            tagList(
              p(
                "PALTIDE+ is an online web-based data portal with an intuitive user 
                interface that enables users to visualise, interrogate and download 
                reconstructions of relative sea level, ice-sheet extent and thickness, 
                palaeotidal dynamics, and derived tidal metrics through time. The 
                platform includes datasets for both the Northwest European Shelf Seas 
                and the Patagonian Shelf spanning the Last Glacial Maximum at 21 ka to 
                the present day at 1 ka intervals."
              ), 
              p(
                "PALTIDE+ brings together two generations of PALTIDE datasets within a 
                single portal. The original Northwest European Shelf Seas reconstructions 
                remain available through a dedicated PALTIDE1 data-selection tab for 
                reproducibility and comparison, while the PALTIDE+ datasets provide updated 
                reconstructions for the Northwest European Shelf Seas based on the latest 
                glacial isostatic adjustment and palaeotidal modelling frameworks, together 
                with new reconstructions for the Patagonian Shelf. Available datasets include 
                relative sea level, ice-sheet extent and thickness, palaeobathymetry, palaeotidal
                 amplitudes, bed shear stress, seasonal stratification, M₂ tidal elevation 
                 amplitude and spring tidal range. Different glacial isostatic adjustment 
                 and hydrodynamic modelling frameworks underpin the PALTIDE1 and PALTIDE+ 
                  datasets; users should consult the relevant source publications below for
                 full methodological details."
              ), 
              p(
                "On the “Explore Data Visualisations” tab, the “Maps” section 
                enables visualisation of two-dimensional colour (raster) plots 
                of palaeoenvironmental variables through time. Point-location 
                data can be downloaded by moving the cursor and clicking on a 
                chosen location; these downloads are specific to the variable being 
                viewed. Users can interrogate the maps by adjusting the time slider 
                or run a time-sequence animation using the play button beneath it. 
                A zoom function is available, and maps can be moved using click-and-drag 
                functionality with the cursor. Further description of functionality is 
                available in XXX."
              )
            )
    ),

    ## How to cite -----------------------------------------------------------
    card_ui(ns("how_to_cite"),
            "How to cite",
            tagList(
              p("Data from this tool can be freely published with 
              citation to the following publications:"), 
              tags$h6("PALTIDE1"),
              tags$ol(
                tags$li("Scourse, J., Ward, S., Wainwright, A., Bradley, S., 
                        Wilson, J.K. and Guo, J., 2024. An interactive 
                        visualization and data portal tool (PALTIDE) for 
                        relative sea level and palaeotidal simulations of 
                        the northwest European shelf seas since the Last 
                        Glacial Maximum.", 
                        tags$em("Journal of Quaternary Science."), 
                        " DOI: ",
                        tags$a("10.1002/jqs.3615", 
                               target = "_blank", 
                               href = "https://doi.org/10.1002/jqs.3615") 
                        )
              ),
              tags$h6("PALTIDE2"),
              tags$ol(
                tags$li("PALTIDE+ publication..."),
                tags$li("Ward, S.L., Bradley, S.L., Roseby, Z.A., Wilmes, S.B., 
                        Vosper, D.F., Roberts, C.M. and Scourse, J.D., 2025. 
                        The role of long-term hydrodynamic evolution in the 
                        accumulation and preservation of organic carbon-rich 
                        shelf sea deposits.", 
                        tags$em("Journal of Geophysical Research: Oceans."), 
                        " DOI: ",
                        tags$a("10.1029/2024JC022092", 
                               target = "_blank", 
                               href = "https://doi.org/10.1029/2024JC022092")
                        ),
                tags$li("Ward, S.L., Bradley, S.L., Wilmes, S.B., Roseby, Z.A., 
                        Green, J.A.M., Robins, P.E., Roberts, C.M. and 
                        Scourse, J.D., 2026. Relative sea-level change, tidal 
                        evolution and energy dissipation across the Patagonian 
                        Shelf since the Last Glacial Maximum.", 
                        tags$em("Paleoceanography and Paleoclimatology."), 
                        " DOI: ",
                        tags$a("10.1029/2025PA005384", 
                               target = "_blank", 
                               href = "https://doi.org/10.1029/2025PA005384")
                        )
              )
            )
    ),

    ## Acknowledgements ------------------------------------------------------
    card_ui(
      ns("ack"),
      "Acknowledgements",
      # items passed to the content argument in card_ui have to be wrapped in 
      # a tagList
      content = shiny::tagList(
        shiny::img(src = "comb_logos.png", width = "80%"),
        htmltools::h6(
          "App designed by: ",
          htmltools::a("James Scourse", href = "mailto:J.Scourse@exeter.ac.uk", .noWS = "outside"),
          ", ",
          htmltools::a("Sophie Ward", href = "mailto:sophie.ward@bangor.ac.uk", .noWS = "outside")
        ),
        htmltools::h6("App developed by: Keaton Wilson, Jessica Guo")
      )
    )
  )
}


# Welcome modal with the About content. Shown at the start of every session and
# whenever the navbar "About" link is clicked.
about_modal <- function(id = "about_tab_content") {
  shiny::modalDialog(
    title = "Welcome to PALTIDE",
    about_tab_ui(id),
    size = "l",
    easyClose = TRUE,
    footer = shiny::modalButton("Start exploring")
  )
}

