map_ui <- function(id) {
  
  ns <- NS(id)
  leaflet::leafletOutput(ns("map"))
  
}

map_server <- function(id, 
                       inputs,
                       rasters) {
  moduleServer(id, function(input, output, session) {
    
    
    observe({
      # data mapping
      #TODO This will need to eventually be mapped to different rasters
      # for now, just tidal amplitude
      raster_to_map = switch(inputs$datatype, 
                             `Tidal Amplitude` = rasters$amp_raster, 
                             `Stratification` = rasters$amp_raster,
                             `Peak Bed Stress` = rasters$amp_raster,
                             `Tidal Current` = rasters$amp_raster
      )
      
      to_map = names(raster_to_map)[stringr::str_detect(names(raster_to_map), 
                                                        glue::glue("^X{inputs$yearBP}_"))]
      
      # filter by time_step
      raster = raster_to_map[[to_map]]
      
      
      output$map = leaflet::renderLeaflet({
        leaflet::leaflet() |> 
          leaflet::addRasterImage(raster, 
                                  colors = "viridis")
      })
      
    })
    
    

  })
}