#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(bslib)

# Define UI for application that draws a histogram
ui <- fluidPage(
  shinyjs::useShinyjs(),
  
  # Application title
  titlePanel("Old Faithful Geyser Data"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      checkboxInput("activateslider", "Activate slider", FALSE),
      div(id = "sliderbins",
          sliderInput("bins",
                      "Number of bins:",
                      min = 1,
                      max = 50,
                      value = 30)
      ),
      checkboxInput("modifyX", "Modify x value", FALSE),
      shinyjs::hidden(
        div(id = "xvalue", 
            bslib::card(bslib::card_title("Test card"),
                        numericInput("X", "X value:",
                                     value = 5,
                                     min = 1, max = 50,
                                     step = 1,
                                     width  = '40%'))
        ))
      
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("distPlot")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  observe({
    shinyjs::toggleState("sliderbins", input$activateslider)
  })
  
  observe({
    if(input$modifyX == TRUE) {
      shinyjs::show(id = "xvalue", anim = TRUE)
    } else {
      shinyjs::hide(id = "xvalue", anim = TRUE)
    }
  })
  
  output$distPlot <- renderPlot({
    # generate bins based on input$bins from ui.R
    x    <- faithful[, 2]
    bins <- seq(min(x), max(x), length.out = input$bins + 1)
    
    # draw the histogram with the specified number of bins
    hist(x, breaks = bins, col = 'darkgray', border = 'white',
         xlab = 'Waiting time to next eruption (in mins)',
         main = 'Histogram of waiting times')
  })
}

# Run the application 
shinyApp(ui = ui, server = server)