# First stab at lefthand side map display

library(tidyverse)

map_ui <- function(id) {
  shiny::tagList(
    bslib::card(full_screen = TRUE,
                bslib::card_header("Map"),
                plotOutput(NS(id, "map")))
    
  )
}

map_server <- function(id) {
  moduleServer(id, function(input, output, session) { # input_server
    
    ice_matrix_long <- reactive({
      # fn <- paste0("data/raw/ice/ice[", input_server$year, "].txt")
      # ice <- read_tsv(fn, skip = 5, col_names = FALSE)
      ice <- read_tsv("data/raw/ice/ice[21].txt", skip = 5, col_names = FALSE)
      
      foo <- data.frame(ice) %>%
        rowid_to_column("lat") %>%
        mutate(lat = factor(lat),
               lat2 = as.numeric(levels(fct_rev(lat)))) %>%
        relocate(lat, lat2) %>%
        pivot_longer(-1:-2, names_to = "long", names_prefix = "X") %>%
        mutate(long = as.numeric(long),
               value = case_when(value == 0 ~ "non-ice",
                                 value == 1 ~ "ice"))
    })
    
    output$map <- renderPlot({
      # Simple ggplot rendering of  matrix data
      ice_matrix_long() %>%
      ggplot(aes(x = long, y = lat2)) +
        geom_raster(aes(fill = value)) +
        scale_fill_manual(values = c("non-ice" = "gray",
                                     "ice" = 'darkcyan')) +
        coord_fixed() +
        theme_bw() +
        theme(panel.grid = element_blank())
    })
    
  })
}
