# 3c
source("./program/QC/ptosh-ct-update.R")
sort_before_csv <- before_csv %>% arrange(Codelist_Code, Code)
sort_after_csv <- after_csv %>% arrange(Codelist_Code, Code)
df_3c <- anti_join(sort_before_csv, sort_after_csv, by=c("Codelist_Code", "Code"))
df_output <- df_3c
output_name <- "3c"
source("./program/QC/output.R")
