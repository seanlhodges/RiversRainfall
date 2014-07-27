RiversRainfall
==============

Source for providing a simple client that can access multiple river level and rainfall data sets

Background
----------
This project was originally built to access and present river level, rainfall and other environmental information measured and published by Horizons Regional Council. Using the RESTful nature of Hilltop Server, these data can be requested and published via Hilltop or SOS2.0/WaterML based requests and encodings.

The original Shiny application was published in early 2013. This project represents a progressive update to:

1. Fully support WFS for providing site locations
2. Fully support SOS 2.0 requests for retrieving data (Request=GetObservation)
3. Fully support WaterML 2.0 encoded data
4. Support multiple agency data access

Progress
--------
27-Jul-2014
- WFS Location data supported
- GetObservation request supported for individual values. The requests are slow for accessing data across a range of sites
- To speed up data access, RESTful endpoints have been scanned to determine the sites that support observedProperty's of "Flow" and "Rainfall" 


