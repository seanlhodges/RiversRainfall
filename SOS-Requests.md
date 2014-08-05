# Using SOS 2.0 to access time-series data
August 5, 2014  

##Introduction
Accessing data from other organisations has traditionally required the physical transfer of data. Data is moved using common file formats as defacto encodings (for example, fixed format text, delimited text or Excel files). The structure of data stored within the file format is based on presentation. Generally, there is a need to explain the method of presentation to the consumer. This is compounded when requesting data from many organisations - with no generally accepted uniform way to provide data, subtle or substantive differences in data presentation will occur (even when requests are relatively simple). The resulting back-and-forth explanation of data presentation has long been the bane of both the data provider and the data consumer - it is left up the consumer to piece it all together.

In the geospatial world, recognising that there were a range of different software vendors with different encoding formats, standardised specificaions were established by the Open Geospatial Consortium (OGC), allowing data to be exchanged in a platform-neutral manner. It was then up to individual GIS/mapping clients to interpret platform-neutral content and demonstrate compliance with open specifications.

Recently, work has been completed that allows time-series data to adopt this approach for data sharing. The introduction of request (SOS 2.0) and response (WaterML 2.0) specifications by the OGC allows software clients to adopt a common framework, simplifying data exchange. In the New Zealand context, the implication organisations publishing **water** data this way potentially allows for aggregation of data **across** organisation boundaries. Extending this to other domains (biodiversity, biosecurity, land, air, coast) has the potential to revolutionise public access to a wide range of previously hard to access information.

To date, there are six NZ agencies that have OGC-compliant systems for sharing time-series data - Northland RC, Waikato RC, Horizons RC, Marlborough DC, ECan, Environment Southland & NIWA - with more coming online as systems are updated. A lot of activity has occurred over the last 12 months in space, with two main drivers:

