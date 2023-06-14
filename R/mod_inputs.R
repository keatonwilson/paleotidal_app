# First stab at card with inputs

input_ui <- function(id) {
  tagList(
    bslib::navset_card_tab(
      full_screen = TRUE,
      title = "Select inputs",
      bslib::nav_panel("Time",
                bslib::card_title("Years BP"),
                sliderInput(NS(id, "year"), "Select", 
                            min = 0, max = 21,
                            value = 0)),
      bslib::nav_panel("View",
                bslib::card_title("Stratification"))
    )
  )
}

input_server <- function(id) {
  moduleServer(id, function(input, output, session){
    reactive({
      input$year
    })

  })
}