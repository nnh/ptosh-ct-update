# read files
source("./program/QC/ptosh-ct-update.R")
# used.csvとマッチング
before_csv <- match_used("before_csv", used) %>% select(-c(Codelist_Code_code))
# before, after両方にあるCodelist_Code
match_code <- inner_join(before_csv, after_csv, by="Codelist_Code") %>% select(Codelist_Code) %>% distinct()
# beforeからbefore, after両方にあるCodeを除く
unmatch_code <- anti_join(before_csv, match_code, by="Codelist_Code") %>% arrange(Codelist_Code, Code)
unmatch_code$flag <- "2ab"
unmatch_code$used <- unmatch_code$temp_used
unmatch_code <- unmatch_code %>% select(-c("temp_used"))
write.csv(unmatch_code, str_c("./output/QC/", "2ab.csv"), row.names=F, na='""')
