map_ui <- function(id) {
  
  ns <- NS(id)
  leaflet::leafletOutput(ns("map"))
  
}

map_server <- function(id, 
                       datatype, 
                       data, 
                       time_step) {
  moduleServer(id, function(input, output, session) {
        # render a single datatype for now
    datatype = "amplitude"
    time_step = "0"
    
    to_map = names(data)[stringr::str_detect(names(data), glue::glue("^X{time_step}"))]
    
    # filter by time_step
    data_to_map = data[[to_map]]
    
    
    output$map = leaflet::renderLeaflet({
      leaflet::leaflet() |> 
        leaflet::addRasterImage(data_to_map)
    })
  })
}