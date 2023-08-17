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
      raster = raster_to_map[[to_map]]
      ice_raster = ice_raster[[ice_to_map]]
      
      # Tidal Amplitude Map
      if(data$datatype == "Tidal Amplitude") {
        
        pal <- leaflet::colorNumeric(palette = "viridis",
                            domain = c(0, 4),
                            na.color = "gray30")
        

        
        mp <- map_proxy() |> 
          leaflet::clearControls() |> 
          leaflet::clearShapes() |> 
          leaflet::addRasterImage(raster, 
                                  colors = pal) |> 
          leaflet::addRasterImage(ice_raster, colors = "aliceblue") |> 
          leaflet::addPolygons(data = shape_1, 
                               weight = 0.5, 
                               opacity = 1,
                               color = "black",
                               fillOpacity = 0) |> 
          leaflet::addLegend("topright", colors = c("gray", "aliceblue"),
                    labels = c("land", "ice"),
                    opacity = 1) |> 
          leaflet::addLegend("bottomright", pal = pal, values = c(0, 4), bins = 5,
                    title = "Tidal Amplitude",
                    labFormat = leaflet::labelFormat(suffix = " m"), 
                    opacity = 1)
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
                            na.color = "gray30")
        
        mp <- map_proxy() |> 
          leaflet::clearControls() |> 
          leaflet::clearShapes() |>  
          leaflet::addRasterImage(raster, 
                                  colors = pal) |> 
          leaflet::addRasterImage(ice_raster, colors = "aliceblue") |> 
          leaflet::addPolygons(data = shape_1, 
                               weight = 0.5, 
                               opacity = 1,
                               color = "black",
                               fillOpacity = 0) |> 
          leaflet::addLegend("topright", colors = c("gray", "aliceblue"),
                    labels = c("land", "ice"),
                    opacity = 1) |> 
          leaflet::addLegend("bottomright", pal = pal, values = c(0, 1.6), bins = 4,
                    title = "Tidal Current",
                    labFormat = leaflet::labelFormat(suffix = " m/s"), 
                    opacity = 1)
        
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
        
        pal <- leaflet::colorFactor(palette = "GnBu",
                           domain = raster::values(raster),
                           na.color = "gray30", 
                           reverse = TRUE)
        
        mp <- map_proxy() |> 
          leaflet::clearControls() |> 
          leaflet::clearShapes() |> 
          leaflet::addRasterImage(raster, 
                                  colors = pal) |> 
          leaflet::addRasterImage(ice_raster, colors = "aliceblue") |> 
          leaflet::addPolygons(data = shape_1, 
                               weight = 0.5, 
                               opacity = 1,
                               color = "black",
                               fillOpacity = 0) |> 
          leaflet::addLegend("topright", colors = c("gray", "aliceblue"),
                             labels = c("land", "ice"),
                             opacity = 1) |> 
          leaflet::addLegend("bottomright",
                    colors = c("#43A2CA", 
                               "#A8DDB5", 
                               "#E0F3DB"),
                    labels = c("mixed", "frontal", "stratified"),
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
       
        pal <- leaflet::colorNumeric(palette = "viridis",
                           domain = raster::values(raster),
                           na.color = "gray30")
        
        mp <- map_proxy() |> 
          leaflet::clearControls() |> 
          leaflet::clearShapes() |> 
          leaflet::addRasterImage(raster, 
                                  colors = pal) |> 
          leaflet::addRasterImage(ice_raster, colors = "aliceblue") |> 
          leaflet::addPolygons(data = shape_1, 
                               weight = 0.5, 
                               opacity = 1,
                               color = "black",
                               fillOpacity = 0) |> 
          leaflet::addLegend("topright", colors = c("gray", "aliceblue"),
                             labels = c("land", "ice"),
                             opacity = 1)  |> 
          leaflet::addLegend("bottomright", pal = pal, values = c(0, 15), bins = 4,
                             title = "Peak Bed Stress",
                             labFormat = leaflet::labelFormat(suffix = " N/m2"), 
                             opacity = 1)
        

        bss_filt = bss |> 
          dplyr::filter(year == inputs$yearBP) |> 
          dplyr::filter(!is.na(quadrant)) |> 
          dplyr::filter(uv > 1) |> 
          dplyr::slice_max(order_by = uv, n = 500)
        
        # mag multiplier
        mag_mult = 0.05
        polylines_df_base = bss_filt |> 
          dplyr::mutate(id = dplyr::row_number())
        
        polylines_end = bss_filt |> 
          dplyr::mutate(x = x+(u*mag_mult), 
                 y = y+(v*mag_mult)) |> 
          dplyr::mutate(id = dplyr::row_number())
        
        to_plot = dplyr::bind_rows(polylines_df_base, polylines_end) |> 
          dplyr::mutate(id = factor(id))
        
        for(group in levels(to_plot$id)){
          mp = leaflet.extras2::addArrowhead(mp,
                                              lng= ~x,
                                              lat= ~y,
                                              data = to_plot[to_plot$id==group,],
                                              weight = 2)
        }
        
        
        mp
        
        if(inputs$coast == FALSE) {
          mp2<- mp |> 
            leaflet::clearShapes()
          mp2
        }
        
        # hide loading screen
        w$hide()
      }

      
      })
      
    })
    
  }
