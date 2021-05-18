match_used <- function(input_df_name, used){
  assign(str_c("save_", input_df_name), get(input_df_name), envir=.GlobalEnv)  # Save data frame
  temp <- left_join(get(input_df_name), used, by=c("CodelistId"="V1", "CDISC_Submission_Value"="V4"))
  temp$temp_used <- ifelse(!(is.na(temp$V2)), 1, ".")
  temp$Codelist_Code_code <- str_c(temp$Codelist_Code, temp$Code)
  temp <- temp %>% select(-c("V2", "V3", "V5"))
  return(temp)
}
get_change <- function(target_1, target_2){
  # Codelist_CodeとCodeの少なくともどちらかが一致していない
  df_anti_join <- anti_join(target_1, target_2, by="Codelist_Code_code") %>% arrange(Codelist_Code, Code)
  return(df_anti_join)
}
# read files
source("./program/QC/ptosh-ct-update.R")
used <- read.csv(str_c(rawdata_path, "/used.csv"), header=F)
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
df_after_join_only_code$temp_used <- df_before_join_only_code$temp_used
df_change <- rbind(df_before_join_only_code, df_after_join_only_code) %>% arrange(Code, CDISC_Submission_Value, seq, Codelist_Code) %>% select(-c("seq"))
df_change$used <- df_change$temp_used
df_change <- df_change %>% select(-c("temp_used"))
# ------ del
# Codelist_code, Codeのセットがbeforeにあってafterにない→削除
df_del <- anti_join(before_csv, after_csv, by="Codelist_Code_code") %>% arrange(Codelist_Code, Code)
# change_beforeにあるCodeを除く
df_del_exclusion_change <- anti_join(df_del, df_before_join_only_code, by="Code") %>% arrange(Codelist_Code, Code)
df_del_exclusion_change$flag <- "del"
df_del_exclusion_change$used <- df_del_exclusion_change$temp_used
df_del_exclusion_change <- df_del_exclusion_change %>% select(-c("temp_used")) %>% distinct()
# ------ add
# Codelist_code, Codeのセットがafterにあってbeforeにない→追加
df_add <- anti_join(after_csv, before_csv, by="Codelist_Code_code") %>% arrange(Codelist_Code, Code)
# change_afterにあるCodeを除く
df_add_exclusion_change <- anti_join(df_add, df_after_join_only_code, by="Code") %>% arrange(Codelist_Code, Code) %>% distinct()
df_add_exclusion_change$flag <- "add"
df_add_exclusion_change$used <- df_add_exclusion_change$temp_used
df_add_exclusion_change <- df_add_exclusion_change %>% select(-c("temp_used"))
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
sas_change %>% filter(used != 1)
# usedを落としてCSV出力
df_change %>% select(-c("used", "Codelist_Code_code")) %>% write.csv(str_c("./output/QC/", "r_change_check.csv"))
sas_change %>% select(-c("used")) %>% write.csv(str_c("./output/QC/", "sas_change_check.csv"))
# Codeだけ違うデータ
temp_code_only_change_1 <- inner_join(before_csv, after_csv, by=c("Codelist_Code", "CDISC_Submission_Value"))
temp_code_only_change_2 <- temp_code_only_change_1 %>% filter(Code.x != Code.y) %>% select(Codelist_Code, Code.x, Code.y, used=temp_used.x)
code_only_change_before <- inner_join(before_csv, temp_code_only_change_2, by=c("Codelist_Code", "Code"="Code.x")) %>% select(-c("temp_used", "Code.y", "Codelist_Code_code"))
code_only_change_before$flag <- "change_code_only_before"
code_only_change_after <- inner_join(after_csv, temp_code_only_change_2, by=c("Codelist_Code", "Code"="Code.y")) %>% select(-c("temp_used", "Code.x", "Codelist_Code_code"))
code_only_change_after$flag <- "change_code_only_after"
code_only_change <- rbind(code_only_change_before, code_only_change_after) %>% arrange(Codelist_Code, desc(flag), Code)
code_only_change %>% write.csv(str_c("./output/QC/", "code_only_change.csv"), row.names=F, na='""')
