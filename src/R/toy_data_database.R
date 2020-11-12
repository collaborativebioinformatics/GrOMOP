#!/bin/Rscript
#Toy dataset database.
##Uses toy ESV files and metadata table created by toy_data_sets.R.
library(ROMOPOmics)
library(tidyverse)
library(data.table)
library(magrittr)
library(here)

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

meta_data <- as_tibble(tb2)

