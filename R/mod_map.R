map_ui <- function(id) {
  
  # ns <- NS(id)
  # leaflet::leafletOutput(ns("map"))
  
}

map_server <- function(id, 
                       inputs,
                       data, 
                       rasters, 
                       ice_raster,
                       map_proxy) {
  moduleServer(id, function(input, output, session) {
    
    # waiter loading animation
    w = waiter::Waiter$new(
      id = "map",
      html = waiter::spin_3(), 
      color = waiter::transparent(.5)
    )
    
    observe({
      # data mapping
      
      # show loading animation
      w$show()
      
      raster_to_map = switch(data$datatype, 
                             `Tidal Amplitude` = rasters$amp_raster, 
                             `Stratification` = rasters$strat_raster,
                             `Peak Bed Stress` = rasters$bss_raster,
                             `Tidal Current` = rasters$vel_raster
      )
      
      to_map = names(raster_to_map)[stringr::str_detect(names(raster_to_map), 
                                                        glue::glue("^X{inputs$yearBP}_"))]
      ice_to_map = names(ice_raster)[stringr::str_detect(names(ice_raster), 
                                                         glue::glue("^X{inputs$yearBP}_"))]
      
      # inputs$coast returns T or F for showing shapefile
      
      
      # filter by time_step
      the_raster = raster_to_map[[to_map]]
      ice_raster = ice_raster[[ice_to_map]]
      
      # Tidal Amplitude Map
      if(data$datatype == "Tidal Amplitude") {
        
        pal <- leaflet::colorNumeric(palette = "viridis",
                            domain = c(0, 4),
                            na.color = "#bebebe")
        

        
        mp <- map_proxy() |> 
          leaflet::clearControls() |> 
          leaflet::clearShapes() |> 
          leaflet::addRasterImage(the_raster, 
                                  colors = pal) |> 
          leaflet::addRasterImage(ice_raster, colors = "aliceblue") |> 
          leaflet::addPolygons(data = shape_1, 
                               weight = 0.5, 
                               opacity = 1,
                               color = "black",
                               fillOpacity = 0) |> 
          leaflet::addLegend("topright", colors = c("#bebebe", "aliceblue"),
                    labels = c("Land", "Ice"),
                    opacity = 1) |> 
          addLegend_decreasing("bottomright", pal = pal, values = c(0,4), bins = 5, 
                               title = "Tidal Amplitude (m)",
                               opacity = 1,
                               decreasing = TRUE)

        mp
        
        if(inputs$coast == FALSE) {
          mp2<- mp |> 
            leaflet::clearShapes()
          mp2
        }
        
        # hide loading screen
        w$hide()
        
        # Tidal Current Map
      } else if (data$datatype == "Tidal Current") {
        
        pal <- leaflet::colorNumeric(palette = "viridis",
                            domain = c(0, 1.6),
                            na.color = "#bebebe")
        
        mp <- map_proxy() |> 
          leaflet::clearControls() |> 
          leaflet::clearShapes() |>  
          leaflet::addRasterImage(the_raster, 
                                  colors = pal) |> 
          leaflet::addRasterImage(ice_raster, colors = "aliceblue") |> 
          leaflet::addPolygons(data = shape_1, 
                               weight = 0.5, 
                               opacity = 1,
                               color = "black",
                               fillOpacity = 0) |> 
          leaflet::addLegend("topright", colors = c("#bebebe", "aliceblue"),
                    labels = c("Land", "Ice"),
                    opacity = 1) |> 
          addLegend_decreasing("bottomright", pal = pal, values = c(0, 1.6), bins = 4, 
                               title = "Tidal Current (m/s)",
                               opacity = 1,
                               decreasing = TRUE)
        
        mp
        
        if(inputs$coast == FALSE) {
          mp2<- mp |> 
            leaflet::clearShapes()
          mp2
        }
        
        # hide loading screen
        w$hide()
        
        # Strat Map
      } else if(data$datatype == "Stratification") {
        
        pal <- leaflet::colorFactor(palette = rev(c("#43A2CA", 
                                                "#A8DDB5", 
                                                "#f1ffed")),
                           domain = raster::values(the_raster),
                           na.color = "#bebebe", 
                           reverse = TRUE)
        
        mp <- map_proxy() |> 
          leaflet::clearControls() |> 
          leaflet::clearShapes() |> 
          leaflet::addRasterImage(the_raster, 
                                  colors = pal) |> 
          leaflet::addRasterImage(ice_raster, colors = "aliceblue") |> 
          leaflet::addPolygons(data = shape_1, 
                               weight = 0.5, 
                               opacity = 1,
                               color = "black",
                               fillOpacity = 0) |> 
          leaflet::addLegend("topright", colors = c("#bebebe", "aliceblue"),
                             labels = c("Land", "Ice"),
                             opacity = 1) |> 
          leaflet::addLegend("bottomright",
                    colors = c("#43A2CA", 
                               "#A8DDB5", 
                               "#f1ffed"),
                    labels = c("Mixed", "Frontal", "Stratified"),
                    title = "Stratification",
                    opacity = 1)
        
        
        mp
        
        if(inputs$coast == FALSE) {
         mp2<- mp |> 
           leaflet::clearShapes()
         mp2
        }
        
        # hide loading screen
        w$hide()
        
      } else if(data$datatype == "Peak Bed Stress") {
        

        # bss palette
        pal = leaflet::colorNumeric(palette = "viridis",
                           domain = raster::values(the_raster),
                           na.color = "#bebebe", 
                           reverse = FALSE)
        
        # dynamic spacing
        spacing = switch(inputs$vec_space, 
                         `sparse` = 800, 
                         `medium` = 500,
                         `dense` = 200
        )
       
        mp <- map_proxy() |> 
          leaflet::clearControls() |> 
          leaflet::clearShapes() |> 
          leaflet::addRasterImage(the_raster, 
                                  colors = pal) |> 
          leaflet::addRasterImage(ice_raster, colors = "aliceblue") |> 
          leaflet::addPolygons(data = shape_1,
                               layerId = "coastline",
                               weight = 0.5, 
                               opacity = 1,
                               color = "black",
                               fillOpacity = 0) |> 
          leaflet::addLegend("topright", colors = c("#bebebe", "aliceblue"),
                             labels = c("Land", "Ice"),
                             opacity = 1)  |> 
          addLegend_decreasing("bottomright", pal = pal, values = c(0, 15), bins = 4, 
                               title = "Peak Bed Stress (N/m<sup>2</sup>)",
                               opacity = 1,
                               decreasing = TRUE)
        
        to_plot = bss_polylines |>
          dplyr::filter(year == inputs$yearBP)

        for(group in unique(to_plot$id)){
          mp = leaflet.extras2::addArrowhead(mp,
                                              lng= ~x,
                                              lat= ~y,
                                              data = to_plot[to_plot$id==group,],
                                              weight = 2,
                                              color = "white")
        }
        
        
        mp
        
        if(inputs$coast == FALSE) {
          mp2<- mp |> 
            leaflet::removeShape(layerId = "coastline")
          mp2
        }
        
        # hide loading screen
        w$hide()
      }

      
      })
      
    })
    
  }
