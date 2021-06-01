library(tidyverse)
match_used <- function(input_df_name, used){
  assign(str_c("save_", input_df_name), get(input_df_name), envir=.GlobalEnv)  # Save data frame
  temp <- left_join(get(input_df_name), used, by=c("CodelistId"="V1", "CDISC_Submission_Value"="V4"))
  temp$temp_used <- ifelse(!(is.na(temp$V2)), 1, ".")
  temp$Codelist_Code_code <- str_c(temp$Codelist_Code, temp$Code)
  temp <- temp %>% select(-c("V2", "V3", "V5"))
  return(temp)
}
rawdata_path <- "./input/rawdata"
output_path <- "./output/QC"
before <- read.delim(str_c(rawdata_path, "/", "SDTM Terminology 2017-12-22.txt"))
after <- read.delim(str_c(rawdata_path, "/", "SDTM Terminology 2020-11-06.txt"))
before_csv <- read.csv(str_c(rawdata_path, "/", "SDTM Terminology 2017-12-22.csv"))
after_csv <- read.csv(str_c(rawdata_path, "/", "SDTM Terminology 2020-11-06.csv"))
before_codelist <- before_csv[ , "Codelist_Code"] %>% unique()
after_codelist <- after_csv[ , "Codelist_Code"] %>% unique()
used <- read.csv(str_c(rawdata_path, "/used.csv"), header=F)
