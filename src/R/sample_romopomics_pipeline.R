install.packages("pacman")
library(pacman)
p_load(tidyverse,devtools,data.table,DBI)

install_github("AndrewC160/ROMOPOmics",force=T)
library(ROMOPOmics)

#Data model.
dm_file     <- system.file("extdata","OMOP_CDM_v6_0_custom.csv",package="ROMOPOmics",mustWork = TRUE)
dm          <- loadDataModel(master_table_file = dm_file)

#Mask file
msk_file    <- file.path("../../data/sample_mask.tsv")
msks <- loadModelMasks(msk_file)

#Sample file
in_file     <- file.path("../../data/sample.tsv")

#Put it all together
omop_inputs <- readInputFile(input_file=in_file,data_model=dm,mask_table=msks,transpose_input_table = T)

#Do the cha cha smooth
db_inputs   <- combineInputTables(input_table_list = omop_inputs)

#Bippity boppity boop
omop_db     <- buildSQLDBR(omop_tables = db_inputs, sql_db_file=file.path("../../data/sample.sqlite"))
DBI::dbDisconnect(omop_db)


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


