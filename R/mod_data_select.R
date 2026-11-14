data_select_ui <- function(id) {
  labels = unique(sapply(statics, `[[`, "label"))
  start_model = default_model(model_choices(labels[1]))
  # the region folder for the starting shelf and model run
  start_region = names(Filter(function(s) s$label == labels[1] && s$model == start_model,
                              statics))[1]
  tagList(
    shinyWidgets::radioGroupButtons(
      NS(id, "label"),
      label = "Region",
      choices = labels,
      selected = labels[1],
      size = "sm",
      status = "outline-primary"
    ),
    shinyWidgets::radioGroupButtons(
      NS(id, "model"),
      label = "Model",
      choices = model_choices(labels[1]),
      selected = start_model,
      size = "sm",
      status = "outline-primary"
    ),
    shinyWidgets::radioGroupButtons(
      NS(id, "datatype"),
      label = "Data type",
      choices = datatype_choices(start_region),
      selected = "M\u2082 Elevation Amplitude",
      size = "sm",
      status = "outline-primary"
    )
  )
}

# data types a region has layers for, in menu order
datatype_choices = function(region) {
  all_types = c("M\u2082 Elevation Amplitude", "Spring Tidal Range", "Seasonal Stratification",
                "Peak Bed Stress", "Peak Bed Stress (90th pct)", "Tidal Current",
                "Water Depth", "Relative Sea Level", "Ice Thickness")
  prefixes = sapply(map_layers[all_types], `[[`, "prefix")
  all_types[prefixes %in% names(statics[[region]]$years)]
}

# the model run offered first: PALTIDE2 when the shelf has it
default_model = function(choices) {
  if ("PALTIDE2" %in% choices) "PALTIDE2" else choices[1]
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
      shinyWidgets::updateRadioGroupButtons(
        session, "model", choices = choices,
        selected = if (isTRUE(input$model %in% choices)) input$model else default_model(choices),
        size = "sm", status = "outline-primary"
      )
    }, ignoreInit = TRUE)

    # offer only what the region has, keeping the current data type if it can
    observeEvent(input_vals$region, {
      choices = datatype_choices(input_vals$region)
      shinyWidgets::updateRadioGroupButtons(
        session, "datatype", choices = choices,
        selected = if (input$datatype %in% choices) input$datatype else choices[1],
        size = "sm", status = "outline-primary"
      )
    }, ignoreInit = TRUE)

    return(input_vals)

  })
}
