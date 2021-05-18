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
Codeの内容のみ変更された項目  
# 実行手順
