library(shiny)
library(XML)
library(sp)
library(RgoogleMaps)
library(pixmap)

#===================================================================================================
# INIT Settings

runStatus <- FALSE    ## Pulling site and measurement information takes time.
                      ## The WFS Scan and site table build only need be run
                      ## As new councils are added, or on a nightly basis to
                      ## update the data in the reference table.

# Council SOS domain addresses
servers <- c("http://hilltop.nrc.govt.nz/","http://hilltopserver.horizons.govt.nz/","http://hydro.marlborough.govt.nz/")
wfs_url <- c("data.hts?service=WFS&request=GetFeature&typename=SiteList")

# Measurements to scan
measurement <- c("Flow","Rainfall","Water Temperature")
## ===============================================================================
## Getting Site Data - THIS SHOULD ONLY BE RUN DAILY IN ITS CURRENT FORM

if(runStatus){
    # For each council server specified...
    # Assumption is that gml:pos has coordinates recorded in lat,lon order
    for(i in 1:length(servers)){
        getSites.xml <- xmlInternalTreeParse(paste(servers[i],wfs_url[1],sep=""))
        
        # In WFS, the <Site> element value is the sitename
        site.list<-sapply(getNodeSet(getSites.xml,"//gml:pos/../../../Site"),xmlValue)
        
        # In WFS, lat lon are specified as the value in the <gml:pos> element, separated by a single space.
        data.latlon <- sapply(getNodeSet(getSites.xml,"//gml:pos"),xmlValue)
        latlon <- sapply(strsplit(data.latlon," "),as.numeric)
        data.lat <- latlon[1,]
        data.lon <- latlon[2,]
        
        if(i==1){
            ds <-data.frame(site.list,data.lat,data.lon, stringsAsFactors=FALSE)
            ds$source <- servers[i]
        } else {
            ds1 <-data.frame(site.list,data.lat,data.lon, stringsAsFactors=FALSE)
            ds1$source <- servers[i]
    
            ds <- rbind(ds,ds1)
        }
    }
    rm(ds1,data.lat,data.lon,latlon,data.latlon,site.list,getSites.xml,i)
    names(ds) <- c("SiteName","Lat","Lon","source")
}

#------------------------------------------------------------
# Getting the data to match up with the site list
# The following requests, through the rcData function, are made using the SOS2.0 service

#dframe <- rcData(ds,measurement)
#dfsites <- ds[,1:4]
#dfsites <- dfsites[-2,]    # Dropping record with bad map ref
#save(dfsites,file="dfSitesCouncils.Rdata")

load("dfSitesCouncils.Rdata") # only needed for testing

## ===============================================================================
## Getting Measurement Data for Mapping.

## For each site that has flow data, get the last value ...

t <- Sys.time()
for(i in 1:length(df_flow[ ,1])){

    SOS_url <- paste(df_flow$source[i],"data.hts?service=SOS",
                     "&request=GetObservation",
                     "&featureOfInterest=",df_flow$SiteName[i],
                     "&observedProperty=Flow",
                     sep="")

    getData.xml <- xmlInternalTreeParse(SOS_url)
    xmltop <- xmlRoot(getData.xml)
     
    if(xmlName(xmltop)!="ExceptionReport"){
        data.date <- sapply(getNodeSet(getData.xml, "//wml2:time"),xmlValue)
        data.value <- sapply(getNodeSet(getData.xml, "//wml2:value"),xmlValue)
      
        if(i==1){
            dd<-data.frame(df_flow$SiteName[i],data.date,data.value, stringsAsFactors=FALSE)
        } else {
            dd1<-data.frame(df_flow$SiteName[i],data.date,data.value, stringsAsFactors=FALSE)
            dd <- rbind(dd,dd1)
        }
    }
}

names(dd) <- c("SiteName","Date","Value")
print(Sys.time() - t)

## ===============================================================================

## ===============================================================================
## Merging Data For Mapping
df<-as.data.frame(merge(ds,dd,by=c("SiteName","SiteName")))
#colnames(df)<-c("SiteName","Lat","Lon","Date","Value")
df$Lat<-as.numeric(df$Lat)
df$Lon<-as.numeric(df$Lon)
df$Date<-strptime(df$Date,"%Y-%m-%dT%H:%M:%S")
df$Value<-as.numeric(df$Value)

#if(input$collection=="Flow"){
  maxValue=4000
  colValue="blue"
  legendTitle="Flow m3/s"
#}

#if(input$collection=="Rainfall"){
#  maxValue=500
#  colValue="blue"
#  legendTitle="Rainfall"
#}

#Resizing variable to a 0-100 range for plotting and putting this data into
# df$StdValue column.
df$StdValue<-(100/maxValue)*df$Value

# If collection = Flow Distribution, symbol sizes show the scale of 100 - Flow percentile.
# This makes low flow symbols small and high flow symbols large.
#if(input$collection=="FlowDistribution"){
#  df$StdValue <- 100-df$StdValue
#}


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
}

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
hrclogo<-read.pnm("hrclogo_small.pnm")
addlogo(hrclogo,c(-290,-190),c(-200,-130))
##==========================================    

text(0,300,labels=c("Some random title"),cex=2.5, col="white")
text(0,-300,labels=c("Horizons Regional Council Disclaimer Applies"),cex=0.7)

