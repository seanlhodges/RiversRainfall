## FUNCTION LIBRARY
## 28-Jul-2014 

## RELATED FILES
## SOS-Requests.Rmd
## server_sites_from_wfs.R

#####################################################################################
## RUN ONCE - PoorMans GetDataAvailability
## For each measurement in the vector below, it's taking approximately 7 minutes to 
## scan across every site (with a location) provided by the three Councils.
## This is not sustainable in the long run.
## There is a need to have a collection implementation with the SOS standard so that
## grouped data can all be returned at once. Accessing each individual site is
## just too slow.
#####################################################################################

rcData <- function(ds,measurements){
  
  for(m in 1:length(measurements)){
    for(i in 1:length(ds[,1])){
      
        if(substrRight(ds$source[i],1)=="&"){
            
            ## Using some Kister and Waikato specific KVP's
            SOS_url <- paste(ds$source[i],"service=SOS&version=2.0",
                             "&request=GetObservation",
                             "&featureOfInterest=",ds$SiteName[i],
                             "&procedure=Cmd.P",
                             "&observedProperty=Discharge",
                             sep="")
        } else{
            ## Using the minimal Hilltop KVPs
            SOS_url <- paste(ds$source[i],"service=SOS",
                             "&request=GetObservation",
                             "&featureOfInterest=",ds$SiteName[i],
                             "&observedProperty=",measurements[m],
                             sep="")
        }  
        
        SOS_url <- gsub(" ","%20",SOS_url)

      cat(SOS_url,"\n")
      err.attr <- c("")
      err.list <- c("OK")
      result = tryCatch({
        getData.xml <- xmlInternalTreeParse(SOS_url)
        }, warning = function(w) {
          
        }, error = function(e) {
          err.list <- c("NoData")
        }, finally = {
         xmltop <- xmlRoot(getData.xml)
         
        if(xmlName(xmltop)=="ExceptionReport"){
             err.attr<-getNodeSet(getData.xml,"//ows:Exception/@exceptionCode")
             err.list<-sapply(err.attr, as.character)
        }
         
      })
      
      
      if(i==1){
        a <- c(err.list)
      } else {
        b <- c(err.list)
        a <- c(a,b)
      }
      
      rm(err.attr,err.list)
    }
    
    
    #Append each measurements output vector to the data.frame as a new column
    ds[,length(ds)+1] <- a  ### Add flag for sites that record requested measurement
    colnames(ds)[length(ds)] <-  measurements[m]
    #ds <- ds[,1:6]
  }
  
  #ds_flow <- subset(ds,ds$Flow == "OK")
  #ds_rain <- subset(ds,ds$Rainfall == "OK")
  
  return(ds)
}


#####################################################################################
## RUN ONCE - PoorMans Hilltop GetData based on a collection
##            Function runs against an individual measurement, 
##            rather than a vector of values. Might change this
#####################################################################################

