# First stab at card with inputs

input_ui <- function(id) {
  tagList(
    
    #shinyJS Set --------------------------------------------------
    shinyjs::useShinyjs(),
    
    # Datatype Dropdown -------------------------------------------------------
    
    # selectInput(
    #   NS(id, "datatype"),
    #   label = NULL,
    #   choices = c(
    #     "Tidal Amplitude",
    #     "Stratification",
    #     "Peak Bed Stress",
    #     "Tidal Current"
    #   ),
    #   selected = "Tidal Amplitude"
    # ),
    
    # General and Custom Tab Panels -------------------------------------------
    
    bslib::navset_card_tab(
      id = NS(id, "tabs"),
      full_screen = FALSE,
      # title = "User inputs",
      ## General Panel ----------------------------------------------------------
      bslib::nav_panel(
        "",
        # bslib::card_title("Time"),
        shinyWidgets::sliderTextInput(
          NS(id, "yearBP"),
          "Years BP(*1000):",
          choices = 21:0,
          selected = 21,
          grid = TRUE,
          width = "100%",
          # animate = animationOptions(interval = 1000,
          #                            loop = FALSE)
        ),
        # bslib::layout_column_wrap(
        #   width = 1 / 2,
          checkboxInput(
            NS(id, "coast_current"),
            "Show modern coastline",
            value = TRUE,
            width = '100%'
          # ),
          # selectInput(
          #   NS(id, "coastyear"),
          #   "Select coastline year:",
          #   choices = 0:21,
          #   selected = 0,
          #   width = '100%'
          # )
        ),
        checkboxInput(
          NS(id, "coast_paleo"),
          "Show paleo-coastline",
          value = FALSE,
          width = '100%')
      ),
      ## Custom Panel ----------------------------------------------------------
      bslib::nav_panel(
        "Custom",
        # shiny::div(
        #   id = NS(id, "strat_inputs"),
        #   bslib::layout_column_wrap(
        #     width = 1 / 2,
        #     bslib::card(
        #       bslib::card_title("Boundary values"),
        #       shinyWidgets::numericRangeInput(
        #         NS(id, "boundaryrange"),
        #         "Set min and max:",
        #         value = c(1.9, 2.9),
        #         min = 0,
        #         max = 12,
        #         step = 0.1
        #       ),
        #       checkboxInput(NS(id, "contrast"), "Show contrast",
        #                     value = FALSE)
        #     ), 
        #     # shiny::div(
        #     #   id = NS(id, "front_inputs"),
        #     bslib::card(
        #       bslib::card_title("Front values"),
        #       checkboxInput(NS(id, "front"), "Show front",
        #                     value = TRUE),
        #       # gradient not currently in development
        #       # checkboxInput(NS(id, "gradient"), "Show gradient",
        #       #               value = FALSE),
        #       uiOutput(NS(id, "dyn_frontvalue")),
        #       numericInput(
        #         NS(id, "frontradius"),
        #         "Set front radius:",
        #         value = 0.08,
        #         min = 0.01,
        #         max = 1,
        #         step = 0.01
        #       )
        #     )
        #   )
        # ),
        # shiny::div(
        #   id = NS(id, "vector_inputs"),
          # bslib::layout_column_wrap(
          #   width = 1 / 2,
          #   bslib::card(
          #     bslib::card_title("Vector spacing"),
          #     bslib::layout_column_wrap(
          #       width = 1 / 2,
          #       numericInput(
          #         NS(id, "X"),
          #         "X",
          #         value = 5,
          #         min = 1,
          #         max = 50,
          #         step = 1,
          #         width  = '100%'
          #       ),
          #       numericInput(
          #         NS(id, "Y"),
          #         "Y",
          #         value = 3,
          #         min = 1,
          #         max = 50,
          #         step = 1,
          #         width  = '100%'
          #       )
          #     )
          #   ),
            # bslib::card(
            #   bslib::card_title("Vector appearance"),
              # checkboxInput(NS(id, "arrow"), "Show arrow",
              #               value = TRUE),
              shinyWidgets::sliderTextInput(
                NS(id, "vec_space"),
                "Vector spacing:",
                choices = c("sparse", "medium", "dense"),
                selected = "medium"),
              numericInput(
                NS(id, "minvec"),
                "Minimum magnitude (N/m2):",
                value = 1.0,
                min = 0.0,
                max = 15,
                step = 0.01
              )
            # )
          # )
        # )
      )
    )
  )
}

