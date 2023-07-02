can_browse <- function() interactive() && require("shiny")

# Selecting a tab
if (can_browse()) {
  shinyApp(
    page_fluid(
      radioButtons("item", "Choose", c("A", "B")),
      navset_hidden(
        id = "container",
        nav_panel_hidden("A", "a"),
        nav_panel_hidden("B", "b")
      )
    ),
    function(input, output) {
      observe(nav_select("container", input$item))
    }
  )
}

# Inserting and removing
if (can_browse()) {
  ui <- page_fluid(
    actionButton("add", "Add 'Dynamic' tab"),
    actionButton("remove", "Remove 'Foo' tab"),
    selectInput("hide", "Hide Bar tab",
                choices = c("hide", "don't hide", "I don't know")),
    navset_tab(
      id = "tabs",
      nav_panel("Hello", "hello"),
      nav_panel("Foo", "foo"),
      nav_panel("Bar", "bar")
    )
  )
  server <- function(input, output) {
    observeEvent(input$add, {
      print(input$add)
      nav_insert(
        "tabs", target = "Bar", select = TRUE,
        nav_panel("Dynamic", "Dynamically added content")
      )
    })
    observeEvent(input$remove, {
      print(input$remove)
      nav_remove("tabs", target = "Foo")
    })
    observe({
      print(input$hide)
      if(input$hide == "hide") {
      nav_hide("tabs", target = "Bar")
      } else{
        nav_show("tabs", target = "Bar")
      }
    })
  }
  shinyApp(ui, server)
}
