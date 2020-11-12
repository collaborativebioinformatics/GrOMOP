#!/bin/Rscript
#Utility functions

vectify   <- function (table_in, value_col, name_col){
  #Convert two columns of a tibble into a named vector.
  select  <- dplyr::select
  nms     <- unlist(select(table_in, !!as.name(name_col)), use.names = FALSE)
  vals    <- unlist(select(table_in, !!as.name(value_col)), use.names = FALSE)
  names(vals) <- nms
  return(vals)
}

scan_evs_flags  <- function(evs_file_list,flag_column_num=6,flag_val="indel"){
  #Counts flags via the shell (for speed).
  fread(cmd=
          paste0("ARRAY=(",paste(evs_file_list,collapse=" "),");",
                 "for fl in ${ARRAY[@]}; do cut -f",flag_column_num," $fl | grep ",flag_val," | wc -l; done")) %>%
    unlist(use.names=FALSE)
}


