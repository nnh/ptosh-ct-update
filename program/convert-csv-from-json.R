# Converting a JSON file to a CSV file
# Mariko Ohtsuka
# Create 2021/06/23
# ------ libraries ------
library(tidyverse)
library(jsonlite)
library(here)
# ------ functions ------
#' Read a JSON file and store it in a data frame
#'
#' Read the JSON file and store it in the data frame of the global environment.
#' The data frame name is the same as the JSON file.
#' @param target_full_path Path of the JSON file
#' @return NULL
EditDataFrameFromJson <- function(target_full_path){
  temp_read_file <- target_full_path %>% read_file()
  object_name <- target_full_path %>% str_extract("[^/]+(?=.json$)")
  assign(object_name, fromJSON(temp_read_file), envir=.GlobalEnv)
  return(NULL)
}
#' Create the output data frame
#'
#' @param input_df input data frame
#' @param flatten_colname Name of the nested column (only one column)
#' @return a data frame
CreateDataFrameForOutput <- function(input_df, flatten_colname){
  output_df <- NULL
  for (i in 1:nrow(input_df)){
    temp_others <- input_df[i, ] %>% select(c(-all_of(flatten_colname)))
    temp_others$temp_key <- 1
    temp_flatten <- input_df[i, all_of(flatten_colname)] %>% do.call("rbind", .) %>% flatten(recursive=T) %>%
      mutate_if(is.numeric, as.character)
    temp_colnames <- temp_flatten %>% colnames() %>% str_c(all_of(flatten_colname), "_", .)
    colnames(temp_flatten) <- temp_colnames
    temp_flatten$temp_key <- 1
    output_df <- full_join(temp_others, temp_flatten, by="temp_key") %>% bind_rows(output_df, .)
  }
  output_df <- output_df %>% select(-c("temp_key"))
  return(output_df)
}
# ------ main ------
rawdata_path <- here("input", "rawdata")
output_path <- rawdata_path
file_list <- list.files(rawdata_path, pattern="json$", full.names=T)
map(file_list, EditDataFrameFromJson)
output_template <- CreateDataFrameForOutput(template, "field_items") %>%
  write.csv(str_c(output_path, "/template.csv"), row.names=F, na="")
output_controlled_terminologies <- CreateDataFrameForOutput(controlled_terminologies, "terms") %>%
  write.csv(str_c(output_path, "/controlled_terminologies.csv"), row.names=F, na="")