1. LAWA (http://www.lawa.org.nz),  where, the Regional Council Chief Executives  and Chairs have agreed to make data available for consumption through the LAWA website. 
2. CRI's investing in systems specialising in environmental data discovery and delivery.

The net result is that a critical mass of agencies adopting OGC specifications for data exchange in the environmental domains has been achieved. While other mechanisms for data exchange are also available (but platform dependent eg. Kisters Query Service), the acceptance of OGC as providing the core data exchange specification is a significant step in improving data exchange to support the delivery of portals such as LAWA.

For this document, five of the above listed agencies are accessed using the OGC specifications to demonstrate how a cross-agency data summary might be constructed. The approach taken is as follows:
1. Aggregate location information across selected agencies, creating `featureOfInterest` reference data.
2. From an *a priori* list, determine whether an `observedProperty` has any data available for a specific locatoin (the equivalent of a GetDataAvailability call, but without date range);
3. Retrieve the last recorded data value from each `observedProperty` (and `procedure` where required) for the `featureOfInterest` determined at step 1.
4. Make a simple table to summarise responses
5. Make a map of values


##Methods
The R code this document assumes the following OGC request and data format standards are supported:

- WFS 1.1.0 to encode location (requires valid `<gml:pos>` element - no assumption is made about data schema)
- SOS 2.0 requests (the `GetObservation` request is supported *without* `temporalFilter` argument. It is intended to add this at a later date)
- WaterML 2.0 encoded data responses (requires valid `<wml2:time>` & `<wml2:value>` elements)

Some error checking is undertaken. Sites are exluded where location coordinates are not available or coordinates do not fall near NZ. Order of Lat-lon values has been considered for different implementations. Coordinates may fall outside NZ where servers have not been correctly configured to handle projections. Server maintainers may be notified where this is discovered. Finally, where an exception reports or other unexpected responses are returned from SOS requests, a `tryCatch()` approach has been adopted to ensure code execution is not interrupted..


##Demonstrated federated data access using R
[R](http://R-project.org/), a language and environment for statistical computing, is being used to demonstrated federated data access.

The R code chunks below set up data access to each Council and pulls time-series data via SOS-based requests. Some of the requests used below are easier to implement in the host systems native RESTful services, but this would defeat the purpose of this document. Federation of water data, based on OGC specifications, is the key component to implementing a common set of rules for engangement between agencies.

The demonstration that follows is a trivial use-case of showing the last recorded value for discharge at a water-level monitoring site. In undertaking this exercise, evaluation of using OGC specifications for a request/response framework can be undertaken.

###Loading libraries


```r
library(XML)
library(sp)
library(RgoogleMaps)
library(googleVis)
```

```
## Warning: package 'googleVis' was built under R version 3.1.1
```

```
## 
## Welcome to googleVis version 0.5.4
## 
## Please read the Google API Terms of Use
## before you start using the package:
## https://developers.google.com/terms/
## 
## Note, the plot method of googleVis will by default use
## the standard browser to display its output.
## 
## See the googleVis package vignettes for more details,
## or visit http://github.com/mages/googleVis.
## 
## To suppress this message use:
## suppressPackageStartupMessages(library(googleVis))
```



###Build reference data
**Site table**
The first step is to build a list of sites where environmental data are recorded. Accessing the WFS services and requesting a list of sites (`service=WFS&request=GetFeature&typename=<provider specific name>`) enables this list of sites to be created. 

Limitation: Schemas are potentially different across servers, so the simple approach here is to simply retrieve the lat/long data and hard code the call to retrieve the site name that will be used later to retrieve data via the SOS request.

Defining a schema for site data, based on terms used by SOS, would simplify compilation of reference data.


```r
#===================================================================================================
# INIT Settings
source("SOS_Ref.R")

USE_CACHE_SITES <- TRUE# Scan WFS endpoints
USE_CACHE_GDA   <- TRUE  # GetDataAvailability
# Council SOS domain addresses
# These addresses are currently the property of their respective councils. Please request permission 
# from respective Hydrology teams to use the data from their servers
servers <- c("http://hilltop.nrc.govt.nz/data.hts?",
             "http://envdata.waikatoregion.govt.nz:8080/KiWIS/KiWIS?datasource=0&",
             "http://hilltopserver.horizons.govt.nz/data.hts?",
             "http://hydro.marlborough.govt.nz/data.hts?",
             "http://odp.es.govt.nz/data.hts?")

## ===============================================================================
## Getting Site Data - THIS SHOULD ONLY BE RUN DAILY IN ITS CURRENT FORM
## KiWIS Servers and Hilltop Servers take slighty different approaches
## to serving WFS.

## KISTERS
## http://envdata.waikatoregion.govt.nz:8080/KiWIS/KiWIS?datasource=0&service=WFS&request=GetFeature&typename=KiWIS:Station&version=1.1.0

## HILLTOP
## http://hilltopserver.horizons.govt.nz/data.hts?service=WFS&request=GetFeature&typename=SiteList

## For simplicities sake, unique WFS calls will be defined for each agency
wfs <- c("http://hilltop.nrc.govt.nz/data.hts?service=WFS&request=GetFeature&typename=SiteList",
         "http://envdata.waikatoregion.govt.nz:8080/KiWIS/KiWIS?datasource=0&service=WFS&request=GetFeature&typename=KiWIS:Station&version=1.1.0",
         "http://hilltopserver.horizons.govt.nz/data.hts?service=WFS&request=GetFeature&typename=SiteList",
         "http://hydro.marlborough.govt.nz/data.hts?service=WFS&request=GetFeature&typename=SiteList",
         "http://odp.es.govt.nz/data.hts?service=WFS&request=GetFeature&typename=SiteList")

wfs_site_element <- c("Site","KiWIS:station_no","Site","Site","Site")


if(USE_CACHE_SITES){
    ## Load the one prepared earlier
    load("dfSitesCouncils.Rdata")
    #ds <- dfsites
    
} else{
    # For each council server specified...
    # Assumption is that gml:pos has coordinates recorded in lat,lon order
    for(i in 1:length(wfs)){
                     
        #cat(wfs[i],"\n")
        # Code is susceptible to loss of web services (HTTP 503 errors will stop code execution)
        # The tryCatch() approach will enable the code to continue running, but at the expense
        # of lost services. This may have unintended consequences.
        getSites.xml <- xmlInternalTreeParse(wfs[i])
        
         # In WFS, the <Site> element value is the sitename
        site.list<-sapply(getNodeSet(getSites.xml,paste("//gml:pos/../../../",wfs_site_element[i],sep="")),xmlValue)
        
        # In WFS, lat lon are specified as the value in the <gml:pos> element, separated by a single space.
        data.latlon <- sapply(getNodeSet(getSites.xml,"//gml:pos"),xmlValue)
        latlon <- sapply(strsplit(data.latlon," "),as.numeric)
        
        ## Lats and Longs are stored in a different order for waikatoregion service
        ## Reverse association for this Waikato
        if(i!=2){
            data.lat <- latlon[1,]
            data.lon <- latlon[2,]
        } else {
            data.lat <- latlon[2,]
            data.lon <- latlon[1,]
        }
        
        # bind rows together from successive loops
        if(i==1){
            ds <-data.frame(site.list,data.lat,data.lon,Sys.time(), stringsAsFactors=FALSE)
            ds$source <- servers[i]
        } else {
            ds1 <-data.frame(site.list,data.lat,data.lon,Sys.time(), stringsAsFactors=FALSE)
            ds1$source <- servers[i]
        
            ds <- rbind(ds,ds1)
        }

    }
    
    rm(ds1,data.lat,data.lon,latlon,data.latlon,site.list,getSites.xml,i)
    names(ds) <- c("SiteName","Lat","Lon","lastrun","source")
    # removing resource consent flow monitoring sites
    ds <- subset(ds,substr(ds$SiteName,1,3) !="RC_")
    # Remove site with strange latlon values
    ds <- ds[-2,]
    save(ds,file="dfSitesCouncils.Rdata")

}
```

**Site Map**
A quick map to show the what reference data has been constructed. A tabular summary of Council and number of sites would also be useful here.
![plot of chunk MakeASiteMap](./SOS-Requests_files/figure-html/MakeASiteMap.png) 

**GetDataAvailability**
With a valid list of sites, the next step is to establish what data is available. A `GetDataAvailability` call against a SOS server would be convenient. However, for those servers not currently supporting this call, a slightly longer process is required to *discover* what is avialable. The only pre-condition is that the names of the `observedProperty` can be determined by other means beforehand. For this purposes of this example, the following `observedProperty` values have been chosen: Flow, Rainfall, Water Temperature.

The example below could be modified to return valid date ranges for the `observedProperty`'s in question if necessary.



```r
# Measurements to scan
# These are locally defined terms. Alternatives may be Discharge, Precipitation
measurements <- c("Flow")

## GetDataAvailability for each measurement
if(USE_CACHE_GDA){
    cat("Loading cached data ...\n")
    load("dsmMeasurements.Rdata")
    
} else {
    dsm <- rcData(ds,measurements)
    save(dsm,file="dsmMeasurements.Rdata")
    
}
```

```
## Loading cached data ...
```

```r
# Just select sites that have  flow data
ds_flow <- subset(dsm,dsm$Flow == "OK")
#ds_rain <- subset(dsm,dsm$Rainfall == "OK")

## ===============================================================================
## Getting Measurement Data for Mapping.
## For each site that has measurement data, get the last value ...

#df_flow <- rcLastTVP(ds_flow,"Flow")

df <-ds_flow
measurement <- "Flow"

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

# Housekeeping
rm(wml2_Time,wml2_Value,xmltop)
```


###Make a map


![plot of chunk MakeAFlowMap](./SOS-Requests_files/figure-html/MakeAFlowMap.png) 
