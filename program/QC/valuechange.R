# read files
source("./program/QC/ptosh-ct-update.R")
# used.csvとマッチング
before_csv <- match_used("before_csv", used) %>% select(-c(Codelist_Code_code))
# before, after両方にあるCodelist_Code, Code
match_code <- inner_join(before_csv, after_csv, by=c("Codelist_Code", "Code")) %>% select(Codelist_Code, Code) %>% distinct()
before_match <- inner_join(before_csv, match_code, by=c("Codelist_Code", "Code"))
df_used <- before_match %>% select(Codelist_Code, Code, used1_flg, used2_flg)
after_match <- inner_join(after_csv, match_code, by=c("Codelist_Code", "Code")) %>% inner_join(df_used, by=c("Codelist_Code", "Code"))
before_match$temp_seq <- 1
after_match$temp_seq <- 2
# submission value
temp <- inner_join(before_match, after_match, by=c("Codelist_Code", "Code"))
submission_value_change_code <- filter(temp, CDISC_Submission_Value.x != CDISC_Submission_Value.y) %>% select(Codelist_Code, Code) %>% distinct()
before_submission_value_change <- inner_join(before_match, submission_value_change_code, by=c("Codelist_Code", "Code")) %>% distinct()
after_submission_value_change <- inner_join(after_match, submission_value_change_code, by=c("Codelist_Code", "Code")) %>% distinct()
submission_value_change <- rbind(before_submission_value_change, after_submission_value_change) %>% arrange(Codelist_Code, Code, temp_seq)
submission_value_change$flag <- ifelse(submission_value_change$temp_seq == 1, "submission_value_change_before", "submission_value_change_after")
submission_value_change <- submission_value_change %>% select(-c(temp_seq))
submission_value_change <- submission_value_change %>% filter(used1_flg == 1 | used2_flg == 1)
write.csv(submission_value_change, str_c("./output/QC/", "Submission Value_change.csv"), row.names=F, na='""')
# NCI preferred term
temp <- inner_join(before_match, after_match, by=c("Codelist_Code", "Code"))
nci_change_code <- filter(temp, NCI_Preferred_Term.x != NCI_Preferred_Term.y) %>% select(Codelist_Code, Code) %>% distinct()
before_nci_change <- inner_join(before_match, nci_change_code, by=c("Codelist_Code", "Code")) %>% distinct()
after_nci_change <- inner_join(after_match, nci_change_code, by=c("Codelist_Code", "Code")) %>% distinct()
nci_change <- rbind(before_nci_change, after_nci_change) %>% arrange(Codelist_Code, Code, temp_seq)
nci_change$flag <- ifelse(nci_change$temp_seq == 1, "NCI_preferred_term_before", "NCI_preferred_term_after")
nci_change$used <-nci_change$temp_used
nci_change <- nci_change %>% select(-c(temp_used, temp_seq))
write.csv(nci_change, str_c("./output/QC/", "NCI Preferred Term_change.csv"), row.names=F, na='""')

