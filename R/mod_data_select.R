data_select_ui <- function(id) {
  tagList(
    shiny::h4("Data Selection"),
    bslib::layout_columns(
      col_widths = c(6, 6),
      selectizeInput(
        NS(id, "region"),
        label = NULL,
        choices = setNames(names(statics), sapply(statics, `[[`, "label")),
        options = list(dropdownParent = "body")
      ),
      selectizeInput(
        NS(id, "datatype"),
        label = NULL,
        choices = datatype_choices(names(statics)[1]),
        selected = "Tidal Amplitude", 
        options = list(dropdownParent = "body")
      )
    )
  )
}

# data types a region has layers for, in menu order
datatype_choices = function(region) {
  all_types = c("Tidal Amplitude", "Stratification", "Peak Bed Stress",
                "Tidal Current", "Water Depth")
  prefixes = sapply(map_layers[all_types], `[[`, "prefix")
  all_types[prefixes %in% names(statics[[region]]$years)]
}

data_select_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    
    # Passing Inputs out to Main Server Env -----------------------------------
    
    # init reactive Values
    input_vals = reactiveValues()
    
    # writing
    observe({
      input_vals$region = input$region
      input_vals$datatype = input$datatype
    })

    # offer only what the region has, keeping the current data type if it can
    observeEvent(input$region, {
      choices = datatype_choices(input$region)
      updateSelectizeInput(session, "datatype", choices = choices,
                           selected = intersect(input$datatype, choices))
    }, ignoreInit = TRUE)
    
    return(input_vals)
    
  })
}