input_server <- function(id, inputs) {
  moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
# Within-Panel Reactivity -------------------------------------------------

    # Grays out coastyear UI if coast == FALSE
    # observeEvent(input$coast, {
    #   shinyjs::toggleState(id = "coastyear", 
    #                        condition = input$coast)
    # })
    
    # gray out front radius if "Show front" is unchecked
    # observeEvent(input$front, {
    # 
    #   shinyjs::toggleState(id = "frontradius", 
    #                        condition = input$front)
    # })
    
    # Dynamically update front value min/max depending on boundary range
    # Disable if "Show front" is unchecked
    # output$dyn_frontvalue <- renderUI({
    # 
    #   # initial UI to render
    #   init = shiny::tagList(dyn_input = numericInput(
    #     ns("frontvalue"),
    #     "Set front value:",
    #     value = 2.1,
    #     min = req(input$boundaryrange[1]),
    #     max = req(input$boundaryrange[2]),
    #     step = 0.1
    #   ))
    #   
    #   # if checkbox is clicked, just render it normally
    #   # if it's unchecked, add a shinyjs disabled tag
    #   if (input$front) {
    #     
    #     return(init$dyn_input)
    #     
    #   } else {
    #     
    #     disabled = shiny::tagAppendAttributes(init$dyn_input, class = "shinyjs-disabled")
    #     
    #     return(disabled)
    #       
    #   }
    # })
    
    
    # Hide "Custom" tab if either Tidal product is selected
    # works great when navset cardtab id is namespaced in UI above
    observe({
      if(inputs$datatype %in% c("Tidal Amplitude", "Tidal Current", "Stratification", "Peak Bed Stress")) {
        bslib::nav_hide("tabs", target = "Custom")
      } else {
        bslib::nav_show("tabs", target = "Custom")
      }
    })
    
    # Now works when div is namespaced appropriately
    # observe({
    # 
    #   if(inputs$datatype == "Peak Bed Stress") {
    #     shinyjs::show(id = "vector_inputs", anim = TRUE)
    #     # shinyjs::show(id = "front_inputs", anim = TRUE)
    #     # shinyjs::hide(id = "vector_inputs", anim = TRUE)
    #   } else {
    #     shinyjs::hide(id = "vector_inputs", anim = TRUE)
    #     # shinyjs::hide(id = "front_inputs", anim = TRUE)
    #     # shinyjs::show(id = "vector_inputs", anim = TRUE)
    #   }
    #   
    # })    
    

# Passing Inputs out to Main Server Env -----------------------------------
    
    # init reactive Values
    input_vals = reactiveValues()
    
    # writing
    observe({
      # input_vals$datatype = inputs$datatype
      input_vals$yearBP = input$yearBP
      input_vals$coast_current = input$coast_current
      input_vals$coast_paleo = input$coast_paleo
      # input_vals$coastyear = input$coastyear
      # input_vals$boundary_range = input$boundaryrange
      # input_vals$contrast = input$contrast
      # input_vals$front = input$front
      # input_vals$front_radius = input$frontradius
      # input_vals$front_value = input$frontvalue
      # input_vals$gradient = input$gradient
      # input_vals$arrow = input$arrow
      input_vals$vec_space = input$vec_space
      input_vals$minvec = input$minvec
      })
    
    return(input_vals)

  })
}
