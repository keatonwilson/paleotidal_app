
# Define server logic required to draw a histogram
function(input, output, session) {
  
 # years <- callModule(input_server, "inputs")
 # callModule(map_server, "map", years)
  
  map_server("map")
  
  # this is reactive
  test_input = input_server("inputs")
  
  # need to wrap in a reactive context (observe), and also call the object with 
  # the ()
  observe({
    print(test_input())
  })
  
  
  # server function for data summary panel
  #TODO remove static values here after we can feed inputs into it
  data_summary_server("data_summary", 
                      year = 20000, 
                      dataset = "Tidal Amplitude", 
                      legend = "Placeholder Legend Text")

}
