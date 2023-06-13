# First stab at card with inputs

input_ui <- function(id) {
  tagList(
    navset_card_tab(
      full_screen = TRUE,
      title = "Select inputs",
      nav_panel("Time",
                card_title("Years BP"),
                sliderInput(NS(id, "year"), "Select", 
                            min = 0, max = 21,
                            value = 0)),
      nav_panel("View",
                card_title("Stratification"))
    )
  )
}

input_server <- function(id) {
  moduleServer(id, function(input, output, session){
    return(input)
  })
}