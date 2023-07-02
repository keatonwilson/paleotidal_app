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
    time_step = "00"
    
    to_map = data |> 
      dplyr::filter(year == as.numeric(time_step))
    
    extent = raster::extent(-15, 11, 45, 65.0125)
    ncol = 626
    nrow = 861
    
    r = raster(extent, ncol = ncol, nrow = nrow)
    
    # rasterize
    r_to_map = rasterize(to_map[,1:2], r, to_map[,3], fun=mean)
    crs(r_to_map) = "+proj=longlat +datum=WGS84"
    
    output$map = leaflet::renderLeaflet({
      leaflet::leaflet() |> 
        leaflet::addRasterImage(r_to_map)
    })
  })
}