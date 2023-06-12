# these module functions could have better documentation via roxygen2
about_tab_ui <- function(id) {
  ns <- NS(id)

# Main Content for Tab ----------------------------------------------------
  shiny::tagList(

  ## Column 1 --------------------------------------------------------------
    bslib::layout_column_wrap(
      width = 1/2, 
      height = 300,
      
      # calls other module from mod_card.R
      card_ui(ns("how_to_use_card"), 
              "How to Use", 
              lapply(
                lorem::ipsum(paragraphs = 3, sentences = c(5, 5, 5)),
                tags$p
              )),

## Column 2 Nested ---------------------------------------------------------

      bslib::layout_column_wrap(
        width = 1, 
        heights_equal = "row",
        
        # re-uses modules like above
        card_ui(ns("ack"), 
                "Acknowledgements",
                lapply(
                  lorem::ipsum(paragraphs = 3, sentences = c(5, 5, 5)),
                  tags$p
                )), 
        card_ui(ns("fun_image"), 
                "", 
                lapply(
                  lorem::ipsum(paragraphs = 3, sentences = c(5, 5, 5)),
                  tags$p
                ))
      )
    )
  )
}


about_tab_server <- function(id) {
  moduleServer(id, function(input, output, session) {
  # We don't need anything in the server for this module
  })
}



