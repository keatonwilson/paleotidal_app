
# Define server logic required to draw a histogram
function(input, output, session) {

  # hard code amplitude for now because it's easy
  map_server("map", data = amp_raster)

  
  # this is reactive
  test_input = input_server("inputs")
  
  # need to wrap in a reactive context (observe), and also call the object with 
  # the ()
  observe({
    print(test_input[["gradient"]]())
  })
  
}
