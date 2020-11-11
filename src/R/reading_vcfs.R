#!/bin/Rscript

#Reading VCF files.
vcf_dir     <- "/projects/andrew/GrOMOP/test_data"
vcf_tbl     <- tibble(file=dir(vcf_dir,full.names = TRUE)) %>%
  filter(grepl("\\.vcf$|\\.vcf\\.gz$",file)) %>%
  mutate(name=gsub(".vcf|.vcf.gz","",basename(file))) %>%
  rowwise() %>%
  mutate(size=utils:::format.object_size(file.size(file),unit="auto"),
         gzipped = grepl(".gz$",file),
         hdr_lines=system(intern=TRUE,paste(ifelse(gzipped,"zcat","cat"),file,"| grep ^# | wc -l")),
         obs_lines=system(intern=TRUE,paste(ifelse(gzipped,"zcat","cat"),file,"| grep -v ^# | wc -l")))
library(vcfR)
#Read VCF:
vcf <- read.vcfR(vcf_tbl$file[2])
head(vcf)

#Get metadata:
queryMETA(vcf)
queryMETA(vcf,nice=FALSE)

#Get file info:
dat   <- gsub("#","",vcf@meta[grep("##file",vcf@meta)])
nms   <- str_extract(dat,"^[^=]+")
dat   <- set_names(str_extract(dat,"[^=]+$"),nms)

#Fixed info:
vcf@fix

#Genotype info:
vcf@gt


