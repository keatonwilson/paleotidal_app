
# Single-page layout: a header bar (title + About link) above the visualizations
ui = bslib::page_fillable(

# Setup -------------------------------------------------------------------
    title = "Paleotidal Data Visualizations",
    theme = bslib::bs_theme(
      version = 5,
      bootswatch = "zephyr",
      primary = "#0b6e7f",
      base_font = bslib::font_google("Inter"),
      heading_font = bslib::font_google("Inter", wght = "600")
    ),
    tags$head(
      # version query string so browsers reload the CSS after it changes
      tags$link(rel = "stylesheet", type = "text/css",
                href = paste0("style.css?v=", as.integer(file.mtime("www/style.css")))),
      tags$script(src = "map_layers.js")
      ),
    tags$style(type = "text/css", ".irs-grid-pol.small {height: 0px;}"),
    # waiter load animations (previously supplied by the navbar header)
    waiter::use_waiter(),

# Header ------------------------------------------------------------------
    div(
      class = "app-header d-flex align-items-center justify-content-between",
      div(class = "app-title", "Paleotidal Data Visualizations"),
      # opens the About modal
      shiny::actionLink("show_about", "About", icon = shiny::icon("circle-info"))
    ),

# Data Viz ----------------------------------------------------------------
    # all data selection inputs, collapsible, full width under the header
    selection_card_ui("selection_card",
                      data_id = "data_type",
                      inputs_id = "inputs"),
    
    bslib::layout_columns(
      col_widths = c(7, 5),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("Map"),
        leaflet::leafletOutput("map")
      ),
      
      # Time series
      time_series_ui("time_series")
    )
  )
