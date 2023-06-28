# First stab at card with inputs

input_ui <- function(id) {
  tagList(
    shinyjs::useShinyjs(),
    # bslib::card(
    
    # bslib::nav_panel("General",
    # bslib::card_title("Time"),
    selectInput(NS(id, "dataproduct"), "Select data product:",
                choices = c("Tidal Amplitude",
                            "Stratification",
                            "Peak Bed Stress",
                            "Tidal Current"),
                selected = "Tidal Amplitude"),
    # bslib::card(bslib::layout_column_wrap(
    #   width = 1/2,
    checkboxInput(NS(id, "coast"), "Show coastline?",
                  value = TRUE,
                  width = '30%'),
    selectInput(NS(id, "coastyear"), "Select coastline  year:",
                choices = 0:21,
                selected = 0,
                width = '70%'),
    # )),
    shinyWidgets::sliderTextInput(NS(id, "animateyear"), "Animate through time:",
                                  choices = 21:0,
                                  selected = 21, 
                                  grid = TRUE,
                                  width = "100%",
                                  animate = animationOptions(interval = 500,
                                                             loop = FALSE)),
    # shinyjs::hidden(
      div(id = "strat_card",
          bslib::card(bslib::card_title("Stratification"),
                      bslib::layout_column_wrap(
                        width = 1/2,
                        bslib::card(bslib::card_title("Boundary values"),
                                    shinyWidgets::numericRangeInput(NS(id, "boundaryrange"), "Set min and max:",
                                                                    value = c(1.9, 2.9),
                                                                    min = 0, max = 12,
                                                                    step = 0.1),
                                    checkboxInput(NS(id, "contrast"), "Show contrast",
                                                  value = FALSE)),
                        bslib::card(bslib::card_title("Front values"),
                                    checkboxInput(NS(id, "front"), "Show front",
                                                  value = TRUE),
                                    numericInput(NS(id, "frontvalue"), "Set front value:",
                                                 value = 2.1,
                                                 min = 1.9, max = 2.9, # dynamic, updated with range from boundary values
                                                 step = 0.1),
                                    numericInput(NS(id, "frontradius"), "Set front radius:",
                                                 value = 0.08,
                                                 min = 0.01, max = 1,
                                                 step = 0.01),
                                    checkboxInput(NS(id, "gradient"), "Show gradient",
                                                  value = FALSE))))
      )
    # )
  )
                            # )
                # )
      # ,
      # bslib::nav_panel("Custom",
      #                  bslib::card(bslib::card_title("Peak Stress Vectors"),
      #                              bslib::layout_column_wrap(
      #                                width = 1/2,
      #                                bslib::card(bslib::card_title("Vector Spacing"),
      #                                            numericInput(NS(id, "X"), "X",
      #                                                         value = 5,
      #                                                         min = 1, max = 50,
      #                                                         step = 1),
      #                                            numericInput(NS(id, "Y"), "Y",
      #                                                         value = 3,
      #                                                         min = 1, max = 50,
      #                                                         step = 1)),
      #                                bslib::card(bslib::card_title("Vector appearance"),
      #                                            numericInput(NS(id, "minvec"), "Minimum vector magnitude (N/m2):",
      #                                                         value = 1.0,
      #                                                         min = 0.0, max = 30.0,
      #                                                         step = 0.01),
      #                                            checkboxInput(NS(id, "arrow"), "Show arrow",
      #                                                          value = TRUE))
      #                              ))
      # )
}

input_server <- function(id) {
  moduleServer(id, function(input, output, session){
    
    # Grays out coastyear UI if coast == FALSE
    observeEvent(input$coast, {
      shinyjs::toggleState(id = "coastyear", 
                           condition = input$coast)
    })
    
    # Grays out frontvalue and frontradius UI's if front == FALSE
    observeEvent(input$front, {
      shinyjs::toggleState(id = "frontvalue", 
                           condition = input$front)
      
      shinyjs::toggleState(id = "frontradius", 
                           condition = input$front)
      
    })
    
    # Set Custom card depending on data product
    observe({
      if(input$dataproduct == "Stratification") {
        shinyjs::showElement(id = "boundaryrange", anim = TRUE)
      } else {
        shinyjs::hideElement(id = "boundaryrange", anim = TRUE)
      }
    })
    
    # General inputs (applicable to all datasets)
    reactive({
      input$dataproduct
    })
    
    reactive({
      input$ghostcoast
    })
    
    reactive({
      input$coastyear
    })
    

    reactive({
      input$year
    })
    
    reactive({
      input$animateyear
    })
    
    # Stratification inputs (applicable to Stratification dataset)
    reactive({
      input$boundaryrange
    })
    
    reactive({
      input$contrast
    })
    
    reactive({
      input$frontvalue
    })
    
    reactive({
      input$radius
    })
    
    reactive({
      input$front
    })
    
    reactive({
      input$gradient
    })
    
    # Peak Stress Vectors inputs (applicable to Peak Bed Stress dataset)
    reactive({
      input$X
    })
    
    reactive({
      input$Y
    })
    
    reactive({
      input$minvec
    })
    
    reactive({
      input$arrow
    })
    

  })
}