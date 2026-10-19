
# Single-page layout: a header bar (title + About link) above the visualizations
ui = bslib::page_fillable(

# Setup -------------------------------------------------------------------
    title = "Palaeotidal Data Visualisations",
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
      tags$script(src = "map_layers.js"),
      tags$script(src = "split_handle.js")
      ),
    tags$style(type = "text/css", ".irs-grid-pol.small {height: 0px;}"),
    # waiter load animations (previously supplied by the navbar header)
    waiter::use_waiter(),

# Header ------------------------------------------------------------------
    div(
      class = "app-header d-flex align-items-center justify-content-between",
      div(class = "app-title", "Palaeotidal Data Visualisations"),
      div(
        class = "d-flex align-items-center gap-3",
        # opens the About modal
        shiny::actionLink("show_about", "About", icon = shiny::icon("circle-info")),
        # light/dark toggle; starts from the user's system setting
        bslib::input_dark_mode(id = "color_mode")
      )
    ),

# Data Viz ----------------------------------------------------------------
    # all data selection inputs, collapsible, full width under the header
    selection_card_ui("selection_card",
                      data_id = "data_type",
                      inputs_id = "inputs"),
    
    # map and time series side by side, with a draggable divider between them
    # (behavior in www/split_handle.js, layout in www/style.css)
    bslib::as_fill_item(
      div(
        class = "split-container",
        bslib::card(
          class = "split-pane split-left",
          full_screen = TRUE,
          # no padding so the map fills the whole card
          bslib::card_body(
            padding = 0,
            leaflet::leafletOutput("map")
          )
        ),
        div(
          class = "split-handle",
          role = "separator",
          `aria-orientation` = "vertical",
          `aria-label` = "Resize map and graph panels",
          `aria-valuemin` = "0",
          `aria-valuemax` = "100",
          `aria-valuenow` = "58",
          tabindex = "0"
        ),
        
        # Time series
        htmltools::tagAppendAttributes(
          time_series_ui("time_series"),
          class = "split-pane split-right"
        )
      )
    )
  )