rcLastTVP <- function(df,measurement){
    
    for(i in 1:length(df[,1])){
        
        if(substrRight(df$source[i],1)=="&"){
            
            ## Using some Kister and Waikato specific KVP's
            SOS_url <- paste(df$source[i],"service=SOS&version=2.0",
                             "&request=GetObservation",
                             "&featureOfInterest=",df$SiteName[i],
                             "&procedure=Cmd.P",
                             "&observedProperty=Discharge",
                             sep="")
        } else{
            ## Using the minimal Hilltop KVPs
            SOS_url <- paste(df$source[i],"service=SOS",
                             "&request=GetObservation",
                             "&featureOfInterest=",df$SiteName[i],
                             "&observedProperty=",measurement,
                             sep="")
        }  
        
        SOS_url <- gsub(" ","%20",SOS_url)
        
        #Waikato Kisters request for river flow
        # http://envdata.waikatoregion.govt.nz:8080/KiWIS/KiWIS?datasource=0&service=SOS&version=2.0
        #                   &request=GetObservation
        #                   &featureOfInterest=64
        #                   &procedure=Cmd.P
        #                   &observedProperty=Discharge
        #                   &temporalFilter=om:phenomenonTime,2014-01-28T15:00:00/2014-01-29T15:00:00
        
        
        #Waikato Kisters request for Precipitation
        # http://envdata.waikatoregion.govt.nz:8080/KiWIS/KiWIS?datasource=0&service=SOS&version=2.0
        #                   &request=GetObservation
        #                   &featureOfInterest=21
        #                   &procedure=CmdTotal.P
        #                   &observedProperty=Precipitation
        #                   &temporalFilter=om:phenomenonTime,2014-01-28T15:00:00/2014-01-29T15:00:00
        
        
        #cat(SOS_url,"\n")
        
        result = tryCatch({
            getData.xml <- xmlInternalTreeParse(SOS_url)
            
        }, warning = function(w) {
            
        }, error = function(e) {
            if(i==1){
                wml2Time <- NA
                wml2Value <- NA
            } else {
                wml2Time1 <- NA
                wml2Value1 <- NA
                
                wml2Time <- c(wml2Time,wml2Time1)
                wml2Value <- c(wml2Value,wml2Value1) 
            } 
            
        }, finally = {
            xmltop <- xmlRoot(getData.xml)
            
            if(xmlName(xmltop)!="ExceptionReport"){
                if(length(getNodeSet(getData.xml,"//wml2:point"))!=0){
                    wml2time<-sapply(getNodeSet(getData.xml,"//wml2:time"),xmlValue)[1]
                    wml2value<-sapply(getNodeSet(getData.xml,"//wml2:value"),xmlValue)[1]
                    #cat(wml2time,"\n")
                    #cat(wml2value,"\n")
                } else {wml2time<-NA
                        wml2value<-NA}
            }
            
            if(i==1){
                wml2_Time <- wml2time
                wml2_Value <-as.numeric(wml2value)
                ## Horizons stores flow as L/s. Others store it as m3/s. The following line adusts Horizons value
                if(df$source[i]=="http://hilltopserver.horizons.govt.nz/data.hts?"){wml2_Value <- wml2_Value/1000}
                ## Recoding negative values to NA
                if(!anyNA(wml2_Value)){
                    if(wml2_Value < 0){wml2_Value <- NA}
                }
                
            } else {
                wml2_Time1 <- wml2time
                wml2_Value1 <- as.numeric(wml2value)
                ## Horizons stores flow as L/s. Others store it as m3/s. The following line adusts Horizons value
                if(df$source[i]=="http://hilltopserver.horizons.govt.nz/data.hts?"){wml2_Value1 <- wml2_Value1/1000}
                ## Recoding negative values to NA
                if(!anyNA(wml2_Value1)){
                    if(wml2_Value1 < 0){wml2_Value1 <- NA}
                }
                
                wml2_Time <- c(wml2_Time,wml2_Time1)
                wml2_Value <- c(wml2_Value,wml2_Value1) 
                rm(wml2_Time1,wml2_Value1)
            }
            rm(SOS_url,wml2time,wml2value)
        })
        
    }
    
    
    ## Append each measurements output vector to the data.frame as a new column
    
    # DateTime inclusion and conversion to POSIXlt DateTime
    df[,length(df)+1] <- wml2_Time  ### Add wml2Time
    colnames(df)[length(df)] <-  c("DateTime")
    df$DateTime<-strptime(df$DateTime,"%Y-%m-%dT%H:%M:%S")
    
    # Measurement value. Data type set to numeric when vector created.
    df[,length(df)+1] <- wml2_Value  ### Add wml2Value
    colnames(df)[length(df)] <-  c("Value")
        
    return(df)
}



##### FOR FUN
## Make a Map

MakeMap <- function(df){
    

    maxValue=4000
    colValue="blue"
    legendTitle="Flow m3/s"
    
    #Resizing variable to a 0-100 range for plotting and putting this data into
    # df$StdValue column.
    df$StdValue<-(100/maxValue)*100
    
    
    
    #===================================================================================================
    # Define the markers:
    df.markers <- cbind.data.frame( lat=df$Lat, lon=df$Lon, 
                                    size=rep('tiny', length(df$Lat)), col=colors()[1:length(df$Lat)], 
                                    char=rep('',length(df$Lat)) )
    # Get the bounding box:
    bb <- qbbox(lat = df[,"Lat"], lon = df[,"Lon"])
    num.mirrors <- 1:dim(df.markers)[1] ## to visualize only a subset of the cran.mirrors
    maptype <- c("roadmap", "mobile", "satellite", "terrain", "hybrid", "mapmaker-roadmap", "mapmaker-hybrid")[4]
    
    # Download the map (either jpg or png): 
    MyMap <- GetMap.bbox(bb$lonR, bb$latR, destfile = paste("Map_", maptype, ".png", sep=""), GRAYSCALE=F, maptype = maptype)
    # Plot:
    
    
    # Controlling symbol size
    symPower=2/10
    txtPower=0.009
    zeroAdd=0.05
    transp=0
    
    
    
    PlotOnStaticMap(MyMap,lat = df.markers[num.mirrors,"lat"], lon = df.markers[num.mirrors,"lon"], 
                    cex=((df$StdValue)+zeroAdd)^symPower, pch=19, col=colValue, add=F)
    
    
    ## Coloured Rect for Title
    rect(-320,280,320,320,col="cornflowerblue")
    
    text(0,300,labels=c("Stations"),cex=2.5, col="white")
    
}




