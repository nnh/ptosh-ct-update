get_change <- function(target_1, target_2){
  # Codelist_CodeとCodeの少なくともどちらかが一致していない
  df_anti_join <- anti_join(target_1, target_2, by="Codelist_Code_code") %>% arrange(Codelist_Code, Code)
  return(df_anti_join)
}
# read files
source("./program/QC/ptosh-ct-update.R")
# used.csvとマッチングしてCodelist_CodeとCodeを結合
after_csv <- match_used("after_csv", used)
before_csv <- match_used("before_csv", used)
# Codelist_CodeとCodeが完全一致→これは対象外
df_exclusion <- inner_join(before_csv, after_csv, by="Codelist_Code_code")
# ------ change
# Codelist_CodeとCodeの少なくともどちらかが一致していない
df_before_anti_join <- get_change(before_csv, df_exclusion)
df_after_anti_join <- get_change(after_csv, df_exclusion)
# Codeだけ一致する
df_before_join_only_code <- inner_join(df_before_anti_join, select(df_after_anti_join, Code), by="Code") %>% distinct()
df_before_join_only_code$flag <- "change_before"
df_before_join_only_code$seq <- 1
df_after_join_only_code <- inner_join(df_after_anti_join, select(df_before_anti_join, Code), by="Code") %>% distinct()
df_after_join_only_code$flag <- "change_after"
df_after_join_only_code$seq <- 2
df_after_join_only_code <- df_after_join_only_code %>% select(-c("used1_flg", "used2_flg"))
df_after_join_only_code$used1_flg <- df_before_join_only_code$used1_flg
df_after_join_only_code$used2_flg <- df_before_join_only_code$used2_flg
df_change <- rbind(df_before_join_only_code, df_after_join_only_code) %>% arrange(Code, CDISC_Submission_Value, seq, Codelist_Code) %>% select(-c("seq"))
# Codeだけ違うデータ
temp_code_only_change_1 <- inner_join(before_csv, after_csv, by=c("Codelist_Code", "CDISC_Submission_Value"))
temp_code_only_change_2 <- temp_code_only_change_1 %>% filter(Code.x != Code.y) %>% select(Codelist_Code, Code.x, Code.y, used1_flg.x, used2_flg.x)
code_only_change_before <- inner_join(before_csv, temp_code_only_change_2, by=c("Codelist_Code", "Code"="Code.x")) %>% select(-c("Code.y", "Codelist_Code_code"))
code_only_change_before$flag <- "change_code_only_before"
code_only_change_before <- code_only_change_before %>% select(-c("used1_flg.x", "used2_flg.x"))
code_only_change_after <- inner_join(after_csv, temp_code_only_change_2, by=c("Codelist_Code", "Code"="Code.y")) %>% select(-c("Code.x", "Codelist_Code_code"))
code_only_change_after$flag <- "change_code_only_after"
code_only_change_after <- code_only_change_after %>% select(-c("used1_flg", "used2_flg", "used1_flg.x", "used2_flg.x"))
code_only_change_after$used1_flg <- code_only_change_before$used1_flg
code_only_change_after$used2_flg <- code_only_change_before$used2_flg
code_only_change <- rbind(code_only_change_before, code_only_change_after) %>% arrange(Codelist_Code, CDISC_Submission_Value, desc(flag), Code)
code_only_change %>% write.csv(str_c("./output/QC/", "code_only_change.csv"), row.names=F, na='""')
# ------ del
# Codelist_code, Codeのセットがbeforeにあってafterにない→削除
df_del <- anti_join(before_csv, after_csv, by="Codelist_Code_code") %>% arrange(Codelist_Code, Code)
# code_only_change_beforeにあるCodelist_code, Codeを除く
df_del_exclusion_code_change <- anti_join(df_del, code_only_change_before, by=c("Codelist_Code", "Code"))
# change_beforeにあるCodeを除く
df_del_exclusion_change <- anti_join(df_del_exclusion_code_change, df_before_join_only_code, by="Code") %>% arrange(Codelist_Code, Code)
df_del_exclusion_change$flag <- "del"
# ------ add
# Codelist_code, Codeのセットがafterにあってbeforeにない→追加
df_add <- anti_join(after_csv, before_csv, by="Codelist_Code_code") %>% arrange(Codelist_Code, Code)
# code_only_change_afterにあるCodelist_code, Codeを除く
# change_afterにあるCodeを除く
df_add_exclusion_code_change <- anti_join(df_add, code_only_change_after, by=c("Codelist_Code", "Code"))
df_add_exclusion_change <- anti_join(df_add_exclusion_code_change, df_after_join_only_code, by="Code") %>% arrange(Codelist_Code, Code) %>% distinct()
df_add_exclusion_change$flag <- "add"
# ------ SAS出力ファイル取り込み
sas_change <- read.csv(str_c("./output/", "codelist_change.csv")) %>% arrange(Code, CDISC_Submission_Value, desc(flag), Codelist_Code)
# change 比較用CSV出力
sas_change %>% write.csv(str_c("./output/QC/", "sas_change.csv"), row.names=F, na='""')
select(df_change, -c("Codelist_Code_code")) %>% write.csv(str_c("./output/QC/", "r_change.csv"), row.names=F, na='""')
# del 比較用CSV出力
select(df_del_exclusion_change, -c("Codelist_Code_code")) %>% write.csv(str_c("./output/QC/", "r_del.csv"), row.names=F, na='""')
# add 比較用CSV出力
select(df_add_exclusion_change, -c("Codelist_Code_code")) %>% write.csv(str_c("./output/QC/", "r_add.csv"), row.names=F, na='""')
# used.csvにないもの
sas_change %>% filter(is.na(used1_flg) && is.na(used2_flg))
# usedを落としてCSV出力
df_change %>% select(-c("used1_flg", "used2_flg", "Codelist_Code_code")) %>% write.csv(str_c("./output/QC/", "r_change_check.csv"))
sas_change %>% select(-c("used1_flg", "used2_flg")) %>% write.csv(str_c("./output/QC/", "sas_change_check.csv"))
# used:is_master=F
not_is_master_used <- used %>% filter(is_master == "FALSE")
unmatch_df_add <- df_add
unmatch_df_add$key <- str_c(unmatch_df_add$CodelistId, unmatch_df_add$CDISC_Submission_Value)
unmatch_used <- not_is_master_used
unmatch_used$key <- str_c(unmatch_used$cdisc_name, unmatch_used$terms_submission_value)
unmatch_add <- unmatch_used %>% anti_join(unmatch_df_add, by="key") %>% arrange(cdisc_name, name, terms_submission_value) %>%
  select(c("cdisc_name", "cdisc_code", "name", "terms_code", "terms_submission_value")) %>% distinct()
#select cdisc_name as CodelistId, cdisc_code as Codelist_Code, name as Codelist_Name,terms_code as Code,
#terms_submission_value as CDISC_Submission_Value, 12 as seq
unmatch_add_sas <- read.csv("./output/code_add.csv", na='') %>% filter(flag=="unmatch") %>% arrange(CodelistId, Codelist_Name, CDISC_Submission_Value) %>%
  select(c("CodelistId", "Codelist_Code", "Codelist_Name", "Code", "CDISC_Submission_Value"))
unmatch_add %>% write.csv(str_c("./output/QC/", "unmatch_add_r.csv"), row.names=F, na='""')
unmatch_add_sas %>% write.csv(str_c("./output/QC/", "unmatch_add_sas.csv"), row.names=F, na='""')
