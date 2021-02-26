
# install needed packages
install.packages("magrittr")
install.packages("dplyr")
install.packages("plyr")
install.packages("xlsx")
install.packages("stringr")
install.packages("tm")
install.packages("writexl")
install.packages("binom")
install.packages("epiR")
options(java.parameters = "-Xmx1024m")
library(tm)
library(stringr)
library(xlsx)
library(plyr)
library(dplyr)
library(magrittr)
library(readxl)
library(writexl)
library(binom)
library(epiR)


# ---------------------------- The algorithm below checks for Uncertainty, Laterality, Temporality, Removal of Uncertainty within free-text diagnosis descriptions of the dataset
# --------------------------- The free-text modified descriptions are named "USER_EDITED_DIAGNOSIS_DESCRIPTION" 
# --------------------------- The standard diagnosis descriptions are named "DIAGNOSIS_NAME"

# read the file containing the dataset
dataset <- read_excel("path.xlsx")

# colname change
# change the column names of the free-text modified descriptions to USER_EDITED_DIAGNOSIS_DESCRIPTION and the standard diagnosis descriptions to DIAGNOSIS_NAME
colnames(dataset)[2] <- "USER_EDITED_DIAGNOSIS_DESCRIPTION" 
colnames(dataset)[3] <- "DIAGNOSIS_NAME"

# determine the total number of rows in the complete dataset
totalNumberofRows <- nrow(dataset)
totalNumberofRows

# Make all free-text default, modified descriptions and specialty names to lower cases for comparison
dataset$DIAGNOSIS_NAME <- tolower(dataset$DIAGNOSIS_NAME)
dataset$USER_EDITED_DIAGNOSIS_DESCRIPTION <- tolower(dataset$USER_EDITED_DIAGNOSIS_DESCRIPTION)
dataset$SPECIALTY_NAME_LAST_EDITING_USER <- tolower(dataset$SPECIALTY_NAME_LAST_EDITING_USER) # specialty names in the dataset


# Determine the total number and % of modified descriptions in the dataset
numberofEditedDescriptions <- sum(!is.na(dataset$USER_EDITED_DIAGNOSIS_DESCRIPTION))
numberofEditedDescriptions
percentageEdited <- (numberofEditedDescriptions/totalNumberofRows)*100
percentageEdited

# remove descriptions that are empty
datasetNoNA <- dataset[!is.na(dataset$USER_EDITED_DIAGNOSIS_DESCRIPTION),]
nrow(datasetNoNA)
# create a dataset that only contains the descriptions that are not similar compared to the default diagnosis description
datasetNew <- datasetNoNA[!(datasetNoNA$DIAGNOSIS_NAME == datasetNoNA$USER_EDITED_DIAGNOSIS_DESCRIPTION),] 
nrow(datasetNew) 
# determine the new number of modified descriptions (this should be similar to the number of rows)
numberofEditedDescriptions <- sum(!is.na(datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION))
numberofEditedDescriptions


# Create new columns for the determination of the categories Uncertainty, Laterality or Temporality, removal of Uncertainty and unclassified
datasetNew[c("Uncertainty","Laterality","Temporality", "removal", "Unclassified")] <- NA



