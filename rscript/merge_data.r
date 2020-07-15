github_full_data <- read.csv("covid-19/data/time-series-19-covid-combined.csv")
owid_data <- read.csv("covid-19-data/public/data/owid-covid-data.csv")
ref <- read.csv("covid-19/data/reference.csv")

# substrRight <- function(x, n){
#   nc = nchar(x)
#   substr(x, nc-n+1, nc)
# }
# 
# substrRmRight <- function(x, n){
#   nc = nchar(x)
#   substr(x, start = 1, stop = nc-n)
# }
# 
# rmSAR <- function(x) {
#   is_sar <- substrRight(x,4) == " SAR"
#   print(sum(is_sar))
#   ifelse(is_sar, substrRmRight(x, 4), x)
# }

#John-Hopkin data
# jh_data_confirmed <- read.csv("COVID-19-JH/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv")
# jh_data_death <- read.csv("COVID-19-JH/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv")
# jh_data_recovered <- read.csv("COVID-19-JH/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv")
# 
# cols <- names(jh_data)
# dates <- as.Date(cols, "X%m.%d.%y")
# varying <- which(!is.na(dates))
# data <- reshape(jh_data, idvar = which(is.na(dates)), varying = varying, timevar = "Date", times = dates[varying], v.names = "Confirmed", direction = "long", new.row.names = NULL)
# rownames(data) <- NULL
# small_ref <- ref[,c("Province_State", "Country_Region", "UID")]
# small_ref$Province_State <- rmSAR(small_ref$Province_State)
# 
# data2 <- merge(data, small_ref, by.x = c("Country.Region", "Province.State"), by.y = c("Country_Region", "Province_State"), all.x = T, all.y=F)
# head(data2)
#abc


github_full_data$Date <- as.Date(github_full_data$Date)
owid_data$date <- as.Date(owid_data$date)

#aggreate full data for github data

github_full_data <- merge(github_full_data, ref, by.x = c("Country.Region", "Province.State"), by.y = c("Country_Region", "Province_State"), all.x = T, all.y=F)
# Since canada has some weird stuff i need to do this
unmapped <- is.na(github_full_data$UID)
update_col <- intersect(colnames(ref),colnames(github_full_data))
github_full_data[unmapped, update_col] <- ref[match(github_full_data[unmapped,"Country.Region"], ref$Country_Region), update_col]

#should have no na in full_data$uid
github_full_data$code <- ifelse(is.na(github_full_data$code3), github_full_data$UID, github_full_data$code3)
github_data <- aggregate(x = github_full_data[c("Confirmed", "Recovered", "Deaths")], by = list(uid = github_full_data$code, date = github_full_data$Date), FUN = function(x) { sum(x, na.rm=T) } )


#aggregate github world
github_world_data <- aggregate(x = github_data[c("Confirmed", "Recovered", "Deaths")], by = list(date = github_data$date), FUN = function(x) { sum(x, na.rm=T) } )

# specific iso
owid_data[owid_data$iso_code == "","iso_code"] <- "_INT"
owid_data[owid_data$iso_code == "OWID_WRL","iso_code"] <- "_WRL"
owid_data$code <- ref[match(owid_data$location, ref$Country_Region),"UID"]
#Map using iso
mapping <- match(owid_data$iso_code, ref$iso3)
mapped <- !is.na(mapping)
#update location by isocode
owid_data[mapped,"code"] <- ref$UID[mapping[mapped]]
unmapped <- which(is.na(owid_data$code)) 
new_loc <- unique(owid_data[unmapped,]$location)
new_uid <- -seq(1, length(new_loc))

github_full = github_data

#finding constant column in owid_data
collapse = aggregate(x = owid_data, by = list("DROP" = owid_data$code),function(x) {(all(is.na(x)) || (all(!is.na(x)) && all(x==x[1])))}) 
collapse$DROP = NULL
constant = apply(collapse, MARGIN = 2, FUN= all)
constant["code"] = F
country_data = aggregate(x = owid_data[,names(constant[constant])], by = list("UID" = owid_data$code),function(x) {x[1]}) 

#remove
owid_data_small = owid_data[, names(constant[!constant])]

#move it to another table

#merge
github_full$date <- github_full$date + 1
res <- merge(x = github_full, y = owid_data_small, by.x = c("date", "uid"), by.y = c("date", "code"),all.x = T,all.y = F, sort = TRUE)

#merge with reference
cnt_ref <- ref[match(unique(res$uid),ref$UID),]
ref_merged = merge(cnt_ref, country_data, by.x = "UID", by.y = "UID", all.x = T, all.y = T)
combine <- function(df, col1, col2) {
  miss = is.na(df[,col1])
  df[miss, col1] = df[miss, col2]
  df[,col2] <- NULL
  df
}
ref_merged <- combine(ref_merged, "iso3", "iso_code")
ref_merged <- combine(ref_merged, "Country_Region", "location")
ref_merged <- combine(ref_merged, "Population", "population")

#additional info
res$location <- ref_merged[match(res$uid, ref_merged$UID), ]$Combined_Key

#save
write.csv(res, file = "mydata/merged.csv", row.names = F)
write.csv(cnt_ref, file = "mydata/location.csv", row.names = F)

#github_data$Code = ref$UID[match(github_data$Country, ref$Country_Region)] * 1000 + unclass(github_data$Date)
#assert this sum(duplicated(github_data$Code)) == 0
