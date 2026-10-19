
# Single-page layout: a header bar (title + About link) above the visualizations
ui = bslib::page_fillable(

# Setup -------------------------------------------------------------------
    title = "Paleotidal Data Visualizations",
    theme = bslib::bs_theme(bootswatch = "zephyr",
                            version = 5),
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
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
    bslib::layout_columns(
      col_widths = c(7, 5),
      bslib::layout_columns(
        col_widths = 12,
        # top row sizes to its content; map takes the rest
        row_heights = list("auto", 1),
        bslib::layout_columns(
          col_widths = c(5, 7),
          bslib::card(
            class = "compact-card",
            data_select_ui("data_type")
          ),
          input_ui("inputs")
        ),
        bslib::card(
          full_screen = TRUE,
          bslib::card_header("Map"),
          leaflet::leafletOutput("map")
        )
      ),
      
      # Time series
      time_series_ui("time_series")
    )
  )
