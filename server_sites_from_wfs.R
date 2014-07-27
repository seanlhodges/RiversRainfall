library(shiny)
library(XML)
library(sp)
library(RgoogleMaps)
library(pixmap)

#===================================================================================================
## ===============================================================================
## Getting Site Data

#HSERVER<-"hilltopdev"
servers <- c("http://hilltop.nrc.govt.nz/","http://hilltopserver.horizons.govt.nz/","http://hydro.marlborough.govt.nz/")
wfs_url <- c("data.hts?service=WFS&request=GetFeature&typename=SiteList")

#HSERVER<-c("hilltopserver")


# kludge for all physical sites and virtual rainfall sites is to use the subcatchmentrain.dsn which merges publictelemetry and sucatchment rain hts files
# 
#getSites.xml <- xmlInternalTreeParse(paste("http://",HSERVER,".horizons.govt.nz/boo.hts?service=Hilltop&request=SiteList&location=LatLong",sep=""))
#cat(paste("http://",HSERVER,".horizons.govt.nz/SubcatchmentRain.hts?service=Hilltop&request=SiteList&location=LatLong",sep=""),"\n")

#site.attr<-getNodeSet(getSites.xml,"//Latitude/../@Name")
#site.list<-sapply(site.attr, as.character)
#data.lat <- sapply(getNodeSet(getSites.xml, "//HilltopServer/Site/Latitude"), xmlValue)
#data.lon <- sapply(getNodeSet(getSites.xml, "//HilltopServer/Site/Longitude"), xmlValue)

getSites.xml <- xmlInternalTreeParse(paste(servers[2],wfs_url[1],sep=""))


# This line based on hilltop xml which has name as an attribute of the <Site> element
#site.attr<-getNodeSet(getSites.xml,"//gml:pos/../../../Site")

# In WFS, the <Site> element value is the sitename
site.list<-sapply(getNodeSet(getSites.xml,"//gml:pos/../../../Site"),xmlValue)

# These two lines are based on hilltop xml has separate elements for Lat and Lon
#data.lat <- sapply(getNodeSet(getSites.xml, "//HilltopServer/Site/Latitude"), xmlValue)
#data.lon <- sapply(getNodeSet(getSites.xml, "//HilltopServer/Site/Longitude"), xmlValue)

# In WFS, lat lon are specified as the value in the <gml:pos> element, separated by a single space.
data.latlon <- sapply(getNodeSet(getSites.xml,"//gml:pos"),xmlValue)
latlon <- sapply(strsplit(data.latlon," "),as.numeric)
data.lat <- latlon[1,]
data.lon <- latlon[2,]
rm(latlon)

ds <-data.frame(site.list,data.lat,data.lon, stringsAsFactors=FALSE)


#ds1<-data.frame(site.list,data.lat,data.lon, stringsAsFactors=FALSE)
#ds <- rbind(ds0,ds1)

## ===============================================================================
## Getting Rainfall Data

