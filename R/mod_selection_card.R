# One collapsible card holding every data selection input. When collapsed, the
# header shows a text summary of the current selections.

selection_card_ui <- function(id, data_id, inputs_id) {
  ns <- NS(id)
  
  bslib::accordion(
    id = ns("accordion"),
    class = "selection-card",
    open = "selection",
    multiple = FALSE,
    bslib::accordion_panel(
      value = "selection",
      title = div(
        class = "selection-title",
        span(class = "selection-icon",
             bsicons::bs_icon("sliders", size = "1.1em")),
        span(class = "selection-heading", "Data selection"),
        # only visible while the panel is collapsed (see style.css)
        span(class = "selection-summary",
             shiny::textOutput(ns("summary"), inline = TRUE))
      ),
      bslib::layout_columns(
        col_widths = c(4, 8),
        div(data_select_ui(data_id)),
        div(input_ui(inputs_id))
      )
    )
  )
}

selection_card_server <- function(id, data, inputs) {
  moduleServer(id, function(input, output, session) {
    
    output$summary = shiny::renderText({
      req(data$region, data$datatype, inputs$yearBP)
      year = prettyNum(as.numeric(inputs$yearBP) * 1000,
                       big.mark = ",", scientific = FALSE)
      coast = if (isTRUE(inputs$coast_current)) "on" else "off"
      paste(
        statics[[data$region]]$label,
        statics[[data$region]]$model,
        data$datatype,
        paste(year, "BP"),
        paste("Modern coastline:", coast),
        sep = "  \u00b7  "
      )
    })
    
  })
}
