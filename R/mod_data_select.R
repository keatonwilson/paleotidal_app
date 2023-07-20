data_select_ui <- function(id) {
  tagList(
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
    )
  )
}

data_select_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    
    # Passing Inputs out to Main Server Env -----------------------------------
    
    # init reactive Values
    input_vals = reactiveValues()
    
    # writing
    observe({
      input_vals$datatype = input$datatype
    })
    
    return(input_vals)
    
  })
}