# Define server logic required to plot various variables against mpg
shinyServer(function(input, output) {
  
  
  #sliderValues <- reactive(function() {
  #  value = input$intSite
  #})
  
  # Compute the forumla text in a reactive function since it is 
  # shared by the output$caption and output$mpgPlot functions
  #formulaText <- reactive(function() {
  #  paste("mpg ~", input$variable)
  #})
  
  # Return the formula text for printing as a caption
  #output$caption <- reactiveText(function() {
  #  formulaText()
  #})

  
  # Return the formula text for printing as a caption
  #output$htsSite <- reactiveText(function() {
  #  site.list[sliderValues()]
  #})
  
  
  ## Attempting to output a google map
  output$gmap <- reactivePlot(function() {
    a<-Sys.time()
    ## Calculating the endDate of the data to retrieve based on
    ## selected interval
    
    fromDate<-strptime(input$fromdate,"%Y-%m-%d")

    ##
   
    if(input$interval=="1 hour") {
      
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh+1
      addDay <- 0
      if(hhEnd>24){
          hhEnd <- hhEnd - 24
	 addDay <- 86400
      }
      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

      } else if (input$interval=="3 hours") {
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh+3
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
	 addDay <- 86400
      }

      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

      } else if (input$interval=="6 hours") {
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh+6
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
	 addDay <- 86400
      }

      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

      } else if (input$interval=="12 hours") {
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh+12
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
	 addDay <- 86400
      }

      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

     } else if (input$interval=="24 hours") {
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh
      addDay <- 86400

      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay


      } else {
      endTime<-input$fromhour
      ## next line required to do date calculations below
      d <- as.POSIXlt(fromDate)
      
      if(input$interval=="1 day") {
        
        d$mday <- d$mday+1
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="2 days") {
        
        d$mday <- d$mday+2
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="3 days") {
        
        d$mday <- d$mday+3
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="4 days") {
        
        d$mday <- d$mday+4
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="5 days") {
        
        d$mday <- d$mday+5
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="6 days") {
        
        d$mday <- d$mday+6
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if (input$interval=="1 week") {

        d$mday <- d$mday+7
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if  (input$interval=="1 month") {
      
        d$mon <- d$mon+1
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      }  else if  (input$interval=="3 months") {

        d$mon <- d$mon+3
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if  (input$interval=="6 months") {
        
        d$mon <- d$mon+6
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if  (input$interval=="12 months") {
        
        d$year<- d$year+1
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      }
    }
    
    if(input$collection=="zVirtual Rainfall"){
	htsName <- "SubcatchmentRain"
    } else {
	htsName <- "boo"
    }
    htsURL<-paste("http://",HSERVER,".horizons.govt.nz/",htsName,".hts?service=Hilltop&request=GetData&Collection=",input$collection,"&From=",input$fromdate," ",input$fromhour,"&To=",endDate," ",endTime,"&interval=",input$interval,"&Method=",input$method,sep="")
    
    cat(htsURL,"\n")

    print(Sys.time()-a)
    
    getData.xml <- xmlInternalTreeParse(htsURL)
    
    site.attr<-getNodeSet(getData.xml,"//E[2]/../../@SiteName")
    site.list<-sapply(site.attr, as.character)
    
    data.date <- sapply(getNodeSet(getData.xml, "//Hilltop/Measurement/Data/E[2]/../E[1]/T"), xmlValue)
    data.value <- sapply(getNodeSet(getData.xml, "//Hilltop/Measurement/Data/E[2]/I1"), xmlValue)
    
    dd<-data.frame(site.list,data.date,data.value, stringsAsFactors=FALSE)
    ## ===============================================================================
    
    ## ===============================================================================
    ## Merging Data For Mapping
    df<-as.data.frame(merge(ds,dd,by=c("site.list","site.list")))
    
    colnames(df)<-c("SiteName","Lat","Lon","Date","Value")
    print(colnames(df))
    df$Lat<-as.numeric(df$Lat)
    df$Lon<-as.numeric(df$Lon)
    df$Date<-strptime(df$Date,"%Y-%m-%dT%H:%M:%S")
    df$Value<-as.numeric(df$Value)
    
    if(input$collection=="AirTemperature"){
      maxValue=30
      colValue="orange"
      legendTitle="Air Temperature"
    }

    if(input$collection=="DissolvedOxygen"){
      maxValue=100
      colValue="cornflowerblue"
      legendTitle="Dis. Oxygen"
    }
 
    if(input$collection=="DroughtCode"){
      maxValue=300
      colValue="cornflowerblue"
      legendTitle="Drought Code"
    }
    
    
    if(input$collection=="Flow"){
      maxValue=4000
      colValue="blue"
      legendTitle="Flow m3/s"
    }
    
    if(input$collection=="FlowDistribution"){
        maxValue=100
        colValue="blue"
        legendTitle="Flow Distribution"
    }
    
    if(input$collection=="Humidity"){
      maxValue=100
      colValue="bisque3"
      legendTitle="Humidity"
    }
    
    if(input$collection=="Rainfall"){
      maxValue=500
      colValue="blue"
      legendTitle="Rainfall"
    }
    
    if(input$collection=="zVirtual Rainfall"){
      maxValue=500
      colValue="blue"
      legendTitle="Rainfall"
    }
   
    if(input$collection=="SoilMoisture"){
      maxValue=40
      colValue="brown"
      legendTitle="Soil Moisture"
    }
    
    if(input$collection=="DroughtCode"){
      maxValue=800
      colValue="brown"
      legendTitle="Drought Code"
    }
    
    if(input$collection=="FireWeatherIndex"){
      maxValue=50
      colValue="red"
      legendTitle="Fire Weather Index"
    }
    
    if(input$collection=="Turbidity"){
      maxValue=100
      colValue="burlywood4"
      legendTitle="Turbidity NTU"
    }
    
    if(input$collection=="WaterMatters"){
      maxValue=500
      colValue="blue"
      legendTitle="Flow"
    }
    
    
    
    #Resizing variable to a 0-100 range for plotting and putting this data into
    # df$StdValue column.
    df$StdValue<-(100/maxValue)*df$Value

    # If collection = Flow Distribution, symbol sizes show the scale of 100 - Flow percentile.
    # This makes low flow symbols small and high flow symbols large.
    if(input$collection=="FlowDistribution"){
      df$StdValue <- 100-df$StdValue
    }
    
    
    #===================================================================================================
    print(Sys.time()-a)
    # Define the markers:
    df.markers <- cbind.data.frame( lat=df$Lat, lon=df$Lon, 
                                    size=rep('tiny', length(df$Lat)), col=colors()[1:length(df$Lat)], 
                                    char=rep('',length(df$Lat)) )
    # Get the bounding box:
    bb <- qbbox(lat = df[,"Lat"], lon = df[,"Lon"])
    num.mirrors <- 1:dim(df.markers)[1] ## to visualize only a subset of the cran.mirrors
    maptype <- c("roadmap", "mobile", "satellite", "terrain", "hybrid", "mapmaker-roadmap", "mapmaker-hybrid")[as.numeric(input$basemap)]
    
    # Download the map (either jpg or png): 
    MyMap <- GetMap.bbox(bb$lonR, bb$latR, destfile = paste("Map_", maptype, ".png", sep=""), GRAYSCALE=F, maptype = maptype)
    # Plot:
    
  
    # Controlling symbol size
    symPower=input$intSymSize/10
    txtPower=0.009
    zeroAdd=0.05
    transp=0
    
  
    if(input$collection=="WaterMatters")
    {
    PlotOnStaticMap(MyMap,lat = df.markers[num.mirrors,"lat"], lon = df.markers[num.mirrors,"lon"], 
                      cex=((df$StdValue)+zeroAdd)^symPower, col=rgb(0,0,200,50,maxColorValue=255), pch=16, add=F)
      
    } else {
    PlotOnStaticMap(MyMap,lat = df.markers[num.mirrors,"lat"], lon = df.markers[num.mirrors,"lon"], 
                    cex=((df$StdValue)+zeroAdd)^symPower, pch=19, col=colValue, add=F)
    }
    if(input$showPointLabels=="Yes")
    {
      TextOnStaticMap(MyMap,lat = df.markers[num.mirrors,"lat"], lon = df.markers[num.mirrors,"lon"], 
                    cex=(df$Value)^txtPower, labels=as.character(round(df$Value,0)), col="white", add=T)
    } else {
      ## turn legend on if label not chosen
      legend(x=-310,y=278, c("Low","Medium","High"), title=legendTitle, pch=c(20), cex=1.2,
             pt.cex=c((5+zeroAdd)^symPower,(50+zeroAdd)^symPower,(95+zeroAdd)^symPower), text.col="white", bty="n", col=colValue, y.intersp=1.2)
      
    }

    ## Coloured Rect for Title
    rect(-320,280,320,320,col="cornflowerblue")
    

    ##==========================================    
    ## Requires pixmap package
    hrclogo<-read.pnm("hrclogo_small.pnm")
    addlogo(hrclogo,c(-290,-190),c(-200,-130))
    ##==========================================    
    
    text(0,300,labels=c(input$plotTitle),cex=2.5, col="white")
    text(0,-300,labels=c("Horizons Regional Council Disclaimer Applies"),cex=0.7)

    print(Sys.time()-a)
  })
  
  # Generate a summary of the data
  output$summary <- reactivePrint(function() {
    a<-Sys.time()
    ## Calculating the endDate of the data to retrieve based on
    ## selected interval
    
    fromDate<-strptime(input$fromdate,"%Y-%m-%d")

    ##
   
   if(input$interval=="1 hour") {
      
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh+1
      addDay <- 0
      if(hhEnd>24){
          hhEnd <- hhEnd - 24
	 addDay <- 86400
      }
      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

      } else if (input$interval=="3 hours") {
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh+3
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
	 addDay <- 86400
      }

      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

      } else if (input$interval=="12 hours") {
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh+12
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
	 addDay <- 86400
      }

      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

      } else if (input$interval=="6 hours") {
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh+6
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
	 addDay <- 86400
      }

      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

     } else if (input$interval=="24 hours") {
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh
      addDay <- 86400

      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

      } else {
      endTime<-input$fromhour
      ## next line required to do date calculations below
      d <- as.POSIXlt(fromDate)
      
      if(input$interval=="1 day") {
        
        d$mday <- d$mday+1
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="2 days") {
        
        d$mday <- d$mday+2
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="3 days") {
        
        d$mday <- d$mday+3
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="4 days") {
        
        d$mday <- d$mday+4
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="5 days") {
        
        d$mday <- d$mday+5
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="6 days") {
        
        d$mday <- d$mday+6
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if (input$interval=="1 week") {

        d$mday <- d$mday+7
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if  (input$interval=="1 month") {
      
        d$mon <- d$mon+1
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      }  else if  (input$interval=="3 months") {

        d$mon <- d$mon+3
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if  (input$interval=="6 months") {
        
        d$mon <- d$mon+6
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if  (input$interval=="12 months") {
        
        d$year<- d$year+1
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      }
    }

    if(input$collection=="zVirtual Rainfall"){
	htsName <- "SubcatchmentRain"
    } else {
	htsName <- "boo"
    }
    htsURL<-paste("http://",HSERVER,".horizons.govt.nz/",htsName,".hts?service=Hilltop&request=GetData&Collection=",input$collection,"&From=",input$fromdate," ",input$fromhour,"&To=",endDate," ",endTime,"&interval=",input$interval,"&Method=",input$method,sep="")
        
    print(Sys.time()-a)
    
    getData.xml <- xmlInternalTreeParse(htsURL)
    
    site.attr<-getNodeSet(getData.xml,"//E[2]/../../@SiteName")
    site.list<-sapply(site.attr, as.character)
    
    data.date <- sapply(getNodeSet(getData.xml, "//Hilltop/Measurement/Data/E[2]/../E[1]/T"), xmlValue)
    data.value <- sapply(getNodeSet(getData.xml, "//Hilltop/Measurement/Data/E[2]/I1"), xmlValue)
    
    dd<-data.frame(site.list,data.date,data.value, stringsAsFactors=FALSE)
 
    ## ===============================================================================
    
    ## ===============================================================================
    ## ===============================================================================
    ## Merging Data For Mapping
    df<-as.data.frame(merge(ds,dd,by=c("site.list","site.list")))
    
    colnames(df)<-c("SiteName","Lat","Lon","Date","Value")
    
    df$Lat<-as.numeric(df$Lat)
    df$Lon<-as.numeric(df$Lon)
    df$Date<-strptime(df$Date,"%Y-%m-%dT%H:%M:%S")
    df$Value<-as.numeric(df$Value)
    print(htsURL)
    summary(df[ ,c(1,4,5)])
  })
  
  # Generate an HTML table view of the data
  output$table <- reactiveTable(function() {
    a<-Sys.time()
    ## Calculating the endDate of the data to retrieve based on
    ## selected interval
    
    fromDate<-strptime(input$fromdate,"%Y-%m-%d")

    ##
   
   if(input$interval=="1 hour") {
      
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh+1
      addDay <- 0
      if(hhEnd>24){
          hhEnd <- hhEnd - 24
	 addDay <- 86400
      }
      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

      } else if (input$interval=="3 hours") {
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh+3
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
	 addDay <- 86400
      }

      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

      } else if (input$interval=="12 hours") {
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh+12
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
	 addDay <- 86400
      }

      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

      } else if (input$interval=="6 hours") {
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh+6
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
	 addDay <- 86400
      }

      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

     } else if (input$interval=="24 hours") {
      hh <- as.numeric(substr(input$fromhour,1,2))
      hhEnd<-hh
      addDay <- 86400

      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay

      } else {
      endTime<-input$fromhour
      ## next line required to do date calculations below
      d <- as.POSIXlt(fromDate)
      
      if(input$interval=="1 day") {
        
        d$mday <- d$mday+1
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="2 days") {
        
        d$mday <- d$mday+2
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="3 days") {
        
        d$mday <- d$mday+3
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="4 days") {
        
        d$mday <- d$mday+4
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="5 days") {
        
        d$mday <- d$mday+5
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(input$interval=="6 days") {
        
        d$mday <- d$mday+6
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if (input$interval=="1 week") {

        d$mday <- d$mday+7
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if  (input$interval=="1 month") {
      
        d$mon <- d$mon+1
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      }  else if  (input$interval=="3 months") {

        d$mon <- d$mon+3
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if  (input$interval=="6 months") {
        
        d$mon <- d$mon+6
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if  (input$interval=="12 months") {
        
        d$year<- d$year+1
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      }
    }
    
     if(input$collection=="zVirtual Rainfall"){
	htsName <- "SubcatchmentRain"
    } else {
	htsName <- "boo"
    }
    htsURL<-paste("http://",HSERVER,".horizons.govt.nz/",htsName,".hts?service=Hilltop&request=GetData&Collection=",input$collection,"&From=",input$fromdate," ",input$fromhour,"&To=",endDate," ",endTime,"&interval=",input$interval,"&Method=",input$method,sep="")
    
 
    print(Sys.time()-a)
    
    getData.xml <- xmlInternalTreeParse(htsURL)
    
    site.attr<-getNodeSet(getData.xml,"//E[2]/../../@SiteName")
    site.list<-sapply(site.attr, as.character)
    
    data.date <- sapply(getNodeSet(getData.xml, "//Hilltop/Measurement/Data/E[2]/../E[1]/T"), xmlValue)
    data.value <- sapply(getNodeSet(getData.xml, "//Hilltop/Measurement/Data/E[2]/I1"), xmlValue)
    
    dd<-data.frame(site.list,data.date,data.value, stringsAsFactors=FALSE)
    ## ===============================================================================
    
    ## ===============================================================================
    ## ===============================================================================
    ## Merging Data For Mapping
    df<-as.data.frame(merge(ds,dd,by=c("site.list","site.list")))
    
    colnames(df)<-c("SiteName","Lat","Lon","Date","Value")
    
    df$Lat<-as.numeric(df$Lat)
    df$Lon<-as.numeric(df$Lon)
    df$Date<-strptime(df$Date,"%Y-%m-%dT%H:%M:%S")
    df$Value<-as.numeric(df$Value)
    print(htsURL)
    data.frame("Site"=df[,1],"Value"=df[,5],"Lat"=df[,2],"Lon"=df[,3])
  })

})
