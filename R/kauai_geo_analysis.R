############################################################
####  This code finds out which charging stations are within 
####  the Kauai county                      
############################################################

# Remove all objects in the workspace. Clean slate.
rm(list=ls())

# Change this to directory where this R file is located
setwd("C:\\temp\\CP")
# Change this to the filename containing the charging stations from AFDC
hawaii_FC <- read.csv("alt_fuel_stations.csv")

hawaii_FC$county <- NA

## Download the file
temp <- tempfile()
download.file("http://download.geonames.org/export/zip/US.zip",temp)
con <- unz(temp, "US.txt")
US <- read.delim(con, header=FALSE)
unlink(temp)
colnames(US)[c(3,5,6)] <- c("city","state","county")
US$city <- tolower(US$city)
# regularize the name of cities 
hawaii_FC$City <- as.character(hawaii_FC$City)
hawaii_FC$City[31] <- "Papaaloa"
hawaii_FC$City[30] <- "Keaau"
hawaii_FC$City[28] <- "Kailua Kona"
for (i in 1:length(hawaii_FC)) {
  hawaii_FC$county[i] <- as.character(US$county[US$city %in% tolower(hawaii_FC$City[i])][1])
}
# Waimea FC in Big Island and not Kauai 
hawaii_FC$county[which(tolower(hawaii_FC$City) == 'waimea')] <- 'Hawaii'
kauai_FC <- hawaii_FC[tolower(hawaii_FC$county) %in% 'kauai',]

kauai_FC_useful <- kauai_FC[, c('City', 'ZIP', 'EV.DC.Fast.Count', 'Latitude', 'Longitude', 'ID', 'EV.Connector.Types')]
kauai_FC_useful$Latitude <- round(kauai_FC_useful$Latitude, 5)
kauai_FC_useful$Longitude <- round(kauai_FC_useful$Longitude, 5)
# This is the CSV file read by GAMA, containing the location and info
# about the charging station(s)
write.csv(kauai_FC_useful, file = "kauai_FC.csv")
