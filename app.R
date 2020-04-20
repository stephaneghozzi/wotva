library(shiny)
library(shinydashboard)
library(shinycssloaders)
library(ISOweek)
library(ggplot2)
library(plotly)
library(leaflet)
library(rpivotTable)
library(DT)
library(Rtsne)
library(dplyr)

# Functions and parameters ----

source('src/ConvertToListMatrix.R')
source('src/ComputeScores.R')
source('src/GenerateEventLineList.R')
source('src/CaseCaseVarDistance.R')
source('src/ComputeDistances.R')
source('src/AppendScoresToLineList.R')
source('src/ComputeTSNE.R')
n_ref_cases <- 10
ref_seed <- 1000
date_ref_from <- as.Date('2015-1-1')
date_ref_to <- as.Date('2019-09-30')
maximum_multiplicity <- 3
conf_interval_extension <- 0.5
case_color <- '#4682b4' # vega default
colors_few_refs <- c('#4E79A7', '#F28E2B', '#E15759', '#76B7B2', '#59A14F', '#EDC948', '#B07AA1', '#FF9DA7',
  '#9C755F', '#BAB0AC') # tableau10
colors_many_refs <- c('#4E79A7', '#A0CBE8', '#F28E2B', '#FFBE7D', '#59A14F', '#8CD17D', '#B6992D', '#F1CE63',
  '#499894', '#86BCB6', '#E15759', '#FF9D9A', '#79706E', '#BAB0AC', '#D37295', '#FABFD2', '#B07AA1',
  '#D4A6C8', '#9D7660', '#D7B5A6') # tableau20

# Directories for automatic datsets upload
datadictionary_dir <- 'data/datadictionary'
reference_dir <- 'data/references'
linelist_dir <- 'data/linelists'

# UI ----

