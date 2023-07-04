data_summary_ui <- function(id){
  ns <- NS(id)

    bslib::layout_columns(
      col_widths = c(4, 4, 4),
      bslib::value_box(
        "Year",
        showcase = bsicons::bs_icon("hourglass-split"),
        value = shiny::textOutput(ns("year_bp"))
      ),
      bslib::value_box(
        "Dataset",
        showcase = bsicons::bs_icon("database"),
        value = shiny::textOutput(ns("dataset"))
      ),
      bslib::value_box(
        "Legend",
        showcase = bsicons::bs_icon("compass-fill"),
        value = shiny::htmlOutput(ns("legend"))
      )
    )
  
}

data_summary_server <- function(id, 
                                inputs) {
  moduleServer(
    id,
    function(input, output, session) {
      
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
        
        # Dataset -----------------------------------------------------------------
        
        
        output$dataset = shiny::renderText({
          inputs$datatype
        }) 
        
        
        # Legend ------------------------------------------------------------------
        
        output$legend = shiny::renderUI({
          # might need more complex html here - hence the different output
          shiny::HTML("Legend Placeholder Text")
        })      
      })


      
      
    }
  )
}