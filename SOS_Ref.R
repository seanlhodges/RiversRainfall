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


#####################################################################################
## RUN ONCE - PoorMans Hilltop GetData based on a collection
##            Function runs against an individual measurement, 
##            rather than a vector of values. Might change this
#####################################################################################

rcLastTVP <- function(df,measurement){
    for(m in 1:length(measurement)){
        for(i in 1:length(ds[,1])){
            
            SOS_url <- paste(ds$source[i],"data.hts?service=SOS",
                             "&request=GetObservation",
                             "&featureOfInterest=",ds$SiteName[i],
                             "&observedProperty=",measurement[m],
                             sep="")
            cat(SOS_url,"\n")
            
            err.attr<-""
            err.list <- c("OK")
            
            result = tryCatch({
                getData.xml <- xmlInternalTreeParse(SOS_url)
            }, warning = function(w) {
                
            }, error = function(e) {
                err.list <- c("NoData")
            }, finally = {
                
            })
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
    
    return(ds)
}