ui <- dashboardPage(

  dashboardHeader(title = 'WHO Outbreak Toolkit Virtual Assistant', disable = F, titleWidth = 400,
    tags$li(class = 'dropdown', conditionalPanel(condition = '$("html").hasClass("shiny-busy")', 'loading...'))),
  dashboardSidebar(
    sidebarMenu(
      uiOutput('load_type'),
      conditionalPanel(
        condition='input.load_type == "auto"',
        uiOutput('data_dictionary_auto'),
        uiOutput('reference_auto'),
        uiOutput('linelist_auto')
      ),
      conditionalPanel(
        condition='input.load_type == "manual"',
        fileInput('data_dictionary_file', 'Data dictionary', multiple = F,
          accept = c('text/csv', 'text/comma-separated-values,text/plain', '.csv')),
        fileInput('reference_files', 'References', multiple = T,
          accept = c('text/csv', 'text/comma-separated-values,text/plain', '.csv')),
        fileInput('linelist_file', 'Line list', multiple = F,
          accept = c('text/csv', 'text/comma-separated-values,text/plain', '.csv'))
      ),
      width = 800)
  ),

  dashboardBody(
    tags$head(
      tags$style(type='text/css',
        '.shiny-output-error { visibility: hidden; }',
        '.shiny-output-error:before { visibility: hidden; }'),
      tags$style(HTML(
        '.skin-blue .content {background-color: #ffffff;}
         .skin-blue .content-wrapper {background-color: #ffffff;}
         .skin-blue .main-header .logo {
           background-color: #638291;
           font-family: "Source Sans Pro", "Helvetica Neue", Helvetica, Arial, sans-serif;
           font-size: 24px}
         .skin-blue .main-header .logo:hover {background-color: #638291;}
         .skin-blue .main-header .navbar {background-color: #638291;}
         .skin-blue .main-header .navbar .sidebar-toggle {font-color: white;}
         .skin-blue .main-header .navbar .sidebar-toggle:hover{background-color: #638291;}
         .skin-blue .main-header .navbar .dropdown {
           font-size: 20px;
           line-height: 50px;
           text-align: center;
           font-family: "Source Sans Pro", "Helvetica Neue", Helvetica, Arial, sans-serif;
           padding: 0 50px;
           overflow: hidden;
           color: white}
         hr {border-top: 1px solid #D3D3D3;}'))
    ),
    fluidPage(
      HTML('Prototype of a tool to help the investigation of outbreaks of unknown origin, developed for the <a href="https://www.who.int/emergencies/outbreak-toolkit">Outbreak Toolkit</a> of WHO.'), br(),
      HTML('See the <a href="https://gitlab.com/stephaneghozzi/wotva">project repository</a> for information.'),
      br(),hr(),br(),
      h4(HTML(paste0('You are looking at the cases from',
        tags$b(tags$span(style=paste0('color:',case_color),textOutput('header_linelist'))),
        'with disease references',
        tags$b(textOutput('header_references'))))),
      br(), hr(),br(),
      splitLayout(cellWidths = c('45%','10%', '45%'),
        withSpinner(plotlyOutput('score_plot', height=450), color='lightgrey'),
        ' ',
        withSpinner(plotlyOutput('tsne_plot', height=450), color='lightgrey')
      ),
      br(),hr(),br(),
      splitLayout(cellWidths = c('45%','10%', '45%'),
        withSpinner(plotlyOutput('epicurve', height=450), color='lightgrey'),
        ' ',
        withSpinner(leafletOutput('map', height=450), color='lightgrey')
      ),
      br(),hr(),br(),
      withSpinner(DT::dataTableOutput('linelist_table'), color='lightgrey'),
      br(),hr(),br(),
      withSpinner(rpivotTableOutput('pivot'), color='lightgrey')
    )
  )
)

# Server ----

server <- function(input, output, session) {

  ### Load and arrange data ----

  # How data are loaded
  # if "auto", a dropdown menu is displayed that offers to select data sets from those available in data/
  # if "manual", the user has to upload the data dictionary, the references and the case data (line list)
  output$load_type <- renderUI({
    load_type <- c('auto', 'manual')
    radioButtons('load_type', 'Load data', load_type, inline = T, selected = load_type[1])
  })

  # If upload type is "auto": chose datasets
  output$data_dictionary_auto <- renderUI({
    dd_available <- list.files(datadictionary_dir)
    dd_available <- dd_available[grep('.csv',dd_available)]
    names(dd_available) <- sapply(dd_available, function (nr) paste(strsplit(gsub('.csv','',nr),'_')[[1]],collapse=' '))
    selectInput('data_dictionary_auto', 'Data dictionary', choices=dd_available, selected=dd_available[1])
  })

  output$reference_auto <- renderUI({
    req(input$data_dictionary_auto)
    ref_available <- list.dirs(reference_dir, full.names=F)
    ref_available <- ref_available[ref_available!='']
    ref_available <- sapply(ref_available, function (nr) paste(strsplit(gsub('.csv','',nr),'_')[[1]],collapse=' '))
    selectInput('reference_auto', 'References', ref_available, selected=ref_available[1])
  })

  output$linelist_auto <- renderUI({
    req(input$reference_auto)
    ## DEBUG:
    # input <- data.frame(reference_auto = 'fake')
    ll_available <- list.files(paste0(linelist_dir,'/',input$reference_auto,'_ref'), full.names=F, recursive=T)
    ll_available <- ll_available[grep('.csv',ll_available)]
    names(ll_available) <- sapply(ll_available, function (nr) paste(strsplit(gsub('.csv','',nr),'_')[[1]],collapse=' '))
    selectInput('linelist_auto', 'Line list', ll_available, selected=ll_available[1])
  })

  data_dictionary <- reactive({
    req(input$load_type)
    if (input$load_type == 'auto') {
      req(input$data_dictionary_auto)
      dd_path <- paste0(datadictionary_dir,'/',input$data_dictionary_auto)
    } else if (input$load_type == 'manual') {
      req(input$data_dictionary_file)
      dd_path <- input$data_dictionary_file$datapath
    }
    dd_df <- read.csv(dd_path, stringsAsFactors = F)
    dd_mat <- ConvertToListMatrix(dd_df,NULL,'datadictionary')
    return(dd_mat)
  })

  reference_list <- reactive({
    req(input$load_type)
    if (input$load_type == 'auto') {
      req(input$reference_auto)
      ref_paths <- list.files(paste0(reference_dir,'/',input$reference_auto), full.names=T)
      ref_paths <- ref_paths[grep('.csv',ref_paths)]
      ref_names <- list.files(paste0(reference_dir,'/',input$reference_auto), full.names=F)
      ref_names <- ref_names[grep('.csv',ref_names)]
    } else if (input$load_type == 'manual') {
      req(input$reference_files)
      ref_paths <- input$reference_files$datapath
      ref_names <- input$reference_files$name
    }
    ref_names <- sapply(ref_names, function (nr) paste(strsplit(gsub('.csv','',nr),'_')[[1]],collapse=' '))
    ref_list <- list()
    for (i in 1:length(ref_paths)) {
      ref_df <- read.csv(ref_paths[i], stringsAsFactors = F)
      ## DEBUG:
      # ref_mat <- ConvertToListMatrix(ref_df,dd_mat,'reference')
      ref_mat <- ConvertToListMatrix(ref_df,data_dictionary(),'reference')
      ref_list[[ref_names[i]]] <- ref_mat
    }
    return(ref_list)
  })

  linelist <- reactive({
    req(input$load_type)
    if (input$load_type == 'auto') {
      req(input$linelist_auto)
      ll_path <- paste0(linelist_dir,'/',input$reference_auto,'_ref','/',input$linelist_auto)
      ll_name <- input$linelist_auto
    } else if (input$load_type == 'manual') {
      req(input$linelist_file)
      ll_path <- input$linelist_file$datapath
      ll_name <- input$linelist_file$name
    }
    ll_name <- paste(strsplit(gsub('.csv','',ll_name), '_')[[1]],collapse=' ')
    ll_df <- read.csv(ll_path, stringsAsFactors = F)
    ## DEBUG:
    # ll_mat <- ConvertToListMatrix(ll_df,dd_mat,'linelist')
    ll_mat <- ConvertToListMatrix(ll_df,data_dictionary(),'linelist')
    return(list(name=ll_name,df=ll_df,mat=ll_mat))
  })

  ref_case_colors <- reactive({
    rc <- ifelse(length(reference_list())>10,colors_many_refs,colors_few_refs)
    rc <- rep_len(rc,length(reference_list()))
    rc <- c(rc,case_color)
    names(rc) <- c(names(reference_list()),linelist()$name)
    return(rc)
  })

  reference_cases <- reactive({
    ## DEBUG:
    # data_dict <- dd_mat; r_list <- ref_list
    data_dict <- data_dictionary(); r_list <- reference_list()
    ref_cases <- matrix(list(),nrow=0,ncol=1+nrow(data_dict))
    for (i in 1:length(r_list)) {
      set.seed(ref_seed+i)
      nr <- names(r_list)[i]
      event_ref_list <- list()
      event_ref_list[[nr]] <- r_list[[i]]
      cases <- GenerateEventLineList(data_dict,event_ref_list,0,n_ref_cases,maximum_multiplicity,
        conf_interval_extension,paste0('ref_', tolower(gsub(' ','_',nr))),date_ref_from,date_ref_to)
      ref_cases <- rbind(ref_cases, cases)
    }
    return(ref_cases)
  })

  ### Score, distance and t-SNE computations ----

  scores <- reactive({
    ComputeScores(linelist()$mat,linelist()$name,reference_list(),data_dictionary())
  })

  linelist_scores <- reactive({
    AppendScoresToLineList(linelist(), reference_list(), scores())
  })

  distances <- reactive({
    withProgress(message = 'Computing 2d projection', value = 0, {
      ComputeDistances(rbind(reference_cases(),linelist()$mat),reference_list(),data_dictionary(),T)
    })
  })

  tsne_projection <- reactive({
    ## DEBUG:
    # dist_mat <- readRDS('data/distance_list_fake.rds'))[['Noisy West Rhine Virus event']]
    # llist <- ll_mat; llname <- ll_name; r_list <- ref_list
    dist_mat <- distances();
    llist <- linelist()$mat; llname <- linelist()$name; r_list <- reference_list()
    ComputeTSNE(dist_mat, llist, llname, r_list, n_ref_cases)
  })

  ### Output ----

  output$header_linelist <- renderText({
    linelist()$name
  })

  output$header_references <- renderText({
    paste0(paste(names(reference_list()), collapse=', '),'.')
  })

  output$score_plot <- renderPlotly({
    sp_plotly_options <- list(showline=T,zeroline=F,mirror=T,ticks='outside')
    score1_case_plot_df <- scores()
    plot_ly(data = score1_case_plot_df, x = ~s1, y = ~reference) %>%
      add_boxplot(jitter = 0.5,pointpos=-1.5,boxpoints='all',text=~paste0('<b>case id</b><br>',case_id),
        hoverinfo='text',color=case_color,colors=case_color,
        marker=list(color='rgba(0,0,0,0)',size=5,opacity=0.7,line=list(color=case_color,width=2)),
        line = list(width=1)) %>%
      layout(xaxis=append(sp_plotly_options, list(title='score',range=c(0,1))),
        yaxis=append(sp_plotly_options, list(title='', autorange='reversed')))
  })

  output$tsne_plot <- renderPlotly({
    # tsne_projection_plot <- tsne_projection()
    # tsne_projection_plot$reference <- as.character(tsne_projection_plot$reference)
    tot_n_ref_c <- length(reference_list())*n_ref_cases
    tsne_projection_ll <- tsne_projection()[(tot_n_ref_c+1):(tot_n_ref_c+nrow(linelist()$mat)),]
    tsne_projection_ref <- tsne_projection()[1:tot_n_ref_c,]
    tsne_plotly_options <- list(showline=T,zeroline=F,showticklabels=F,title='',mirror=T)
    plot_ly(type = 'scatter', mode = 'markers') %>%
      add_trace(data=tsne_projection_ll,x=~x, y=~y,
        marker=list(color='rgba(0,0,0,0)',size=10,opacity=0.85,line=list(color=case_color,width=4)),
        text=~paste0('<b>case id</b><br>',case_id),
        hoverinfo='text',showlegend=F) %>%
      add_markers(data=tsne_projection_ref, x=~x, y=~y, color=~reference,colors=ref_case_colors(),size=12,
        text=~paste0('<b>case id</b><br>',case_id),
        hoverinfo='text',showlegend=T) %>%
      layout(xaxis=tsne_plotly_options, yaxis=tsne_plotly_options,
        legend = list(orientation = 'h', x = 0.0, y = -0.1))
  })

  output$epicurve <- renderPlotly({
    ## DEBUG:
    # onset_date <- ll_mat[,'onset_date']
    onset_date <- linelist()$mat[,'onset_date']
    onset_day <- sapply(onset_date, function (da) da[[1]])
    daily_count <- table(onset_day)
    all_days <- as.Date(seq(min(onset_day),max(onset_day)),origin='1970-1-1')
    daily_count_df <- data.frame(date = as.Date(as.numeric(rownames(daily_count)),origin='1970-1-1'),
      count = c(daily_count))
    daily_count_df <- rbind(daily_count_df,
      data.frame(date=all_days[!all_days%in%daily_count_df$date], count=0))
    onset_week <- sapply(onset_date, function (da) ISOweek2date(paste0(ISOweek(da[[1]]),'-1')))
    all_weeks <- as.Date(sapply(all_days, function (da) ISOweek2date(paste0(ISOweek(da),'-1'))),
      origin='1970-1-1')
    weekly_count <- table(onset_week)
    weekly_count_df <- data.frame(date = as.Date(as.numeric(rownames(weekly_count)),origin='1970-1-1'),
      count = c(weekly_count))
    weekly_count_df <- rbind(weekly_count_df, data.frame(date=all_weeks[!all_weeks%in%weekly_count_df$date], count=0))
    epic <- ggplot(weekly_count_df, aes(x = date, y = count)) +
      geom_line(color = case_color, size = 0.5) +
      ylim(c(0,max(weekly_count_df$count))) +
      ylab('weekly count') +
      theme_bw() +
      theme()
    ggplotly(epic)
  })

  output$map <- renderLeaflet({
    latitude <- sapply(linelist()$mat[,'gps_lat'], function (gp) gp[[1]])
    longitude <- sapply(linelist()$mat[,'gps_long'], function (gp) gp[[1]])
    coordinates_df <- data.frame(case_id = rownames(linelist()$mat), latitude = latitude,
      longitude = longitude)
    leaflet(data = coordinates_df) %>% addTiles() %>%
    addCircleMarkers(~longitude,~latitude,popup=~paste0('<b>case id</b><br>',case_id),
      label=~case_id,radius=6,color=case_color,stroke=T,fill=F,opacity=0.95,weight=5)
  })

  output$linelist_table <- DT::renderDataTable({
    datatable(linelist_scores()$df,
      style = 'bootstrap', extensions = 'Buttons', options = list(dom = 'Bftlrip', scrollX = T,
        buttons = c('csv', 'excel')),
      rownames = F) %>%
      formatStyle(columns = 1:ncol(linelist_scores()$df),`font-size` = '12px')
  })

  output$pivot <- renderRpivotTable({
    linelist_df <- linelist()$df
    linelist_df$onset_year <- sapply(linelist_df$onset_date,
      function (da) as.numeric(format(as.Date(da),'%Y')))
    rpivotTable(linelist_df[,c('onset_year','age_year','sex','sign_bleed_site','water_drinking_qual',
      'food_unusual')], rows = c('water_drinking_qual'), cols = c('sign_bleed_site', 'sex'),
      aggregatorName = 'Count', rendererName = 'Heatmap', width = 800, height = 600)
  })
}

shinyApp(ui, server)
