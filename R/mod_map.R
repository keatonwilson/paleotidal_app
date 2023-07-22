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
      #TODO Peak Bed Stress will need to mapped to a different raster
      raster_to_map = switch(data$datatype, 
                             `Tidal Amplitude` = rasters$amp_raster, 
                             `Stratification` = rasters$strat_raster,
                             `Peak Bed Stress` = rasters$amp_raster,
                             `Tidal Current` = rasters$vel_raster
      )
      
      to_map = names(raster_to_map)[stringr::str_detect(names(raster_to_map), 
                                                        glue::glue("^X{inputs$yearBP}_"))]
      ice_to_map = names(ice_raster)[stringr::str_detect(names(ice_raster), 
                                                         glue::glue("^X{inputs$yearBP}_"))]
      
      # inputs$coast returns T or F for showing shapefile
      
      # filter by time_step
      raster = raster_to_map[[to_map]]
      ice_raster = ice_raster[[ice_to_map]]
      
      if(data$datatype %in% c("Tidal Amplitude", "Tidal Current")) {
        mp <- map_proxy() |> 
          leaflet::addRasterImage(raster, 
                                  colors = "viridis") |> 
          leaflet::addRasterImage(ice_raster, colors = "aliceblue") |> 
          leaflet::addPolygons(data = shape_1, 
                               weight = 0.5, 
                               opacity = 1,
                               color = "black",
                               fillOpacity = 0)
        mp
        if(inputs$coast == FALSE) {
          mp2<- mp |> 
            clearShapes()
          mp2
        }
      }
      else if(data$datatype == "Stratification") {
        color_vec <- rev(RColorBrewer::brewer.pal(3, "GnBu"))
        
        mp <- map_proxy() |> 
          leaflet::addRasterImage(raster, 
                                  colors = color_vec) |> 
          leaflet::addRasterImage(ice_raster, colors = "aliceblue") |> 
          leaflet::addPolygons(data = shape_1, 
                               weight = 0.5, 
                               opacity = 1,
                               color = "black",
                               fillOpacity = 0)
        mp
        
        if(inputs$coast == FALSE) {
         mp2<- mp |> 
            clearShapes()
         mp2
        }
      }

      
      })
      
    })
    
  }
