# First stab at card with inputs

input_ui <- function(id) {
  tagList(
    shinyjs::useShinyjs(),
    bslib::navset_card_tab(
      id = "tabs",
      full_screen = TRUE,
      title = "User inputs",
      bslib::nav_panel("General",
                # bslib::card_title("Time"),
                selectInput(NS(id, "dataproduct"), "Select data product:",
                            choices = c("Tidal Amplitude",
                                        "Stratification",
                                        "Peak Bed Stress",
                                        "Tidal Current"),
                            selected = "Tidal Amplitude"),
                shinyWidgets::sliderTextInput(NS(id, "yearBP"), "Years BP(*1000):",
                            choices = 21:0,
                            selected = 21, 
                            grid = TRUE,
                            width = "100%",
                            animate = animationOptions(interval = 500,
                                                       loop = FALSE)),
                bslib::card(bslib::layout_column_wrap(
                  width = 1/2,
                  checkboxInput(NS(id, "coast"), "Show coastline?",
                                value = TRUE,
                                width = '40%'),
                  selectInput(NS(id, "coastyear"), "Select coastline  year:",
                              choices = 0:21,
                              selected = 0,
                              width = '60%')))),
      bslib::nav_panel("Custom",
                       shinyjs::hidden(
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
                                                       checkboxInput(NS(id, "gradient"), "Show gradient",
                                                                     value = FALSE),
                                                       uiOutput("dyn_frontvalue"),
                                                       numericInput(NS(id, "frontradius"), "Set front radius:",
                                                                    value = 0.08,
                                                                    min = 0.01, max = 1,
                                                                    step = 0.01)
                                           ))
                                         )
                         )
                       ),
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
                                                                width  = '40%'),
                                                   numericInput(NS(id, "Y"), "Y",
                                                                value = 3,
                                                                min = 1, max = 50,
                                                                step = 1,
                                                                width  = '40%'))),
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
  moduleServer(id, function(input, output, session){
    
    # Grays out coastyear UI if coast == FALSE
    observeEvent(input$coast, {
      shinyjs::toggleState(id = "coastyear", 
                           condition = input$coast)
    })
    
    # WIP remove Custom tab for two Tidal dataproducts
    observeEvent(input$dataproduct, {
      if(input$dataproduct %in% c("Tidal Amplitude", "Tidal Current")) {
        bslib::nav_remove(id = "tabs", target = "Custom")
      }
    })
    
    # WIP Set Custom card depending on data product
    observeEvent(input$dataproduct, {
      # is_strat <- ifelse(input$dataproduct == "Stratification", TRUE, FALSE)
      shinyjs::toggle(id = "strat_card", 
                      condition = input$dataproduct == "Stratification")
    })
    
    # Grays out frontvalue and frontradius UIs if front == FALSE
    observeEvent(input$front, {
      shinyjs::toggleState(id = "frontvalue", 
                           condition = input$front)
      shinyjs::toggleState(id = "frontradius", 
                           condition = input$front)
    })
    
    # WIP Updates frontvalues range based on boundaryvalues
    output$dyn_frontvalue <- renderUI({
      req(input$boundaryrange) # Not sure if this is necessary
      
      numericInput(NS(id, "frontvalue"), "Set front value:",
                   value = 2.1,
                   min = input$boundaryrange[1], max = input$boundaryrange[2], 
                   step = 0.1)
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
      input$gradient
    })
    
    r9 <- reactive({
      input$frontvalue
    })
    
    r10 <- reactive({
      input$frontradius
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
                  boundaryrange = r5, contrast = r6, front = r7, gradient = r8, frontvalue = r9, frontradius = r10,
                  X = r11, Y = r12, minvec = r13, arrow = r14)
    return(rlist)

  })
}