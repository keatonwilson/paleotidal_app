# Random example of a shiny module not implemented in ui.R or server, 
# but a starting place

randomUI <- function(id) {
  tagList(
    textOutput(NS(id, "val")),
    actionButton(NS(id, "go"), "Go!")
  )
}

randomServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    rand <- eventReactive(input$go, sample(100, 1))
    output$val <- renderText(rand())
  })
}