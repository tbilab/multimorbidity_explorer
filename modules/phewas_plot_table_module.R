source(here::here('helpers/network_helpers.R'))

phewas_plot_table_UI <- function(id, app_ns) {
  ns <- . %>% NS(id)() %>% app_ns()
  
  tagList(
    box(title = "Manhattan Plot (Phecode 1.2)",
        width = NULL,
        solidHeader=TRUE,          
        collapsible = TRUE,
        div(id = 'manhattanPlot',
            plotlyOutput(ns("manhattanPlot"), height = '100%')
        )
    ),
    div(id = 'selected_code_box',
        box(
          title = "Phewas Results (Selected Codes)",
          id = 'codeTable',
          solidHeader=TRUE,          
          width = NULL,
          collapsible = TRUE,
          collapsed = TRUE,
          dataTableOutput(ns('selected_codes_list')),
          div(
            id = 'table_selection',
            span('Click on rows to unselect codes.'),
            uiOutput(ns("filter_button"))
          )
        )
    )
  )
}

phewas_plot_table <- function(
  input, output, session, 
  results_data, 
  included_codes,
  category_colors
) {
  # we need to give the button an ever changing ID or else we will run into values hanging around on refresh causing infinite loops
  button_id <- paste0('table_filter_', as.integer(Sys.time()))
  
  output$filter_button <- renderUI({
    actionButton(session$ns(button_id), "Update")
  })
  
  module_data <- reactiveValues(
    selected_codes = c()
  )
  
  #----------------------------------------------------------------
  # Manhattan Plot of Phewas Results
  #----------------------------------------------------------------
  output$manhattanPlot <- renderPlotly({
    results_data %>%
      mutate(
        selected = ifelse(code %in% included_codes$code, 1, 0.2),
        id = 1:n(),
        tooltip = str_remove_all(tooltip, '</br>') # plotly has trouble with breaks in html, uses /n instead.
      ) %>%
      plot_ly(
        x = ~code,
        y = ~-log10(p_val),
        key = ~id,
        color = ~category, colors = category_colors$named_array,
        symbol = ~selected, symbols = c(1,20),
        size = ~selected, sizes = c(2,30),
        text = ~tooltip,
        type = 'scatter',
        mode = 'markers',
        source = 'snpselect',
        hoverinfo = 'text'
      ) %>%
      config(displayModeBar = F) %>%
      layout(
        dragmode =  "select",
        showlegend = FALSE,
        xaxis = list(
          zeroline = FALSE,
          showline = FALSE,
          showticklabels = FALSE,
          showgrid = FALSE
        ),
        margin = list(
          r = 5,
          b = 0,
          t = 1
        )
      )
    
  })
  
  #----------------------------------------------------------------
  # Table output of selected codes.
  #----------------------------------------------------------------
  output$selected_codes_list <- renderDataTable({
    included_codes %>%
      arrange(p_val) %>%
      select(code, `P-Value` = p_val, class = category) %>%
      datatable(
        options = list(
          scrollY = 200,
          scroller = TRUE,
          dom = 't',
          order = list(list(3, 'asc')),
          pageLength = nrow(.)
        ),
        selection = list('multiple', selected = 1:nrow(.))
      )
  })

  # Watch for manhattan plot code selection
  observe({
    selected_points <- event_data("plotly_selected", source = "snpselect")
    req(selected_points)
    module_data$selected_codes <- results_data[selected_points$key,]
  })

  observeEvent(input[[button_id]], {
    codes_to_keep <- input$selected_codes_list_rows_selected

    if(length(codes_to_keep) >= 2){
      module_data$selected_codes <- included_codes %>%
        arrange(p_val) %>%
        `[`(codes_to_keep,)
    } else {
      # alert user they attempted to remove too many codes.
      warn_about_selection()
    }
  })

  # return value of user's choice on the snp filtering. 
  return(
    reactive({
      module_data$selected_codes
    })
  )
}