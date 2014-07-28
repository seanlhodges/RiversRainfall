#/*  -===Load required libraries=== */ 
# 
# These libraries will need to be installed within R first, otherwise
# the script will error and stop. The first couple of lines do the install
# if the libraries are not detected.
# */


#pkgs <- c('XML', 'RCurl','ggplot2','gridExtra','plyr','reshape2','RODBC','doBy')
#if(!all(pkgs %in% installed.packages()[, 'Package']))
#  install.packages(pkgs, dep = T)

#require(XML)        # XML library
#require(RCurl)
#require(reshape2)   # melt, cast, ...
#require(ggplot2)    # pretty plots ...
#require(gridExtra)
#require(plyr)
#require(RODBC)      # Database connectivity
#require(doBy)

#===================================================================================================
#/* -===Pseudo-Function prototypes===- 
#  A list of the required functions for this routine
#  Rather than taking a linear approach to scripting, a number of
#  functions will be defined to do key tasks
#*/

#// endDate <- function(){}
#
#===================================================================================================

#/* -===Function definitions===-  */


endDate <- function(interval,fromdate,fromhour){
  
##--------------------------------------------------------
## The time code below needs to be pushed to a function
##--------------------------------------------------------
    fromDate<-strptime(fromdate,"%Y-%m-%d")
    
    if(interval=="1 hour") {
      
      hh <- as.numeric(substr(fromhour,1,2))
      hhEnd<-hh+1
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
        addDay <- 86400
      }
      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay
      
    } else if (interval=="3 hours") {
      hh <- as.numeric(substr(fromhour,1,2))
      hhEnd<-hh+3
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
        addDay <- 86400
      }
      
      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay
      
    } else if (interval=="6 hours") {
      hh <- as.numeric(substr(fromhour,1,2))
      hhEnd<-hh+6
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
        addDay <- 86400
      }
      
      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay
      
    } else if (interval=="12 hours") {
      hh <- as.numeric(substr(fromhour,1,2))
      hhEnd<-hh+12
      addDay <- 0
      if(hhEnd>24){
        hhEnd <- hhEnd - 24
        addDay <- 86400
      }
      
      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay
      
    } else if (interval=="24 hours") {
      hh <- as.numeric(substr(fromhour,1,2))
      hhEnd<-hh
      addDay <- 86400
      
      endTime<-paste(hhEnd,":00:00",sep="")
      endDate<-fromDate + addDay
      
      
    } else {
      endTime<-fromhour
      ## next line required to do date calculations below
      d <- as.POSIXlt(fromDate)
      
      if(interval=="1 day") {
        
        d$mday <- d$mday+1
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(interval=="2 days") {
        
        d$mday <- d$mday+2
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(interval=="3 days") {
        
        d$mday <- d$mday+3
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(interval=="4 days") {
        
        d$mday <- d$mday+4
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(interval=="5 days") {
        
        d$mday <- d$mday+5
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if(interval=="6 days") {
        
        d$mday <- d$mday+6
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if (interval=="1 week") {
        
        d$mday <- d$mday+7
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if  (interval=="1 month") {
        
        d$mon <- d$mon+1
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      }  else if  (interval=="3 months") {
        
        d$mon <- d$mon+3
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if  (interval=="6 months") {
        
        d$mon <- d$mon+6
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      } else if  (interval=="12 months") {
        
        d$year<- d$year+1
        endDate <- format(as.Date(d),"%d-%b-%Y")
        
      }
    }
    
    t <- c(fromDate,endDate,endTime)
  
    return(t)

}
##--------------------------------------------------------
## The time code above needs to be pushed to a function
##--------------------------------------------------------



#####################################################################################
## RUN ONCE
## For each measurement in the vector below, it's taking approximately 7 minutes to 
## scan across every site (with a location) provided by the three Councils.
## This is not sustainable in the long run.
## There is a need to have a collection implementation with the SOS standard so that
## grouped data can all be returned at once. Accessing each individual site is
## just too slow.
#####################################################################################

rcData <- function(ds,measurements){
    
    for(m in 1:length(measurement)){
      for(i in 1:length(ds[,1])){
       
        SOS_url <- paste(ds$source[i],"data.hts?service=SOS",
                         "&request=GetObservation",
                         "&featureOfInterest=",ds$SiteName[i],
                         "&observedProperty=",measurement[m],
                         sep="")
        #cat(SOS_url,"\n")
        
        err.list <- c("OK")
        getData.xml <- xmlInternalTreeParse(SOS_url)
        xmltop <- xmlRoot(getData.xml)
        
        if(xmlName(xmltop)=="ExceptionReport"){
          err.attr<-getNodeSet(getData.xml,"//ows:Exception/@exceptionCode")
          err.list<-sapply(err.attr, as.character)
        }
        
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
      colnames(ds)[length(ds)] <-  measurement[m]
      #ds <- ds[,1:6]
    }
    
    #ds_flow <- subset(ds,ds$Flow == "OK")
    #ds_rain <- subset(ds,ds$Rainfall == "OK")
    
    return(ds)
}
