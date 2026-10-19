data_select_ui <- function(id) {
  labels = unique(sapply(statics, `[[`, "label"))
  tagList(
    selectizeInput(
      NS(id, "label"),
      label = "Region",
      choices = labels,
      options = list(dropdownParent = "body")
    ),
    radioButtons(
      NS(id, "model"),
      label = "Model",
      choices = model_choices(labels[1]),
      inline = TRUE
    ),
    selectizeInput(
      NS(id, "datatype"),
      label = "Data type",
      choices = datatype_choices(names(statics)[1]),
      selected = "Tidal Amplitude",
      options = list(dropdownParent = "body")
    )
  )
}

# data types a region has layers for, in menu order
datatype_choices = function(region) {
  all_types = c("Tidal Amplitude", "Spring Tidal Range", "Stratification",
                "Peak Bed Stress", "Peak Bed Stress (90th pct)", "Tidal Current",
                "Water Depth", "Relative Sea Level", "Ice Thickness")
  prefixes = sapply(map_layers[all_types], `[[`, "prefix")
  all_types[prefixes %in% names(statics[[region]]$years)]
}

# model runs available for a shelf, in folder order
model_choices = function(label) {
  unname(sapply(Filter(function(s) s$label == label, statics), `[[`, "model"))
}

data_select_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    ns <- session$ns

    # Passing Inputs out to Main Server Env -----------------------------------

    # init reactive Values
    input_vals = reactiveValues()

    # `region` is the data/app folder for the chosen shelf and model run
    observe({
      req(input$label, input$model)
      region = names(Filter(function(s) s$label == input$label && s$model == input$model, statics))
      # the model buttons lag a shelf change by a moment
      req(length(region) == 1)
      input_vals$region = region
      input_vals$datatype = input$datatype
    })

    # offer only the runs the shelf has, keeping the current one if it can
    observeEvent(input$label, {
      choices = model_choices(input$label)
      updateRadioButtons(session, "model", choices = choices, inline = TRUE,
                         selected = if (isTRUE(input$model %in% choices)) input$model else choices[1])
    }, ignoreInit = TRUE)

    # offer only what the region has, keeping the current data type if it can
    observeEvent(input_vals$region, {
      choices = datatype_choices(input_vals$region)
      updateSelectizeInput(session, "datatype", choices = choices,
                           selected = if (input$datatype %in% choices) input$datatype else choices[1])
    }, ignoreInit = TRUE)

    return(input_vals)

  })
}
