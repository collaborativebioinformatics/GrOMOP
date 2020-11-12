#!/bin/Rscript
#Toy dataset database.
##Uses toy ESV files and metadata table created by toy_data_sets.R.
library(ROMOPOmics)
library(tidyverse)
library(data.table)
library(magrittr)
library(here)
library(dbplyr)

source(here("src/R/utility_functions.R"))

rename    <- dplyr::rename
mutate    <- dplyr::mutate

dir_data  <- here("data/toy_data")

#Option 1: Scan director(ies) for ESV files, count their flags.
##Issue: where's the metadata going to come from?
#Collect all TSV files and scan for flags.
tb  <- tibble(evs_file=Sys.glob(file.path(dir_data,"*.evs")),
              met=scan_evs_flags(evs_file,flag_val="meta_driver"),
              ind=scan_evs_flags(evs_file,flag_val="indel"),
              coo=scan_evs_flags(evs_file,flag_val="cooccurring"))

#Option 2: Load a table of data that includes files and metadata, can still 
# scan for flags.
##Issue: Where will this table come from?
tb2 <- fread(Sys.glob(file.path(dir_data,"*.csv")))
        #mutate(met=scan_evs_flags(evs_file,flag_val="meta_driver"),
        #       ind=scan_evs_flags(evs_file,flag_val="indel"),
        #       coo=scan_evs_flags(evs_file,flag_val="cooccurring")) %T>%
        #  write.table(file = here("data/toy_data/tsv_metadata.csv"),row.names = FALSE,quote = FALSE,sep = ",")

dim(tb)
dim(tb2)

head(tb)
head(tb2)

#ROMOPOmics.
dm      <- loadDataModel(master_table_file = here("src/OMOP_CDM_v6_0_GrOMOP.csv"))
msk     <- loadModelMasks(mask_files = here("src/toy_mask_example.tsv"))
file_in <- file.path(dir_data,"evs_metadata.csv")
omop_in <- readInputFile(file_in,data_model = dm,mask_table = msk,transpose_input_table = TRUE)
db_in   <- combineInputTables(input_table_list = omop_in) #Still broken???
omop_db <- buildSQLDBR(db_in,sql_db_file = file.path(dir_data,"toy_sql.db"))
#write.table(fread(here("src/toy_mask_example.csv")),quote = FALSE,sep = "\t",file = here("src/toy_mask_example.tsv"),row.names = FALSE)

tbls  <- db_list_tables(omop_db)

inner_join(x = tbl(omop_db,"PERSON"),tbl(omop_db,"SPECIMEN")) %>%
  inner_join(tbl(omop_db,"SEQUENCING")) %>%
  select_if(function(x) !all(is.na(x))) %>%
  filter(specimen_source_value == "metastatic driver" & quantity > 0) %>%
  select(person_source_value,specimen_source_value,quantity,unit_concept_id,file_local_source) %>%
  as_tibble() %>%
  mutate(file_local_source = basename(file_local_source))
           
  
DBI::dbDisconnect(omop_db)
  

