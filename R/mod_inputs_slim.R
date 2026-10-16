# Card with the year display (text + hourglass icon), time slider and coastline toggle

input_ui <- function(id) {
  bslib::card(
    class = "inputs-card",
    shinyjs::useShinyjs(),
    bslib::card_body(
      # Year display on the left, coastline toggle on the right
      div(
        class = "d-flex align-items-center justify-content-between",
        div(
          class = "year-display d-flex align-items-center gap-2",
          div(class = "year-display-icon",
              bsicons::bs_icon("hourglass-split", size = "1.25em")),
          div(
            div(class = "year-display-label", "Year"),
            div(class = "year-display-value",
                shiny::textOutput(NS(id, "year_bp"), inline = TRUE))
          )
        ),
        checkboxInput(
          NS(id, "coast_current"),
          "Show modern coastline",
          value = TRUE,
          width = "auto"
        )
      ),
      shinyWidgets::sliderTextInput(
        NS(id, "yearBP"),
        "Years BP (*1000):",
        choices = 21:0,
        selected = 21,
        grid = TRUE,
        width = "100%",
        # play button steps through to the present
        animate = animationOptions(interval = 600, loop = FALSE)
      )
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
