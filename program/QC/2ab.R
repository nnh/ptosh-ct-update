# read files
source("./program/QC/ptosh-ct-update.R")
# used.csvとマッチング
before_csv <- match_used("before_csv", used) %>% select(-c(Codelist_Code_code))
# before, after両方にあるCode
match_code <- inner_join(before_csv, after_csv, by="Code") %>% select(Code) %>% distinct()
# beforeからbefore, after両方にあるCodeを除く
unmatch_code <- anti_join(before_csv, match_code, by="Code") %>% arrange(Code, Codelist_Code)
unmatch_code$flag <- NA
unmatch_code$used <- unmatch_code$temp_used
unmatch_code <- unmatch_code %>% select(-c("temp_used"))
write.csv(unmatch_code, str_c("./output/QC/", "2ab.csv"), row.names=F, na='""')
