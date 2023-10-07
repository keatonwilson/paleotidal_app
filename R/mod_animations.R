animations_ui <- function(id) {
  ns <- NS(id)

# Card Definitions --------------------------------------------------------

  amp_anim_card <- card(
    card_header("Tidal Amplitude")
  )  
  strat_anim_card <- card(
    card_header("Tidal Amplitude")
  )  
  bss_anim_card <- card(
    card_header("Tidal Amplitude")
  )  
  curr_anim_card <- card(
    card_header("Tidal Amplitude")
  )  
  
  tagList(
    bslib::layout_column_wrap(
      width = "200px", height = 300,
      fixed_width = TRUE,
      amp_anim_card, 
      strat_anim_card, 
      bss_anim_card, 
      curr_anim_card
    ) |>
      bslib::anim_width("100%", "67%")
  )
}

animations_server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
      
    }
  )
}