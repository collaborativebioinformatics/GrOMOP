install.packages("pacman")
library(pacman)
p_load(tidyverse,devtools,data.table)

install_github("AndrewC160/ROMOPOmics",force=T)
library(ROMOPOmics)

#Data model.
dm_file     <- system.file("extdata","OMOP_CDM_v6_0_custom.csv",package="ROMOPOmics",mustWork = TRUE)
dm          <- loadDataModel(master_table_file = dm_file)
