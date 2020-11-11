#!/usr/bin/env Rscript
## count_variant_supports.R
## Reads in a transformed mpileup file
## and calculates the variant supporting reads
## for the pileup. 
## Prints a TSV with the counts information to stderr.

library(argparser)
library(readr)
library(dplyr)
library(stringr)

parser <- arg_parser("wsvc: A simple pileup-based variant caller.")

parser <- add_argument(parser, "--input", "A transformed mpileup file from which to call variants.", type="character", default="-")
#parser <- add_argument(parser, "--ploidy", "Estimated ploidy at the variant site.", default=2, type="numeric")
#parser <- add_argument(parser, "--allele", "The allele of interest", type="character")

argv <- parse_args(parser)

read_mpileup <- function(fname){
  x <- readr::read_tsv(fname)
  x <- x %>%
    rename(chrom=Chromosome,
           start_pos=Position,
           ref=REF,
           alt=ALT) %>%
    mutate(end_pos = max(start_pos + stringr::str_length(alt) - 1, start_pos + stringr::str_length(ref) - 1))
  return (x)
}

read_calls <- read_mpileup(argv$input)

counts <- read_calls %>%
  group_by(chrom, start_pos, end_pos, ref, alt, SAMPLE) %>%
  summarize(count = n()) %>%
  ungroup()

cat(readr::format_tsv(counts))