TimeSeriesSlider <- function(df,stn,measurement,duration){

        
        if(substrRight(df$source[stn],1)=="&"){
            
            ## Using some Kister and Waikato specific KVP's
            SOS_url <- paste(df$source[stn],"service=SOS&version=2.0",
                             "&request=GetObservation",
                             "&featureOfInterest=",df$SiteName[stn],
                             "&procedure=Cmd.P",
                             "&observedProperty=Discharge",
                             sep="")
        } else{
            ## Using the minimal Hilltop KVPs
            SOS_url <- paste(df$source[stn],"service=SOS",
                             "&request=GetObservation",
                             "&featureOfInterest=",df$SiteName[stn],
                             "&observedProperty=",measurement,
                             sep="")
        }  
        
        # Adding temporalFilter to SOS call
        #SOS_url <- paste(SOS_url,"&temporalFilter=om:phenomenonTime",duration)
        SOS_url <- paste(SOS_url,"&temporalFilter=om:phenomenonTime,",duration,sep="")
        
        #Replacing spaces with %20 in url
        SOS_url <- gsub(" ","%20",SOS_url)    
        cat(SOS_url,"\n")
        
        result = tryCatch({
            getData.xml <- xmlInternalTreeParse(SOS_url)
            
        }, warning = function(w) {
            
        }, error = function(e) {
            
            wml2Time <- NA
            wml2Value <- NA 
            
        }, finally = {
            xmltop <- xmlRoot(getData.xml)
            
            if(xmlName(xmltop)!="ExceptionReport"){
                if(length(getNodeSet(getData.xml,"//wml2:point"))!=0){
                    wml2time<-sapply(getNodeSet(getData.xml,"//wml2:time"),xmlValue)
                    wml2value<-sapply(getNodeSet(getData.xml,"//wml2:value"),xmlValue)
                } else {wml2time<-NA
                        wml2value<-NA
                }
            }
            
            wml2_Time <- wml2time
            wml2_Value <-as.numeric(wml2value)
            ## Horizons stores flow as L/s. Others store it as m3/s. The following line adusts Horizons value
            if(df$source[stn]=="http://hilltopserver.horizons.govt.nz/data.hts?"){wml2_Value <- wml2_Value/1000}
            ## Recoding negative values to NA
            if(!anyNA(wml2_Value)){
                if(wml2_Value < 0){wml2_Value <- NA}
            }
            
        })
        
        # data review
        df_PxD <- data.frame(wml2_Time,wml2_Value)
        names(df_PxD) <- c("Date","Value")
        df_PxD$Date <- strptime(df_PxD$Date,format="%Y-%m-%dT%H:%M:%S")
        summary(df_PxD)
        
        # gvisChart of some sort
        AnnoTimeLine  <- gvisAnnotatedTimeLine(df_PxD, 
                                               datevar="Date",
                                               numvar="Value", 
                                               options=list(displayAnnotations=FALSE,
                                                            width="600px", height="350px"))
        plot(AnnoTimeLine)
            
}

