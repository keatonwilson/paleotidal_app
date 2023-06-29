#TODO Improve documentation

card_ui <- function(id, 
                  header, 
                  content) {
  
    bslib::card(
      bslib::card_header(header),
      content
  )

  
}

card_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # We don't need anything in the server for this module
  })
}