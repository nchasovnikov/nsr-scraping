setwd('/Volumes/Untitled/GitHub/NSR_scraping')
Sys.setlocale("LC_CTYPE", "ru_RU.UTF-8")

require('rvest')
require('stringr')

start_date <- as.Date("2022-01-01")
end_date <- as.Date("2022-09-09")

search_dates <- seq(start_date, end_date, by=1)

url <- "http://www.nsra.ru/ru/grafik_dvijeniya_po_smp.html?date="

vessels_df <- setNames(data.frame(matrix(ncol = 8, nrow = 0)), c("Number", "Name", "IMO_number", "Lat_Lon", "Course", "Speed", "ETA", "Date"))

for (search_date in search_dates){
  str_date <- format(as.Date(search_date, origin = "1970-01-01"), "%Y-%m-%d")
  print(str_c("retrieving date ", str_date))
  tables <- read_html(str_c(url, str_date)) %>% html_nodes('table')
  if (length(tables) > 1) {
    rows <- tables[2] %>% html_nodes('tr')
    for (row in rows[-1]){
      tds <- row %>% html_nodes('td') %>% html_text()
      tds[8] <- str_date
      vessels_df <- data.frame(rbind(as.matrix(vessels_df), tds))
    }
  }
  Sys.sleep(3)
}

write.csv(vessels_df,"vessels_df.csv")

library(dplyr)
library(readr)
library(tidyr)

setwd('/Volumes/Untitled/GitHub/NSR_scraping/files')
df <- list.files(path='/Volumes/Untitled/GitHub/NSR_scraping/files') %>% 
  lapply(read_csv) %>% 
  bind_rows 

# tidying data

df <- df %>% separate(Lat_Lon, sep="; ", into=c("Latitude","Longitude"))

write.csv(df,"vessels_df_full.csv")


imo_numbers <- df %>%
  distinct(IMO_number) %>%
  filter(grepl("\\d{7}", IMO_number))



library('RSelenium')
library('tibble')

url <- "https://www.balticshipping.com/vessel/imo/"

vessels_by_imo <- data.frame(matrix(ncol = 17, nrow = 0))

driver <- rsDriver(browser = c("chrome"), chromever = "105.0.5195.52", port = 1234L)
remote_driver <- driver[["client"]] 

imo_number <-''

for(imo_number in imo_numbers){
  webpage <- str_c(url, as.character(imo_number))
  print(webpage)
  remote_driver$navigate(webpage)
  Sys.sleep(5)
  page <- remote_driver$getPageSource()[[1]]
  tables <- page %>%
    read_html() %>%
    html_nodes(xpath = '//*[@id="vessel_info"]/div[1]/div/div[3]/table') %>%
    html_table()
  
  if (length(tables) > 0) {
    tb <- tables[[1]] %>% spread(X1,X2)
    vessels_by_imo <- data.frame(rbind(as.matrix(vessels_by_imo), as.matrix(tb)))
  }
}
remote_driver$close()
driver$server$stop()
