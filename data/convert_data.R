library(readr)
library(dplyr)
##
## convert_data.R : Convert various data sources into svaha3-friendly
## formats.
## svaha3 accepts the following formats:
## 1. VCF
## 2. MAF
## 3. TSV (with the first 5 columns being chrom, start_pos, end_pos, ref, alt)
##
## Standard graph identifiers include:
## DRIVER: True / False
## RISK: True / False
## MET_ASSOCIATED: True / False

## Accessory functions:

arrange_vars <- function(data, vars){
  ##stop if not a data.frame (but should work for matrices as well)
  stopifnot(is.data.frame(data))
  
  ##sort out inputs
  data.nms <- names(data)
  var.nr <- length(data.nms)
  var.nms <- names(vars)
  var.pos <- vars
  ##sanity checks
  stopifnot( !any(duplicated(var.nms)), 
             !any(duplicated(var.pos)) )
  stopifnot( is.character(var.nms), 
             is.numeric(var.pos) )
  stopifnot( all(var.nms %in% data.nms) )
  stopifnot( all(var.pos > 0), 
             all(var.pos <= var.nr) )
  
  ##prepare output
  out.vec <- character(var.nr)
  out.vec[var.pos] <- var.nms
  out.vec[-var.pos] <- data.nms[ !(data.nms %in% var.nms) ]
  stopifnot( length(out.vec)==var.nr )
  
  ##re-arrange vars by position
  data <- data[ , out.vec]
  return(data)
}


## Convert data from "Pathogenic Germline Variants in 10,389 Adult Cancers," Huang et al. 2019
## into a format that can be constructed.

dat <- readr::read_tsv("~/gromop/data/NIHMS957308-supplement-2.10k-germline-pathogenic.txt")

dat <- arrange_vars(dat, c("Chromosome"=1, "Start"=2, "Stop"=3, "Reference"=4, "Alternate"=5))

dat <- dat %>%
  rename(chrom=Chromosome,
         start_pos=Start,
         end_pos=Stop,
         ref=Reference,
         alt=Alternate)

dat <- dat %>% 
  mutate(COHORT="10K_Adult_Cancers_Germline_Variants_Huang_et_al_2019") %>%
  mutate(RISK = TRUE, DRIVER = FALSE)




