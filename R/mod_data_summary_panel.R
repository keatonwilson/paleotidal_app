data_summary_ui <- function(id){
  ns <- NS(id)

      bslib::value_box(
        "Year",
        showcase = bsicons::bs_icon("hourglass-split"),
        value = shiny::textOutput(ns("year_bp"))
      )

}

data_summary_server <- function(id, 
                                inputs) {
  moduleServer(id, function(input, output, session) {
      
      observe({
        
        # Year --------------------------------------------------------------------
        year = as.numeric(inputs$yearBP * 1000)
        year_to_print = prettyNum(year,
                                  big.mark=",",
                                  scientific=FALSE)
        # rendering
        output$year_bp = shiny::renderText({
          glue::glue("{year_to_print} BP")
        })
        
      })

    }
  )
}