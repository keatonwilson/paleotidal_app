library(shiny)
library(bslib)

mod_display_ui <- function(id){
  ns <- NS(id)
  card(
  textInput(ns("title"),"Put text here","Starting Title"),
  textInput(ns("text"),"Put text here","Starting Text"),
  uiOutput(ns("main_out")))
  
}
mod_display_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # stopifnot(is.reactive(title))
    # stopifnot(is.reactive(text))
    
    output$main_out <- renderUI({
      selectInput("type", "Select type",
        choices = c(req(input$title), req(input$text)),
        selected = req(input$text)
      )
    })
  })
}

ui <- fluidPage(
  mod_display_ui("mybox")
)

server <- function(input, output, session) {
  
  mod_display_server("mybox")
}

shinyApp(ui, server)
