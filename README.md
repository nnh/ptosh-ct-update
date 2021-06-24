# 概要
SDTM Terminology 2017-12-22.csvとSDTM Terminology 2020-11-06.csvを比較した結果を出力します。  
# 出力ファイル  
* 1a.csv   
Codelist Codeが追加された項目  
* 3a.csv  
Codelist Codeが変更、Codeが追加された項目  
* 3b.csv  
Codelist Codeが変更、Codeの内容が変更された項目  
* 3c.csv  
Codelist Codeが変更、Codeが削除された項目  
* codelist_change.csv  
t.codeとt.submission_valueは変更されずに、ct.codeとct.submission_valueが変更された項目を新旧交互に出力  
used.csvに存在する項目はused=1をセットする  
* code_add.csv  
追加項目のうち、codelist_changeに存在しない項目  
used.csvに存在する項目はused=1をセットする  
* code_del.csv  
削除項目のうち、codelist_changeに存在しない項目  
used.csvに存在する項目はused=1をセットする  
* code_only_change.csv  
Codeの内容のみ変更された項目を新旧交互に出力  
used.csvに存在する項目はused=1をセットする  
# プログラム内容
* PTOSH_CT_UPDATE_1A.sas  
1a.csvを出力する  
* PTOSH_CT_UPDATE_3A.sas   
3a.csvを出力する  
* PTOSH_CT_UPDATE_3B.sas  
3b.csvを出力する  
* PTOSH_CT_UPDATE_3C.sas  
3c.csvを出力する  
* PTOSH_CT_UPDATE_CODELIST_CHANGE.sas  
codelist_change.csv, code_add.csv, code_del.csv, code_only_change.csvを出力する  
* PTOSH_CT_UPDATE_all_exec.sas  
PTOSH_CT_UPDATE_1A.sas, PTOSH_CT_UPDATE_3A.sas, PTOSH_CT_UPDATE_3B.sas, PTOSH_CT_UPDATE_3C.sasを実行する 
* SDTM_CT_convert_for_after_file.sas  
SDTM Terminology 2020-11-06.txtを上記プログラム実行用の入力ファイルに変換する  
* SDTM_CT_convert_for_before_file.sas  
SDTM Terminology 2017-12-22.txtを上記プログラム実行用の入力ファイルに変換する  
* convert-csv-from-json.R  
JSON形式ファイルをCSVファイルに変換する  
# 実行手順
SASの場合は該当プログラムをSAS（日本語）で開きサブミットする。  
Rの場合はptosh-ct-update/でCreate Projectして該当のプログラムを開きSourceかRunで実行する。  
