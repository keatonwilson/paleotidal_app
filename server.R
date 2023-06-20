
# Define server logic required to draw a histogram
function(input, output, session) {
  
  # server function for data summary panel
  #TODO remove static values here after we can feed inputs into it
  data_summary_server("data_summary", 
                      year = 20000, 
                      dataset = "Tidal Amplitude", 
                      legend = "Placeholder Legend Text")

}