USGS_chart <- function(url){
        
    result = tryCatch({
        getData.xml <- xmlInternalTreeParse(url)
        
    }, warning = function(w) {
        
    }, error = function(e) {
        
        wml2Time <- NA
        wml2Value <- NA 
        
    }, finally = {
        xmltop <- xmlRoot(getData.xml)
        
        if(xmlName(xmltop)!="ExceptionReport"){
            if(length(getNodeSet(getData.xml,"//wml2:point"))!=0){
                wml2time<-sapply(getNodeSet(getData.xml,"//wml2:time"),xmlValue)
                wml2value<-sapply(getNodeSet(getData.xml,"//wml2:value"),xmlValue)
            } else {wml2time<-NA
                    wml2value<-NA
            }
        }
        
        wml2_Time <- wml2time
        wml2_Value <-as.numeric(wml2value)
        ## Recoding negative values to NA
        if(!anyNA(wml2_Value)){
            if(wml2_Value < 0){wml2_Value <- NA}
        }
        
    })
    
    # data review
    df_PxD <- data.frame(wml2_Time,wml2_Value)
    names(df_PxD) <- c("Date","Value")
    df_PxD$Date <- strptime(df_PxD$Date,format="%Y-%m-%dT%H:%M:%S")
    
    # gvisChart of some sort
    AnnoTimeLine  <- gvisAnnotatedTimeLine(df_PxD, 
                                           datevar="Date",
                                           numvar="Value", 
                                           options=list(displayAnnotations=FALSE,
                                                        width="600px", height="350px"))
    plot(AnnoTimeLine)
    
}

MakeAFlowMap <- function(df){
    
    df <- na.omit(df)
    
    # Setting variables that specify how map output will be displayed
    maxValue=4000
    colValue="royalblue"
    legendTitle="Flow m3/s"
    
    
    #Resizing variable to a 0-100 range for plotting and putting this data into
    # df$StdValue column.
    df$StdValue<-(100/maxValue)*df$Value
    
    #===================================================================================================
    # Define the markers:
    df.markers <- cbind.data.frame( lat=df$Lat, lon=df$Lon, 
                                    size=rep('tiny', length(df$Lat)), col=colors()[1:length(df$Lat)], 
                                    char=rep('',length(df$Lat)) )
    # Get the bounding box:
    bb <- qbbox(lat = df[,"Lat"], lon = df[,"Lon"])
    num.mirrors <- 1:dim(df.markers)[1] ## to visualize only a subset of the cran.mirrors
    maptype <- c("roadmap", "mobile", "satellite", "terrain", "hybrid", "mapmaker-roadmap", "mapmaker-hybrid")[4]
    
    # Download the map (either jpg or png): 
    MyMap <- GetMap.bbox(bb$lonR, bb$latR, destfile = paste("Map_", maptype, ".png", sep=""), GRAYSCALE=F, maptype = maptype)
    # Plot:
    
    
    # Controlling symbol size
    symPower=2/10
    txtPower=0.009
    zeroAdd=0.05
    transp=0
    
    
    
    PlotOnStaticMap(MyMap,lat = df.markers[num.mirrors,"lat"], lon = df.markers[num.mirrors,"lon"], 
                    cex=((df$StdValue)+zeroAdd)^symPower, pch=19, col=colValue, add=F)
    
    
    showPointLabels <- "No"
    #if(showPointLabels=="Yes")
    #{
    #  TextOnStaticMap(MyMap,lat = df.markers[num.mirrors,"lat"], lon = df.markers[num.mirrors,"lon"], 
    #                cex=(df$Value)^txtPower, labels=as.character(round(df$Value,0)), col="white", add=T)
    #} else {
    #  ## turn legend on if label not chosen
    #  legend(x=-310,y=278, c("Low","Medium","High"), title=legendTitle, pch=c(20), cex=1.2,
    #         pt.cex=c((5+zeroAdd)^symPower,(50+zeroAdd)^symPower,(95+zeroAdd)^symPower), text.col="white", bty="n", col=colValue, y.intersp=1.2)
    #  
    #}
    
    ## Coloured Rect for Title
    rect(-320,280,320,320,col="cornflowerblue")
    
    
    ##==========================================    
    ## Requires pixmap package
    #hrclogo<-read.pnm("hrclogo_small.pnm")
    #addlogo(hrclogo,c(-290,-190),c(-200,-130))
    ##==========================================    
    
    text(0,300,labels=c("Flow stations"),cex=2.5, col="white")
    text(0,-300,labels=c("Horizons Regional Council Disclaimer Applies"),cex=0.7)
    
}




## String function to emulate excel function right()
substrRight <- function(x, n){
    substr(x, nchar(x)-n+1, nchar(x))
}
