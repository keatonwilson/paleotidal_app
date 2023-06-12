#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define server logic required to draw a histogram
function(input, output, session) {

    output$distPlot <- renderPlot({

        # generate bins based on input$bins from ui.R
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = 3)

        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'darkgray', border = 'white',
             xlab = 'Waiting time to next eruption (in mins)',
             main = 'Histogram of waiting times')

    })
    
    ice_matrix_long <- reactive({
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
                                     "ice" = 'blue')) +
        coord_fixed() +
        theme_bw() +
        theme(panel.grid = element_blank())
    })

}
