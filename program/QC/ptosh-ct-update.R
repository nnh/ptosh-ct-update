library(tidyverse)
match_used <- function(input_df_name, used){
  temp_used <- used %>% select(c("cdisc_name", "terms_submission_value", "used1_flg", "used2_flg"))
  assign(str_c("save_", input_df_name), get(input_df_name), envir=.GlobalEnv)  # Save data frame
  temp <- left_join(get(input_df_name), temp_used, by=c("CodelistId"="cdisc_name", "CDISC_Submission_Value"="terms_submission_value"))
  temp$Codelist_Code_code <- str_c(temp$Codelist_Code, temp$Code)
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
used <- read.csv(str_c(rawdata_path, "/used.csv"), header=T, na='.', colClasses="character")
