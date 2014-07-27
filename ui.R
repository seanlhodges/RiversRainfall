

library(shiny)

# Define UI for miles per gallon application
shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("Rainfall summaries"),
  
  # Sidebar with controls to select the variable to plot against mpg
  # and to specify whether outliers should be included
  sidebarPanel(
    
    textInput("plotTitle","Plot title:",
              value="Cautionary data"),
    
    selectInput("collection", "Parameter:",
                choices=c("Rainfall","AirTemperature","DissolvedOxygen","FireWeatherIndex","Flow","FlowDistribution","Humidity","SoilMoisture","Turbidity","WaterMatters","zVirtual Rainfall")),
    
    dateInput("fromdate", "Select start date:", value = NULL, min = NULL,
                max = NULL, format = "yyyy-mm-dd", startview = "month",
                weekstart = 0, language = "en"),

    selectInput("fromhour", "Select time (NZST) of day to calculate values from:",
                choices=c("00:00:00","01:00:00","02:00:00","03:00:00","04:00:00","05:00:00","06:00:00","07:00:00","08:00:00","09:00:00","10:00:00","11:00:00","12:00:00","13:00:00","14:00:00","15:00:00","16:00:00","17:00:00","18:00:00","19:00:00","20:00:00","21:00:00","22:00:00","23:00:00")),
    
    #sliderInput("intSymSize", "Select time of day (NZST) to calculate values from:", 
    #            min=0, max=23, value=0)

    selectInput("interval", "Select the time range:",
                choices=c("1 hour", "3 hours","6 hours", "12 hours", "1 day","2 days", "3 days","4 days","5 days","6 days", "1 week", "1 month", "3 months","6 months","12 months")),
    
    selectInput("method", "Method:",
                choices=c("Total","Average","Moving Average","Interpolated")),
    
    #checkboxInput("outliers", "Show outliers", FALSE),
    
    # Simple integer interval for writing site lable
    #sliderInput("intSite", "Hilltop Site:", 
    #            min=1, max=20, value=1),
    
    #maptype <- c("roadmap", "mobile", "satellite", "terrain", "hybrid")
    selectInput("basemap", "Select basemap:",
                 list("Road map" = "1", 
                        "Mobile" = "2", 
                     "Satellite" = "3",
                       "Terrain" = "4",
                        "Hybrid" = "5")),
    
    selectInput("showPointLabels","Show point labels?",
                choices=c("No","Yes")),
    
    sliderInput("intSymSize", "Adjust symbol size:", 
                min=1, max=7, value=4)
       
    
  ),
  
  # Show the caption and plot of the requested variable against mpg
  mainPanel(
    tabsetPanel(
      tabPanel("Plot",  plotOutput("gmap", width="640px", height="640px")),
      tabPanel("Summary", verbatimTextOutput("summary")),
      tabPanel("Table", tableOutput("table"))
    )
  )
  
))
