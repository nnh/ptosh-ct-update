df_output <- df_output %>% arrange(Codelist_Code, Code)
df_output_2 <- df_output %>% rename(ct.name=Codelist_Name, ct.submission_value=CodelistId, ct.code=Codelist_Code, t.code=Code,
                              t.submission_value=CDISC_Submission_Value, t.label=NCI_Preferred_Term)
df_output_3 <- df_output_2 %>% select(ct.name, ct.submission_value, ct.code, t.code, t.submission_value, t.label)
write.csv(df_output_3, file=str_c(output_path, "/", output_name, ".csv"), row.names=F, na='""', quote=T)
