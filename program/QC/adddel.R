source("./program/QC/ptosh-ct-update.R")
colnames(after_csv)
after_csv$Codelist_Code_code <- str_c(after_csv$Codelist_Code, after_csv$Code)
before_csv$Codelist_Code_code <- str_c(before_csv$Codelist_Code, before_csv$Code)
sas_change <- read.csv(str_c("./output/", "codelist_change.csv")) %>% arrange(Code, CDISC_Submission_Value, flag)
sas_change_before <- read.csv(str_c("./output/", "codelist_change.csv")) %>% filter(flag=="change_before")
sas_change_after <- read.csv(str_c("./output/", "codelist_change.csv")) %>% filter(flag=="change_after")
#sas_before_all <- sas_change %>% filter(flag=="change_before") %>% rbind(sas_del) %>% arrange(Codelist_Code, Code) %>% select(-c("used", "flag"))
#sas_after_all <- sas_change %>% filter(flag=="change_after") %>% rbind(sas_add) %>% arrange(Codelist_Code, Code) %>% select(-c("used", "flag"))
sas_add <- read.csv(str_c("./output/", "code_add.csv")) %>% arrange(Codelist_Code, Code) %>% select(-c("used", "flag"))
sas_del <- read.csv(str_c("./output/", "code_del.csv")) %>% arrange(Codelist_Code, Code) %>% select(-c("used", "flag"))
# Codelist_CodeとCodeが完全一致→これは対象外
df_inner_join <- inner_join(before_csv, after_csv, by="Codelist_Code_code")
# Codelist_CodeとCodeの少なくともどちらかが一致していない
df_before_anti_join <- anti_join(before_csv, df_inner_join, by="Codelist_Code_code") %>% arrange(Codelist_Code, Code)
df_after_anti_join <- anti_join(after_csv, df_inner_join, by="Codelist_Code_code") %>% arrange(Codelist_Code, Code)
# Codeだけ一致する
df_before_join_only_code <- inner_join(df_before_anti_join, select(df_after_anti_join, Code), by="Code") %>% distinct()
df_before_join_only_code$flag <- "change_before"
df_before_join_only_code$seq <- 1
df_after_join_only_code <- inner_join(df_after_anti_join, select(df_before_anti_join, Code), by="Code") %>% distinct()
df_after_join_only_code$flag <- "change_after"
df_after_join_only_code$seq <- 2
df_change <- rbind(df_before_join_only_code, df_after_join_only_code) %>% arrange(Code, CDISC_Submission_Value, flag) %>% select(-c("seq"))
# Codelist_code, Codeのセットがbeforeにあってafterにない→削除
df_del <- anti_join(before_csv, after_csv, by="Codelist_Code_code") %>% arrange(Codelist_Code, Code)
# change_beforeにあるCodeを除く
df_del_exclusion_change <- anti_join(df_del, df_before_join_only_code, by="Code") %>% arrange(Codelist_Code, Code)
# Codelist_code, Codeのセットがafterにあってbeforeにない→追加
df_add <- anti_join(after_csv, before_csv, by="Codelist_Code_code") %>% arrange(Codelist_Code, Code)
# change_afterにあるCodeを除く
df_add_exclusion_change <- anti_join(df_add, df_after_join_only_code, by="Code") %>% arrange(Codelist_Code, Code)
# change
select(sas_change, -c("used")) %>% write.csv(str_c("./output/", "sas_change.csv"))
select(df_change, -c("Codelist_Code_code")) %>% write.csv(str_c("./output/", "r_change.csv"))
# del
sas_del %>% write.csv(str_c("./output/", "sas_del.csv"))
select(df_del_exclusion_change, -c("Codelist_Code_code")) %>% write.csv(str_c("./output/", "r_del.csv"))
# add
sas_add %>% write.csv(str_c("./output/", "sas_add.csv"))
select(df_add_exclusion_change, -c("Codelist_Code_code")) %>% write.csv(str_c("./output/", "r_add.csv"))
