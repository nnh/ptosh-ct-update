# 3a
source("./program/QC/ptosh-ct-update.R")
#CODELIST Code+Codeで2020-12-18CTに存在して、2017-12-22CTに存在しないものの一覧抽出を依頼。1a.のCODELIST codeのものを除く
#抽出されたCODELISTとBridgehead上のCODELISTが同一のものの一覧を出力依頼
#→ マニュアルで追加項目を手動追加していたかどうか確認する
sort_before_csv <- before_csv %>% arrange(Codelist_Code, Code)
sort_after_csv <- after_csv %>% arrange(Codelist_Code, Code)
# CODELIST Code　2017-12-22CTに存在したものだけ残す
before_codelist_code <- sort_before_csv %>% distinct(Codelist_Code, .keep_all=F)
after_codelist_code <- sort_after_csv %>% distinct(Codelist_Code, .keep_all=F)
# 2017->2020で変わりないCodelist_Code
before_after_left_join <- left_join(before_codelist_code, after_codelist_code, by="Codelist_Code")
# 2020で追加されたCodelist_Code
add_codelist_code <- anti_join(after_codelist_code, before_after_left_join, by="Codelist_Code")
# 2017-12-22CTからadd_codelist_codeを除く
exclude_add_codelist_code <- anti_join(sort_after_csv, add_codelist_code,  by="Codelist_Code")
# exclude_add_codelist_codeから2017に存在したCodelist_Code & Codeを除く
distinct_2020_2017_codelist_code_code <- anti_join(exclude_add_codelist_code, sort_before_csv, by=c("Codelist_Code", "Code"))
# output
df_output <- distinct_2020_2017_codelist_code_code
output_name <- "3a"
source("./program/QC/output.R")
