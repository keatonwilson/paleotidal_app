# First stab at card with inputs

input_ui <- function(id) {
  tagList(

# Waiter and shinyJS Set --------------------------------------------------
    waiter::autoWaiter(),
    shinyjs::useShinyjs(),

# Datatype Dropdown -------------------------------------------------------

    selectInput(
      NS(id, "datatype"),
      label = NULL,
      choices = c(
        "Tidal Amplitude",
        "Stratification",
        "Peak Bed Stress",
        "Tidal Current"
      ),
      selected = "Tidal Amplitude"
    ),

# General and Custom Tab Panels -------------------------------------------

    bslib::navset_card_tab(
      id = NS(id, "tabs"),
      full_screen = FALSE,
      # title = "User inputs",
  ## General Panel ----------------------------------------------------------
      bslib::nav_panel(
        "General",
        # bslib::card_title("Time"),
        shinyWidgets::sliderTextInput(
          NS(id, "yearBP"),
          "Years BP(*1000):",
          choices = 21:0,
          selected = 21,
          grid = TRUE,
          width = "100%",
          animate = animationOptions(interval = 1000,
                                     loop = FALSE)
        ),
        bslib::layout_column_wrap(
          width = 1 / 2,
          checkboxInput(
            NS(id, "coast"),
            "Show coastline?",
            value = TRUE,
            width = '40%'
          ),
          selectInput(
            NS(id, "coastyear"),
            "Select coastline  year:",
            choices = 0:21,
            selected = 0,
            width = '60%'
          )
        )
      ),
  ## Custom Panel ----------------------------------------------------------
      bslib::nav_panel(
        "Custom",
        bslib::layout_columns(
          row_heights = c(3, 5),
          bslib::nav_panel(
            bslib::card_title("Stratification"),
            bslib::layout_column_wrap(
              width = 1 / 2,
              bslib::card(
                bslib::card_title("Boundary values"),
                shinyWidgets::numericRangeInput(
                  NS(id, "boundaryrange"),
                  "Set min and max:",
                  value = c(1.9, 2.9),
                  min = 0,
                  max = 12,
                  step = 0.1
                ),
                checkboxInput(NS(id, "contrast"), "Show contrast",
                              value = FALSE)
              ),
              bslib::card(
                bslib::card_title("Front values"),
                bslib::card_body(
                  bslib::layout_columns(
                    col_widths = c(6, 6),
                    checkboxInput(NS(id, "front"), "Show front",
                                  value = TRUE),
                    checkboxInput(NS(id, "gradient"), "Show gradient",
                                  value = FALSE),
                    uiOutput(NS(id, "dyn_frontvalue")),
                    numericInput(
                      NS(id, "frontradius"),
                      "Set front radius:",
                      value = 0.08,
                      min = 0.01,
                      max = 1,
                      step = 0.01
                    )
                  )
                ),
                
              )
            )
          )
        ),
        bslib::card(
          bslib::card_title("Peak Bed Stress"),
          bslib::layout_column_wrap(
            width = 1 / 2,
            bslib::card(
              bslib::card_title("Vector Spacing"),
              bslib::layout_column_wrap(
                width = 1 / 2,
                numericInput(
                  NS(id, "X"),
                  "X",
                  value = 5,
                  min = 1,
                  max = 50,
                  step = 1,
                  width  = '50%'
                ),
                numericInput(
                  NS(id, "Y"),
                  "Y",
                  value = 3,
                  min = 1,
                  max = 50,
                  step = 1,
                  width  = '50%'
                )
              )
            ),
            bslib::card(
              bslib::card_title("Vector appearance"),
              numericInput(
                NS(id, "minvec"),
                "Min. vector magnitude (N/m2):",
                value = 1.0,
                min = 0.0,
                max = 30.0,
                step = 0.01
              ),
              checkboxInput(NS(id, "arrow"), "Show arrow",
                            value = TRUE)
            )
          )
        )
      )
      
    )
  )
}

input_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
# Within-Panel Reactivity -------------------------------------------------

    # Grays out coastyear UI if coast == FALSE
    observeEvent(input$coast, {
      shinyjs::toggleState(id = "coastyear", 
                           condition = input$coast)
    })
    
    # gray out front radius
    observeEvent(input$front, {
    
      shinyjs::toggleState(id = "frontradius", 
                           condition = input$front)
    })
    
    # Have to grey out frontvalue differently because of dynamic rendering
    output$dyn_frontvalue <- renderUI({
      
      # initial UI to render
      init = shiny::tagList(dyn_input = numericInput(
        ns("frontvalue"),
        "Set front value:",
        value = 2.1,
        min = req(input$boundaryrange[1]),
        max = req(input$boundaryrange[2]),
        step = 0.1
      ))
      
      # if checkbox is clicked, just render it normally
      # if it's unchecked, add a shinyjs disabled tag
      if (input$front) {
        
        return(init$dyn_input)
        
      } else {
        
        disabled = shiny::tagAppendAttributes(init$dyn_input, class = "shinyjs-disabled")
        
        return(disabled)
          
      }
    })
    
    
    # works great when navset cardtab id is namespaced in UI above
    observe({
      if(input$datatype %in% c("Tidal Amplitude", "Tidal Current")) {
        bslib::nav_hide("tabs", target = "Custom")
      } else {
        bslib::nav_show("tabs", target = "Custom")
      }
    })
    
    # WIP Set custom card depending on data product
    # works for the id of the UI widget, but not the div
    observe({
      if(input$datatype == "Stratification") {
        shinyjs::show(id = "boundaryrange", anim = TRUE)
      } else {
        shinyjs::hide(id = "boundaryrange", anim = TRUE)
      }
      
    })    
    

# Passing Inputs out to Main Server Env -----------------------------------
    
    # init reactive Values
    input_vals = reactiveValues()
    
    # writing
    observe({
      input_vals$datatype = input$datatype
      input_vals$yearBP = input$yearBP
      input_vals$coast = input$coast
      input_vals$coastyear = input$coastyear
      input_vals$boundary_range = input$boundaryrange
      input_vals$contrast = input$contrast
      input_vals$front = input$front
      input_vals$front_radius = input$frontradius
      input_vals$front_value = input$frontvalue
      input_vals$gradient = input$gradient
      input_vals$X = input$X
      input_vals$Y = input$Y
      input_vals$minvec = input$minvec
      input_vals$arrow = input$arrow
    })
    
    return(input_vals)

  })
}