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

