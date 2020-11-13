#!/bin/Rscript
#Toy data generator
#Execute script to generate random ESV files for <pat_num> patients, including up to 5 biopsies.
#Files are placed in the <toy_directory>, along with a summary file "evs_file_summary.tsv".

library(tidyverse)
library(data.table)
library(magrittr)
library(GenomicRanges)
library(lubridate)
library(here)
source(here("src/R/utility_functions.R"))

pat_num       <- 100
toy_directory <- here("data/toy_data")
dir.create(toy_directory,showWarnings = FALSE)
genders       <- c(male=0.48,female=0.49,na=0.03)
source_tissues<- c("liver","skin","brain","bowel","testicle","pancreas")
#cancer_types  <- c("CFF45","Devi5 positive","ETV4 negative","LEK33","LolNah")
locations     <- c("Atlanta GA","Lake Luerne NY","University of Pittsburgh","Olive Garden Queensbury NY","Andrew's basement")
chroms        <- paste0("chr",c(1:21,"X","Y"))
genomes       <- c(hg38=0.7,hg19=0.2,hg18=0.1)
outcomes      <- c(deceased=0.4,alive=0.6)
stages        <- c(I=0.6,II=0.2,III=0.15,IV=0.05)
sample_method <- c(biopsy=0.6,blood_draw=0.3,swab=0.1)
biopsy_count  <- c("1"=0.6,"2"=0.3,"3"=0.05,"4"=0.025,"5"=0.025)
flags         <- c(meta_driver=0.01,cooccurring=0.3,indel=0.69)

#Athena resuls; randomly selected from Athena file.
athena_codes <- c("314990009","359780007","422782004","423987006","94154007","94206007","94289002",
                  "94330007","94355001","94368009","94398002","94399005","94459006","94494004",
                  "94504009","94557005","94585007","94604000","94626004","94636007")

date_range    <- seq(ymd("1995-01-01"),ymd("2020-11-11"),by="day")

random_patient_id     <- function(char_len=8){
  sample(replace = FALSE,size = char_len,
    c(toupper(sample(letters,size = char_len)),
      sample(c(0:9),size=char_len))) %>%
    paste(collapse="")
}
generate_variant_set  <- function(patient_id="TT453FF",test_number=1,out_length_min=15,out_length_max=100,write_directory=toy_directory,write_test_file=FALSE){
#Enhanced variant set
#chrom start end ref alt
  out_file_name <- paste0(write_directory,"/",patient_id,"_",test_number,".evs")
  if(write_test_file){
    len_out       <- sample(c(out_length_min:out_length_max),size = 1)
    tibble(chrom=sample(chroms,replace = TRUE,size = len_out)) %>%
      rowwise() %>%
      mutate(start=round(rnorm(1,1e8,sd=1e6),digits=0),
             len = sample(c(1:10),size = 1),
             end = start + len,
             ref = sample(c("A","C","G","T"),replace=TRUE,size = len) %>% paste(collapse=""),
             alt = sample(c("A","C","G","T"),replace=TRUE,size = len) %>% paste(collapse=""),
             flag= sample(names(flags),prob = flags,size = n(),replace = TRUE)) %>%
      select(-len) %>%
      write.csv(file = out_file_name,quote = FALSE,row.names = FALSE)
  }
  return(out_file_name)
}

evs_tb  <- tibble(patient_id = sapply(c(1:pat_num), function(x) random_patient_id())) %>%
            mutate(gender = sample(names(genders),prob = genders,size = n(),replace = TRUE),
                   condition = sample(athena_codes,size = n(),replace = TRUE),
                   #tissue = sample(source_tissues,size=n(),replace =TRUE),
                   #type = sample(cancer_types,size=n(),replace=TRUE),
                   date = sample(date_range,replace = TRUE,size = n())) %>%
            rowwise() %>%
            mutate(biopsy = list(c(1:as.integer(sample(names(biopsy_count),prob=biopsy_count,size = n(),replace = TRUE))))) %>%
            unnest(biopsy) %>%
            rowwise() %>%
            mutate(evs_file = generate_variant_set(patient_id,test_number = biopsy,write_test_file = TRUE)) %>%
            group_by(patient_id) %>%
            mutate(final = biopsy==max(biopsy),
                   genome= sample(names(genomes),prob=genomes,size = n(),replace = TRUE),
                   sample_method=sample(names(sample_method),prob = sample_method,size = n(),replace = TRUE),
                   stage = sample(names(stages),prob=stages,size = n(),replace = TRUE),
                   location=sample(locations,size = n(),replace = TRUE),
                   status= ifelse(!final,"alive",
                                   sample(names(outcomes),prob = outcomes,size = 1)),
                   more_days = sample(c(1:365),size = n()),
                   more_days = ifelse(final,more_days,0),
                   date = date + days(more_days)) %>%
            select(-final,-more_days) %>%
            ungroup() %>%
            mutate(met=scan_evs_flags(evs_file,flag_val = "meta_driver"),
                   coo=scan_evs_flags(evs_file,flag_val = "cooccurring"),
                   ind=scan_evs_flags(evs_file,flag_val = "indel")) %T>%
              write.csv(file = file.path(toy_directory,"evs_metadata.csv"),row.names = FALSE,quote = FALSE)
