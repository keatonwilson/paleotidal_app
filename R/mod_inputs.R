# First stab at card with inputs

input_ui <- function(id) {
  tagList(
    shinyjs::useShinyjs(),
    selectInput(NS(id, "dataproduct"), label = NULL,
                choices = c("Tidal Amplitude",
                            "Stratification",
                            "Peak Bed Stress",
                            "Tidal Current"),
                selected = "Tidal Amplitude"),
    bslib::navset_card_tab(
      id = "tabs",
      full_screen = FALSE,
      # title = "User inputs",
      bslib::nav_panel("General",
                       # bslib::card_title("Time"),
                       shinyWidgets::sliderTextInput(NS(id, "yearBP"), "Years BP(*1000):",
                                                     choices = 21:0,
                                                     selected = 21, 
                                                     grid = TRUE,
                                                     width = "100%",
                                                     animate = animationOptions(interval = 500,
                                                                                loop = FALSE)),
                       bslib::layout_column_wrap(
                         width = 1/2,
                         checkboxInput(NS(id, "coast"), "Show coastline?",
                                       value = TRUE,
                                       width = '40%'),
                         selectInput(NS(id, "coastyear"), "Select coastline  year:",
                                     choices = 0:21,
                                     selected = 0,
                                     width = '60%'))),
      bslib::nav_panel("Custom",
                       # shinyjs::hidden(
                         div(id = "strat_card",
                             bslib::nav_panel(bslib::card_title("Stratification"),
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
                                                       checkboxInput(NS(id, "gradient"), "Show gradient",
                                                                     value = FALSE),
                                                       uiOutput(NS(id, "dyn_frontvalue")),
                                                       numericInput(NS(id, "frontradius"), "Set front radius:",
                                                                    value = 0.08,
                                                                    min = 0.01, max = 1,
                                                                    step = 0.01)
                                           ))
                             )
                         )
                       # )
      ,
                   bslib::card(bslib::card_title("Peak Bed Stress"),
                                   bslib::layout_column_wrap(
                                     width = 1/2,
                                     bslib::card(bslib::card_title("Vector Spacing"),
                                                 bslib::layout_column_wrap(
                                                   width = 1/2,
                                                   numericInput(NS(id, "X"), "X",
                                                                value = 5,
                                                                min = 1, max = 50,
                                                                step = 1,
                                                                width  = '50%'),
                                                   numericInput(NS(id, "Y"), "Y",
                                                                value = 3,
                                                                min = 1, max = 50,
                                                                step = 1,
                                                                width  = '50%'))),
                                     bslib::card(bslib::card_title("Vector appearance"),
                                                 numericInput(NS(id, "minvec"), "Min. vector magnitude (N/m2):",
                                                              value = 1.0,
                                                              min = 0.0, max = 30.0,
                                                              step = 0.01),
                                                 checkboxInput(NS(id, "arrow"), "Show arrow",
                                                               value = TRUE))
                                   ))
      )
    )
  )
}

input_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
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
    
    # Renders reactive UI for frontvalue based on input$boundaryrange
    output$dyn_frontvalue <- renderUI({
      numericInput("frontvalue", "Set front value:",
                   value = 2.1,
                   min = req(input$boundaryrange[1]), max = req(input$boundaryrange[2]), 
                   step = 0.1)
    })
    
    # WIP hide nav_panel depending on dataproduct selected
    # Works in notes/test.R
    observe({
      print(input$dataproduct)
      if(input$dataproduct %in% c("Tidal Amplitude", "Tidal Current")) {
        bslib::nav_hide("tabs", target = "Custom")
      } else {
        bslib::nav_show("tabs", target = "Custom")
      }
    })
    
    # WIP Set custom card depending on data product
    # works for the id of the UI widget, but not the div
    observe({
      if(input$dataproduct == "Stratification") {
        shinyjs::show(id = "boundaryrange", anim = TRUE)
      } else {
        shinyjs::hide(id = "boundaryrange", anim = TRUE)
      }
      
    })    
    
    # General inputs (applicable to all datasets)
    r1 <- reactive({
      input$dataproduct
    })
    
    r2 <- reactive({
      input$yearBP
    })
    
    r3 <- reactive({
      input$coast
    })
    
    r4 <- reactive({
      input$coastyear
    })
    

    # Stratification inputs (applicable to Stratification dataset)
    r5 <- reactive({
      input$boundaryrange
    })
    
    r6 <- reactive({
      input$contrast
    })
    
    r7 <- reactive({
      input$front
    })
    
    r8 <- reactive({
      input$frontvalue
    })
    
    r9 <- reactive({
      input$frontradius
    })
    
    r10 <- reactive({
      input$gradient
    })
    

    # Peak Stress Vectors inputs (applicable to Peak Bed Stress dataset)
    r11 <- reactive({
      input$X
    })
    
    r12 <- reactive({
      input$Y
    })
    
    r13 <- reactive({
      input$minvec
    })
    
    r14 <- reactive({
      input$arrow
    })
    
    # Make named list of reactive objects and return
    rlist <- list(dataproduct = r1, yearBP = r2, coast = r3, coastyear = r4, 
                  boundaryrange = r5, contrast = r6, front = r7, frontvalue = r8,  frontradius = r9,  gradient = r10,
                  X = r11, Y = r12, minvec = r13, arrow = r14)
    return(rlist)

  })
}