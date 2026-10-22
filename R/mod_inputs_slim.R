# Card with the year display (text + hourglass icon), time slider and coastline toggle

input_ui <- function(id) {
  tagList(
    shinyjs::useShinyjs(),
    shinyWidgets::chooseSliderSkin("Flat", color = "#0b6e7f"),
    # Year display on the left, coastline toggle on the right
    div(
      class = "d-flex align-items-center justify-content-between flex-wrap gap-2",
      # icon, label and value on a single line
      div(
        class = "year-display d-flex align-items-baseline gap-2",
        span(class = "year-display-icon",
             bsicons::bs_icon("hourglass-split", size = "1.1em")),
        span(class = "year-display-label", "Year"),
        span(class = "year-display-value",
             shiny::textOutput(NS(id, "year_bp"), inline = TRUE))
      ),
      bslib::input_switch(
        NS(id, "coast_current"),
        "Show modern coastline",
        value = TRUE
      )
    ),
    shinyWidgets::sliderTextInput(
      NS(id, "yearBP"),
      # the year readout above labels the slider
      label = NULL,
      choices = 21:0,
      selected = 21,
      grid = TRUE,
      width = "100%",
      # play button steps through to the present
      animate = animationOptions(interval = 600, loop = FALSE)
    )
  )
}

input_server <- function(id, inputs) {
  moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    
    # Year text above the slider
    output$year_bp = shiny::renderText({
      year = as.numeric(input$yearBP) * 1000
      paste(prettyNum(year, big.mark = ",", scientific = FALSE), "BP")
    })

    # Years ------------------------------------------------------------------

    # the slider offers the years the region has for the chosen data type
    observe({
      req(inputs$region, inputs$datatype)
      years = statics[[inputs$region]]$years[[map_layers[[inputs$datatype]]$prefix]]
      req(years)
      current = isolate(input$yearBP)
      shinyWidgets::updateSliderTextInput(
        session, "yearBP",
        choices = rev(years),
        selected = if (isTRUE(current %in% years)) current else max(years)
      )
    })

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
