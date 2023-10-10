animations_ui <- function(id) {
  ns <- NS(id)

# Card Definitions --------------------------------------------------------
  
  uiOutput(ns("anim"))
  # amp_anim_card <- bslib::card(
  #   full_screen = TRUE,
  #   bslib::card_header("Tidal Amplitude"), 
  #   bslib::card_image("./www/amps.gif", 
  #                     fill = FALSE
  #                     )
  # )  
  # strat_anim_card <- bslib::card(
  #   full_screen = TRUE,
  #   bslib::card_header("Stratification"), 
  #   bslib::card_image(file="./www/strat.gif",
  #                     fill = FALSE
  #                     )
  # )  
  # bss_anim_card <- bslib::card(
  #   full_screen = TRUE,
  #   bslib::card_header("BSS"), 
  #   bslib::card_image(file="./www/bss.gif",
  #                     fill = FALSE
  #   )
  # )  
  # curr_anim_card <- bslib::card(
  #   full_screen = TRUE,
  #   bslib::card_header("Tidal Current"), 
  #   bslib::card_image(file="./www/vel.gif",
  #                     fill = FALSE
  #   )
  # )  
  # 
  # tagList(
  #   bslib::layout_column_wrap(
  #     width = 1/2, 
  #     height = 300,
  #     fixed_width = TRUE,
  #     amp_anim_card, 
  #     strat_anim_card, 
  #     bss_anim_card, 
  #     curr_anim_card
  #   )
  # )
}

animations_server <- function(id,
                              data) {
  moduleServer(
    id,
    function(input, output, session) {
      
      observe({
        # Depending on input, switch link to gif
        anim_path = switch(data$datatype, 
                           `Tidal Amplitude` = "./www/amps.gif", 
                           `Stratification` = "./www/strat.gif",
                           `Peak Bed Stress` = "./www/bss.gif",
                           `Tidal Current` = "./www/vel.gif")
      
        
        # Single card for animation
        output$anim <- renderUI({
          bslib::card(
            full_screen = TRUE,
            # bslib::card_header("Tidal Amplitude"), 
            bslib::card_image(anim_path, 
                              fill = FALSE
            )
          )
        })
        
      })

    }
  )
}