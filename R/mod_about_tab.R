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
                imageOutput("logos")), 
        card_ui(ns("how_to_cite"), 
                "How to cite", 
                lapply(
                  lorem::ipsum(paragraphs = 1, sentences = c(5)),
                  tags$p
                ))
      )
    )
  )
}


about_tab_server <- function(id) {
  moduleServer(id, function(input, output, session) {
  # We don't need anything in the server for this module
    
    output$logos <- renderImage({
      list(
        src = file.path("www/CSS_Logo_2022_DarkGreen_RGB.jpg"), 
        contentType = "image/jpg", 
        height = 250, 
        width = 500
      )
    }, deleteFile = FALSE)
    
  })
}



