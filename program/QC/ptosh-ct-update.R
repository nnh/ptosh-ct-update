library(tidyverse)
rawdata_path <- "./input/rawdata"
output_path <- "./output/QC"
before <- read.delim(str_c(rawdata_path, "/", "SDTM Terminology 2017-12-22.txt"))
after <- read.delim(str_c(rawdata_path, "/", "SDTM Terminology 2020-11-06.txt"))
before_csv <- read.csv(str_c(rawdata_path, "/", "SDTM Terminology 2017-12-22.csv"))
after_csv <- read.csv(str_c(rawdata_path, "/", "SDTM Terminology 2020-11-06.csv"))
before_codelist <- before_csv[ , "Codelist_Code"] %>% unique()
after_codelist <- after_csv[ , "Codelist_Code"] %>% unique()
