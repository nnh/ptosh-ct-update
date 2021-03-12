# 3b
source("./program/QC/ptosh-ct-update.R")
sort_before_csv <- before_csv %>% arrange(Codelist_Code, Code)
sort_after_csv <- after_csv %>% arrange(Codelist_Code, Code)
merge_before_after <- inner_join(sort_before_csv, sort_after_csv, by=c("Codelist_Code", "Code"))
df_3b_1 <- merge_before_after %>% filter(Codelist_Name.x != Codelist_Name.y)
df_3b_2 <- merge_before_after %>% filter(CDISC_Submission_Value.x != CDISC_Submission_Value.y)
df_3b_3 <- merge_before_after %>% filter(NCI_Preferred_Term.x != NCI_Preferred_Term.y)
df_3b <- rbind(df_3b_1, df_3b_2, df_3b_3) %>% distinct(Codelist_Code, Code, .keep_all=T) %>% arrange(Codelist_Code, Code)
df_3b_bef <- df_3b %>% select(Code, CodelistId=CodelistId.x, Codelist_Code, Codelist_Name=Codelist_Name.x, CDISC_Submission_Value=CDISC_Submission_Value.x, NCI_Preferred_Term=NCI_Preferred_Term.x)
df_3b_aft <- df_3b %>% select(Code, CodelistId=CodelistId.y, Codelist_Code, Codelist_Name=Codelist_Name.y, CDISC_Submission_Value=CDISC_Submission_Value.y, NCI_Preferred_Term=NCI_Preferred_Term.y)
df_output <- df_3b_bef
output_name <- "3b_2017_12_22"
source("./program/QC/output.R")
df_output <- df_3b_aft
output_name <- "3b_2020_11_06"
source("./program/QC/output.R")
