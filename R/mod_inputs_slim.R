# First stab at card with inputs

input_ui <- function(id) {
  tagList(
    
    #shinyJS Set --------------------------------------------------
    shinyjs::useShinyjs(),
    
    # General and Custom Tab Panels -------------------------------------------
    
    # bslib::navset_card_tab(
    #   id = NS(id, "tabs"),
    #   full_screen = FALSE,
      # title = "User inputs",
      ## General Panel ----------------------------------------------------------
      bslib::nav_panel(
        "",
        # bslib::card_title("Time"),
        shinyWidgets::sliderTextInput(
          NS(id, "yearBP"),
          "Years BP(*1000):",
          choices = 21:0,
          selected = 21,
          grid = TRUE,
          width = "100%",
        ),
        
        checkboxInput(
          NS(id, "coast_current"),
          "Show modern coastline",
          value = TRUE,
          width = '100%'
        ),
      )
    # )
  )
}

input_server <- function(id, inputs) {
  moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    

    # Passing Inputs out to Main Server Env -----------------------------------
    
    # init reactive Values
    input_vals = reactiveValues()
    
    # writing
    observe({
      input_vals$yearBP = input$yearBP
      input_vals$coast_current = input$coast_current
      })
    
    return(input_vals)

  })
}
