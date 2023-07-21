map_ui <- function(id) {
  
  ns <- NS(id)
  leaflet::leafletOutput(ns("map"))
  
}

map_server <- function(id, 
                       inputs,
                       data, 
                       rasters, 
                       ice_raster,
                       map_proxy) {
  moduleServer(id, function(input, output, session) {
    
    observe({
      # data mapping
      #TODO This will need to eventually be mapped to different rasters
      # for now, just tidal amplitude
      raster_to_map = switch(data$datatype, 
                             `Tidal Amplitude` = rasters$amp_raster, 
                             `Stratification` = rasters$amp_raster,
                             `Peak Bed Stress` = rasters$amp_raster,
                             `Tidal Current` = rasters$vel_raster
      )
      
      to_map = names(raster_to_map)[stringr::str_detect(names(raster_to_map), 
                                                        glue::glue("^X{inputs$yearBP}_"))]
      ice_to_map = names(ice_raster)[stringr::str_detect(names(ice_raster), 
                                                         glue::glue("^X{inputs$yearBP}_"))]
      
      # filter by time_step
      raster = raster_to_map[[to_map]]
      ice_raster = ice_raster[[ice_to_map]]
      
      map_proxy() |> 
        leaflet::addRasterImage(raster, 
                                colors = "viridis") |> 
        leaflet::addRasterImage(ice_raster)
      
      })
      
    })
    
  }
