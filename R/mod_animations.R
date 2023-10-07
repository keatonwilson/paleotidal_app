animations_ui <- function(id) {
  ns <- NS(id)

# Card Definitions --------------------------------------------------------

  amp_anim_card <- bslib::card(
    bslib::card_header("Tidal Amplitude")
  )  
  strat_anim_card <- bslib::card(
    bslib::card_header("Tidal Amplitude")
  )  
  bss_anim_card <- bslib::card(
    bslib::card_header("Tidal Amplitude")
  )  
  curr_anim_card <- bslib::card(
    bslib::card_header("Tidal Amplitude")
  )  
  
  tagList(
    bslib::layout_column_wrap(
      width = 1/2, 
      height = 300,
      fixed_width = TRUE,
      amp_anim_card, 
      strat_anim_card, 
      bss_anim_card, 
      curr_anim_card
    )
  )
}

animations_server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
      
    }
  )
}