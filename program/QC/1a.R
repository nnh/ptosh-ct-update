# 1a
source("./program/QC/ptosh-ct-update.R")
add <- setdiff(after_codelist, before_codelist)
df_add <- map_df(add, function(x){
  temp <- filter(after_csv, Codelist_Code == x)
})
df_output <- df_add
output_name <- "1a"
source("./program/QC/output.R")