# ---------------------- Regular expressions for Temporality and Laterality 
# finds any strings in the modified descriptions with Temporality 
checkTemporality <- grep(pattern ="(0?[1-9]|[12][0-9]|3[0-1])[-\\/](0?[1-9]|1[012])[-\\/](\\d\\d)", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkTemporality2 <- grep(pattern ="(0?[1-9]|[12][0-9]|3[0-1])[-\\/](0?[1-9]|1[012])[-\\/]((19|20)\\d\\d))", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkTemporality3 <- grep(pattern = "\\b(0?[1-9]|[12][0-9]|3[01])[-\\/](0?[1-9]|1[012])\\b", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkTemporality4 <- grep(pattern = "(0?[1-9]|1[012])[-\\/]((19|20)\\d\\d)", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkTemporality5 <- grep(pattern = "(0?[1-9]|1[012])[-\\/]((19|20)\\d\\d)", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkTemporality6 <- grep(pattern ="(19|20)\\d{2}", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkTemporality7 <- grep(pattern = "\\b(jan|feb|aug|sept|okt|nov|dec)\\b", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkTemporality8 <- grep(pattern = "\\b(januari|februari|maart|april|mei|juni|juli|augustus|september|oktober|november|december)\\b", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)

# returns true in a new column 'Temporality' if one of the strings is true,  NA if no value is present and remain false if neither of the strings are true
datasetNew$Temporality = FALSE
datasetNew$Temporality[checkTemporality] = TRUE
datasetNew$Temporality[checkTemporality2] = TRUE
datasetNew$Temporality[checkTemporality3] = TRUE
datasetNew$Temporality[checkTemporality4] = TRUE
datasetNew$Temporality[checkTemporality5] = TRUE
datasetNew$Temporality[checkTemporality6] = TRUE
datasetNew$Temporality[checkTemporality7] = TRUE
datasetNew$Temporality[checkTemporality8] = TRUE
datasetNew$Temporality[is.na(datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)] = NA


# finds any strings in the modified descriptions with Laterality 
checkLaterality <- grep(pattern ="\\b(r|re|li|lnks|od|ad|os|as|ods|ads|bdz|bdzs)\\b",datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkLaterality2 <- grep(pattern = "(rechts|rechter|linker|links|sinister|sinistra|dexter|dextra|beide|unilatera.*|bilatera.*|bifrontaal|beiderzijds)", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkLaterality3 <- grep(pattern="\\b[^\\/\\d\\w]l\\b", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkLaterality4 <- grep(pattern = "\\bl[^\\/\\d\\w]\\b", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)


# returns true in a new column 'Laterality' if one of the strings is true,  NA if no value is present and remains false if neither of the strings are true
datasetNew$Laterality = FALSE
datasetNew$Laterality[checkLaterality] = TRUE 
datasetNew$Laterality[checkLaterality2] = TRUE 
datasetNew$Laterality[checkLaterality3] = TRUE 
datasetNew$Laterality[checkLaterality4] = TRUE 
datasetNew$Laterality[is.na(datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)] = NA

# --------------- Regular expressions for Uncertainty
# finds any strings in the modified descriptions with Uncertainty. This will also be used for 'removal of Uncertainty'
checkUncertainty <- grep(pattern = "verdenk.*",  datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkUncertainty2 <- grep(pattern = "beoordel.*", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkUncertainty3 <- grep(pattern = "onderzoe.*", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkUncertainty4 <- grep(pattern = "erfelijk.*", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkUncertainty5 <- grep(pattern = "screen.*", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION) 
checkUncertainty6 <- grep(pattern="potentie.*", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION) 
checkUncertainty7 <- grep(pattern="^waarschijnlijk*",  datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION) 
checkUncertainty8 <- grep(pattern="niet bevestigd",  datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkUncertainty9 <- grep(pattern = "niet zeker",  datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkUncertainty10 <- grep(pattern ="^mogelijk.*", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION) 
checkUncertainty11 <- grep(pattern = "vermoed.*", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkUncertainty12 <- grep(pattern = "analyse", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION) 
checkUncertainty13 <- grep(pattern="vraag", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkUncertainty14 <- grep(pattern="\\?", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)
checkUncertainty15 <- grep(pattern="advies", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION) 
checkUncertainty16 <- grep(pattern = "^wrs", datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION) 
checkDiagnosisVerdenking <- grep(pattern = "verdenk.*", datasetNew$DIAGNOSIS_NAME) # This will be used later as there will only be a uncertainty when "verdenk" is not present in diagnosis name
checkDiagnosisPotentieel <- grep(pattern="potentie.*", datasetNew$DIAGNOSIS_NAME) # This will be used later as there will only be a uncertainty when "potent" is not present in diagnosis name
checkDiagnosisScreening <- grep(pattern="screen.*", datasetNew$DIAGNOSIS_NAME) # This will be used later as there will only be a uncertainty when "screen." is not present in diagnosis name
checkDiagnosisAnalyse <- grep(pattern="analyse", datasetNew$DIAGNOSIS_NAME) # This will be used later as there will only be a uncertainty when "analyse" is not present in diagnosis name
checkDiagnosisAdvies <- grep(pattern="advies", datasetNew$DIAGNOSIS_NAME) # This will be used later as there will only be a uncertainty when "advies" is not present in diagnosis name

# returns true in a new column 'Uncertainty' if one of the strings is true,  NA if no value is present and remain false if neither of the strings are true
datasetNew$Uncertainty = FALSE
datasetNew$Uncertainty[checkUncertainty]=TRUE
datasetNew$Uncertainty[checkUncertainty2]=TRUE
datasetNew$Uncertainty[checkUncertainty3]=TRUE
datasetNew$Uncertainty[checkUncertainty4]=TRUE
datasetNew$Uncertainty[checkUncertainty5]=TRUE
datasetNew$Uncertainty[checkUncertainty6]=TRUE
datasetNew$Uncertainty[checkUncertainty7]=TRUE
datasetNew$Uncertainty[checkUncertainty8]=TRUE
datasetNew$Uncertainty[checkUncertainty9]=TRUE
datasetNew$Uncertainty[checkUncertainty10]=TRUE
datasetNew$Uncertainty[checkUncertainty11]=TRUE
datasetNew$Uncertainty[checkUncertainty12]=TRUE
datasetNew$Uncertainty[checkUncertainty13]=TRUE
datasetNew$Uncertainty[checkUncertainty14]=TRUE
datasetNew$Uncertainty[checkUncertainty15]=TRUE
datasetNew$Uncertainty[checkUncertainty16]=TRUE
datasetNew$Uncertainty[is.na(datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)] = NA

# comparisons between default diagnoses and modified descriptions
# create new columns so these values can be compared
# UncertaintyD (verdenk), UncertaintyD5 (screen), UncertaintyD10 (mogelijk), UncertaintyD12 (analyse), UncertaintyD15 (advies) are usually present with 'verdenking' in diagnosis name 
datasetNew[c("checkUncertaintyD","checkUncertainty5D","checkUncertainty6D", "checkUncertainty12D", "checkUncertainty10D","checkUncertainty15D", "checkPotentieel","checkScreening", "checkAnalyse", "checkAdvies", "checkDiagnosis")] <- NA
datasetNew$checkUncertaintyD=FALSE
datasetNew$checkUncertainty5D=FALSE
datasetNew$checkUncertainty12D=FALSE
datasetNew$checkUncertainty10D=FALSE
datasetNew$checkUncertainty15D=FALSE
datasetNew$checkUncertainty6D=FALSE
datasetNew$checkDiagnosis=FALSE
datasetNew$checkPotentieel=FALSE
datasetNew$checkScreening=FALSE
datasetNew$checkAdvies=FALSE
datasetNew$checkAnalyse=FALSE

# fill columns with true if the Uncertainties are true
datasetNew$checkUncertaintyD[checkUncertainty]=TRUE
datasetNew$checkUncertainty5D[checkUncertainty5]=TRUE
datasetNew$checkUncertainty12D[checkUncertainty12]=TRUE
datasetNew$checkUncertainty10D[checkUncertainty10]=TRUE
datasetNew$checkUncertainty15D[checkUncertainty15]=TRUE
datasetNew$checkDiagnosis[checkDiagnosisVerdenking]=TRUE
datasetNew$checkUncertainty6D[checkUncertainty6]=TRUE
datasetNew$checkPotentieel[checkDiagnosisPotentieel]=TRUE
datasetNew$checkScreening[checkDiagnosisScreening]=TRUE
datasetNew$checkAdvies[checkDiagnosisAdvies]=TRUE
datasetNew$checkAnalyse[checkDiagnosisAnalyse]=TRUE


# check verdenking 
# Uncertainty is FALSE if 'verdenking' is present in both diagnosis name and user edited description
# Uncertainty is FALSE if 'verdenking' is present in in diagnosis name in combination with screening, verdenking, mogelijk, analyse or advies in the user edited description 
# Uncertainty is FALSE if 'potentieel' is present in both diagnosis name & user edited description
datasetNew$Uncertainty[datasetNew$checkUncertaintyD & datasetNew$checkDiagnosis]=FALSE
datasetNew$Uncertainty[datasetNew$checkUncertainty5D & datasetNew$checkDiagnosis]=FALSE
datasetNew$Uncertainty[datasetNew$checkUncertainty12D & datasetNew$checkDiagnosis]=FALSE
datasetNew$Uncertainty[datasetNew$checkUncertainty10D & datasetNew$checkDiagnosis]=FALSE
datasetNew$Uncertainty[datasetNew$checkUncertainty15D & datasetNew$checkDiagnosis]=FALSE 
datasetNew$Uncertainty[datasetNew$checkUncertainty6D & datasetNew$checkPotentieel]=FALSE

# check screening
# Uncertainty = FALSE if 'screening' present in both diagnosis name and user edited description
# Uncertainty = FALSE if 'screening' is present with 'verdenking'
datasetNew$Uncertainty[datasetNew$checkUncertainty5D & datasetNew$checkScreening]=FALSE
datasetNew$Uncertainty[datasetNew$checkUncertaintyD & datasetNew$checkScreening]=FALSE

# check advies
# Uncertainty = FALSE if 'advies' is present in both diagnosis name and user edited description
# Uncertainty = FALSE if 'advies' is present in diagnosis name and 'screening' in user edited description
datasetNew$Uncertainty[datasetNew$checkUncertainty15D & datasetNew$checkAdvies]=FALSE
datasetNew$Uncertainty[datasetNew$checkUncertainty5D & datasetNew$checkAdvies]=FALSE 


# check analyse
# Uncertainty = FALSE if 'analyse' is present in diagnosis name and user edited description
# Uncertainty = FALSE if 'analyse' is present in diagnosis name and 'advies' in user edited description
# Uncertainty = FALSE if 'analyse' is present in diagnosis name and 'screening' in user edited description
datasetNew$Uncertainty[datasetNew$checkUncertainty12D & datasetNew$checkAnalyse]=FALSE
datasetNew$Uncertainty[datasetNew$checkUncertainty15D & datasetNew$checkAnalyse]=FALSE
datasetNew$Uncertainty[datasetNew$checkUncertainty5D & datasetNew$checkAnalyse]=FALSE

#---------- semantic: removal of Uncertainty
datasetNew$removal=FALSE
# check 'verdenking'-removal
# removal is TRUE if verdenking, screening, mogelijk, analyse, advies is present in  diagnosis name and NOT user edited description
# removal is FALSE if verdenking, screening, mogelijk, analyse, advies is present in  diagnosis name AND user edited description
datasetNew$removal[!datasetNew$checkUncertaintyD & datasetNew$checkDiagnosis]=TRUE
datasetNew$removal[!datasetNew$checkUncertainty15D & datasetNew$checkDiagnosis]=TRUE
datasetNew$removal[!datasetNew$checkUncertainty5D & datasetNew$checkDiagnosis]=TRUE
datasetNew$removal[!datasetNew$checkUncertainty12D & datasetNew$checkDiagnosis]=TRUE
datasetNew$removal[!datasetNew$checkUncertainty10D & datasetNew$checkDiagnosis]=TRUE
datasetNew$removal[datasetNew$checkUncertaintyD & datasetNew$checkDiagnosis]=FALSE
datasetNew$removal[datasetNew$checkUncertainty15D & datasetNew$checkDiagnosis]=FALSE 
datasetNew$removal[datasetNew$checkUncertainty5D & datasetNew$checkDiagnosis]=FALSE
datasetNew$removal[datasetNew$checkUncertainty12D & datasetNew$checkDiagnosis]=FALSE
datasetNew$removal[datasetNew$checkUncertainty10D & datasetNew$checkDiagnosis]=FALSE

# check potentieel-removal
# removal is TRUE if potentieel is present in diagnosis name, and NOT in user edited description
# removal is FALSE if  potentieel is present in diagnosis name AND in user edited description 
datasetNew$removal[!datasetNew$checkUncertainty6D & datasetNew$checkPotentieel]=TRUE
datasetNew$removal[datasetNew$checkUncertainty6D & datasetNew$checkPotentieel]=FALSE

# check screening-removal
# removal is TRUE if screening is present in diagnosis name, and NOT in user edited description
# removal is FALSE if screening is  present in diagnosis name AND user edited description
# removal is FALSE if screening is present in diagnosis name, and verdenking in the user edited description
datasetNew$removal[!datasetNew$checkUncertainty5D & datasetNew$checkScreening]=TRUE
datasetNew$removal[datasetNew$checkUncertainty5D & datasetNew$checkScreening]=FALSE
datasetNew$removal[datasetNew$checkUncertaintyD & datasetNew$checkScreening]=FALSE

# check advies-removal
# removal is TRUE if advies is present in diagnosis name and NOT in uses edited description
# removal is FALSE if advies is present in diagnosis name AND in user edited description
# removal is FALSE if advies is present in diagnosis name and screening in user edited description
datasetNew$removal[!datasetNew$checkUncertainty15D & datasetNew$checkAdvies]=TRUE
datasetNew$removal[datasetNew$checkUncertainty15D & datasetNew$checkAdvies]=FALSE 
datasetNew$removal[datasetNew$checkUncertainty5D & datasetNew$checkAdvies]=FALSE 

# check analyse-removal
# removal is TRUE if analyse is present in diagnosis name and NOT in user edited description
# removal is FALSE if analyse is present in diagnosis name AND in user edited description
# removal is FALSE if analyse is present in diagnosis name and advies in user edited description
# removal is FALSE if analyse is present in diagnosis name and screening in user edited description
datasetNew$removal[!datasetNew$checkUncertainty12D & datasetNew$checkAnalyse]=TRUE 
datasetNew$removal[datasetNew$checkUncertainty12D & datasetNew$checkAnalyse]=FALSE 
datasetNew$removal[datasetNew$checkUncertainty15D & datasetNew$checkAnalyse]=FALSE 
datasetNew$removal[datasetNew$checkUncertainty5D & datasetNew$checkAnalyse]=FALSE 

datasetNew$removal[is.na(datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)] = NA


# --------------- determine unclassified 
# Unclassified: Uncertainty, removal Uncertainty, history and laterality are all false
datasetNew$Unclassified=FALSE
datasetNew$Unclassified[!datasetNew$Uncertainty & !datasetNew$Laterality & !datasetNew$Temporality & !datasetNew$removal]=TRUE
datasetNew$Unclassified[is.na(datasetNew$USER_EDITED_DIAGNOSIS_DESCRIPTION)] = NA




# --------------- determine the percentages of Uncertainty, Laterality, Temporality,  removal of Uncertainty and Unclassified
# count the number of times 'true' is present in Uncertainty, Laterality, Temporality, removal of Uncertainty and Unclassified
countUncertainty <- sum(datasetNew$Uncertainty, na.rm=TRUE)
countLaterality <- sum(datasetNew$Laterality, na.rm=TRUE)
countTemporality <- sum(datasetNew$Temporality, na.rm=TRUE)
countRemovalUncertainty <- sum(datasetNew$removal, na.rm=TRUE)
countUnclassified <- sum(datasetNew$Unclassified, na.rm=TRUE)

# calculate the percentages
percentageUncertainty <- (countUncertainty/numberofEditedDescriptions) *100
countUncertainty
percentageUncertainty
percentageLaterality <- (countLaterality/numberofEditedDescriptions) *100
countLaterality
percentageLaterality
percentageTemporality <- (countTemporality/numberofEditedDescriptions) *100
countTemporality
percentageTemporality
percentageRemovalUncertainty <- (countRemovalUncertainty/numberofEditedDescriptions)*100
countRemovalUncertainty
percentageRemovalUncertainty
percentageUnclassified <- (countUnclassified/numberofEditedDescriptions)*100
countUnclassified
percentageUnclassified

#---------------------------------determine the numbers and percentages of the contextual properties per specialty
# determine the number of times 'TRUE' is present in Uncertainty, Laterality, Temporality and removal of Uncertainty for each specialty
# determine the percentage of TRUE from Uncertainty, Laterality, removal of Uncertainty and Temporality per specialty
# SPECIALTY_NAME_LAST_EDITING_USER = column name that includes the specialty names
contextualPropertiesPerSpecialty <- ddply(datasetNew, ~datasetNew$SPECIALTY_NAME_LAST_EDITING_USER,summarise, 
                                          number_of_Uncertainty=sum(Uncertainty, na.rm=TRUE), 
                                          number_of_Laterality=sum(Laterality, na.rm=TRUE), 
                                          number_of_Temporality=sum(Temporality, na.rm=TRUE), 
                                          number_of_removals=sum(removal, na.rm=TRUE),
                                          number_of_diagnoses=length(DIAGNOSIS_NAME),  
                                          number_of_edited_descriptions=length(which(!is.na(USER_EDITED_DIAGNOSIS_DESCRIPTION))),
                                          percentage_removal=(number_of_removals/number_of_edited_descriptions)*100,
                                          percentage_Uncertainty=(number_of_Uncertainty/number_of_edited_descriptions)*100, 
                                          percentage_Laterality=(number_of_Laterality/number_of_edited_descriptions)*100, 
                                          percentage_Temporality=(number_of_Temporality/number_of_edited_descriptions)*100)
View(contextualPropertiesPerSpecialty)

# write the file to an Excel file
write.xlsx(contextualPropertiesPerSpecialty,"path.xlsx")

