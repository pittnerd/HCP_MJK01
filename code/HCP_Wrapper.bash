#!/bin/bash 
#20171107-MJ need this command so you don't use all the cores and make Bert :(
FSLPARALLEL=8; export FSLPARALLEL
#NDT October 2017
#Set Variables needed to specify input/output directories and files
HCPscriptsDirectory='/data/MRI/code/HCP_Pipelines/Examples/Scripts' #the HCP scripts directory
dcmDir='/opt/ni_tools/dcm2niix/build/bin' #for getting bval and bvec valuesSubj
HcpDir='/data/MRI/Maria_K01/HCPproc' #the directory where all the output files are stored
BidsDir='/data/MRI/Maria_K01/bids' #the directory that the HcpDir files are linked to
RawDir='/data/MRI/Maria_K01/raw' #the raw directory, populated from the original MRRC scan files
#Subjectlist='sub-1508' #the list of subjects to process could be a space-deliminated list
#SessionList='ses-20170828'
Subjectlist="$@" #this will import command line arguements into one list
#Subjectlist=$1; shift #TODO: make this into a space-delimited list
#SessionList=$1; shift

####echo some Warnings:
echo "Did you define Gradient Distortion Coefficients in /data/MRI/code/HCP_Pipeliens/Examples/Scripts/GenericfMRIVolumeProcessingPipelineBatch_MJK01_HCPproc.sh...?"
echo "Did you set the Phase Encoding Direction in /data/MRI/code/HCP_Pipeliens/Examples/Scripts/GenericfMRIVolumeProcessingPipelineBatch_MJK01_HCPproc.sh ...?"

########################################################
###### BEGIN LOOPING THROUGH SUBJECTS and SESSIONS######
########################################################
for Subject in $Subjectlist ; do #<<<<START SUBJECT LOOP #TODO: Make this into a space-delimited list
rawSub=${Subject:4} #remove the first 4 characters of the string
session_files=$(find $RawDir -maxdepth 1 -type d -iname "${rawSub}_*") #look for any file folders in the raw directory that belong to this Subject
for Session in $session_files ; do  #<<<<START SESSION LOOP (this exists here for book-keeping purposes (i.e converting files, making
rawSes=$(tail -c-9 <<< $Session) #extract the last characters 8 characters (yes, it says '9' but its actually 8)
Session=ses-${rawSes} #build the $Session variable
echo $Subject $rawSes

###### STEP 1:
###### Extract necessary information from raw directory and put into bids directory######
#########################################################################################

#Get Free Surfer Files from Raw to Bids (or FauxBids)
mkdir -p ${BidsDir}/${Subject}/${Session}/anat #make the anat directory to house the T1 and T2 files # -p: make parent directoires too
mkdir -p ${BidsDir}/${Subject}/${Session}/fmap #make the fmap directory to house the field map magnitude and phase files
#T1 files
rawT1dir1=$(ls -v -d ${RawDir}/${rawSub}_${rawSes}/T1w_MPR_320x300*/|tail -n1) #look for the rawmprage file with biggest end number
rawT1=$(basename ${rawT1dir1})
dcmstack \
--include '.*' --file-ext 'MR*' --embed-meta \
-o ${Subject}_${Session}_T1w_raw --dest-dir ${BidsDir}/$Subject/$Session/anat \
${RawDir}/${rawSub}_${rawSes}/${rawT1}
nitool dump ${BidsDir}/$Subject/$Session/anat/${Subject}_${Session}_T1w_raw.nii.gz ${BidsDir}/$Subject/$Session/anat/${Subject}_${Session}_T1w_raw.json
#T2 files
rawT2dir1=$(ls -v -d ${RawDir}/${rawSub}_${rawSes}/T2w_SPC_320x300*/|tail -n1) #look for the rawmprage file with biggest end number
rawT2=$(basename ${rawT2dir1})
dcmstack \
--include '.*' --file-ext 'MR*' --embed-meta \
-o ${Subject}_${Session}_T2w_raw --dest-dir ${BidsDir}/$Subject/$Session/anat \
${RawDir}/${rawSub}_${rawSes}/${rawT2}
nitool dump ${BidsDir}/$Subject/$Session/anat/${Subject}_${Session}_T2w_raw.nii.gz ${BidsDir}/$Subject/$Session/anat/${Subject}_${Session}_T2w_raw.json
#FIELD MAPS (FM) getting phase and magnitude file...
FM_MAG=$(ls -v -d ${RawDir}/${rawSub}_${rawSes}/FieldMap_104x90.*| head -n1) #finds FieldMap_104x90."LOWER VALUE" 
FM_PHASE=$(ls -v -d  ${RawDir}/${rawSub}_${rawSes}/FieldMap_104x90.*|tail -n1)  #finds FieldMap_104x90."HIGHER VALUE" 
#gradient field map magnitude
dcmstack \
--include '.*' --file-ext 'MR*' --embed-meta \
-o ${Subject}_${Session}_fm_mag   --dest-dir ${BidsDir}/${Subject}/${Session}/fmap ${FM_MAG}
nitool dump ${BidsDir}/${Subject}/${Session}/fmap/${Subject}_${Session}_fm_mag.nii.gz ${BidsDir}/${Subject}/${Session}/fmap/${Subject}_${Session}_fm_mag.json
#gradient field map phase
dcmstack \
--include '.*' --file-ext 'MR*' --embed-meta \
-o ${Subject}_${Session}_fm_phase   --dest-dir ${BidsDir}/${Subject}/${Session}/fmap ${FM_PHASE}
nitool dump ${BidsDir}/${Subject}/${Session}/fmap/${Subject}_${Session}_fm_phase.nii.gz ${BidsDir}/${Subject}/${Session}/fmap/${Subject}_${Session}_fm_phase.json

#Get Volume/Surface Files from Raw to Bids (or FauxBids) 
mkdir ${BidsDir}/${Subject}/${Session}/func	#make a func directory for the BOLD scans
mkdir ${BidsDir}/${Subject}/${Session}/fauxbids-se	#make a directory to put the SBREF files
#BOLD task-1
dcmstack \
--include '.*' --file-ext 'MR*' --embed-meta \
-o ${Subject}_${Session}_task-rest1_bold --dest-dir ${BidsDir}/${Subject}/${Session}/func ${RawDir}/${rawSub}_${rawSes}/BOLD_REST_1_936x936.*
nitool dump ${BidsDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest1_bold.nii.gz ${BidsDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest1_bold.json
#BOLD task-2
dcmstack \
--include '.*' --file-ext 'MR*' --embed-meta \
-o ${Subject}_${Session}_task-rest2_bold --dest-dir ${BidsDir}/${Subject}/${Session}/func ${RawDir}/${rawSub}_${rawSes}/BOLD_REST_2_936x936.*
nitool dump ${BidsDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest2_bold.nii.gz ${BidsDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest2_bold.json
#SBRef task-1
dcmstack \
--include '.*' --file-ext 'MR*' --embed-meta \
-o ${Subject}_${Session}_task-rest1_sbref --dest-dir ${BidsDir}/${Subject}/${Session}/func ${RawDir}/${rawSub}_${rawSes}/BOLD_REST_1_SBRef_936x936.*
nitool dump ${BidsDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest1_sbref.nii.gz ${BidsDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest1_sbref.json
#SBRef task-2
dcmstack \
--include '.*' --file-ext 'MR*' --embed-meta \
-o ${Subject}_${Session}_task-rest2_sbref --dest-dir ${BidsDir}/${Subject}/${Session}/func ${RawDir}/${rawSub}_${rawSes}/BOLD_REST_2_SBRef_936x936.*
nitool dump ${BidsDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest2_sbref.nii.gz ${BidsDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest2_sbref.json
#spin echo field map -AP (Neg: task1)
dcmstack \
--include '.*' --file-ext 'MR*' --embed-meta \
-o ${Subject}_${Session}_se_fm_AP  --dest-dir ${BidsDir}/${Subject}/${Session}/fauxbids-se ${RawDir}/${rawSub}_${rawSes}/SpinEchoFieldMap_1_936x936.*
nitool dump ${BidsDir}/${Subject}/${Session}/fauxbids-se/${Subject}_${Session}_se_fm_AP.nii.gz ${BidsDir}/${Subject}/${Session}/fauxbids-se/${Subject}_${Session}_se_fm_AP.json
#spin echo field map -PA (Pos: task2)
dcmstack \
--include '.*' --file-ext 'MR*' --embed-meta \
-o ${Subject}_${Session}_se_fm_PA  --dest-dir ${BidsDir}/${Subject}/${Session}/fauxbids-se ${RawDir}/${rawSub}_${rawSes}/SpinEchoFieldMap_2_936x936.*
nitool dump ${BidsDir}/${Subject}/${Session}/fauxbids-se/${Subject}_${Session}_se_fm_PA.nii.gz ${BidsDir}/${Subject}/${Session}/fauxbids-se/${Subject}_${Session}_se_fm_PA.json

#Get Diffusion Files from Raw to Bids (or FauxBids)
mkdir $BidsDir/$Subject/$Session/fauxbids-dwi #the final folder is made by cp using -r
mkdir $BidsDir/$Subject/$Session/fauxbids-dwi #the final folder is made by cp using -r
cp -r $RawDir/${rawSub}_${rawSes}/dMRI_dir98_1_936x936.* $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP
cp -r $RawDir/${rawSub}_${rawSes}/dMRI_dir98_2_936x936.* $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA
${dcmDir}/dcm2niix $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP #Convert files
${dcmDir}/dcm2niix $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA #Convdrt files
rm -r $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP/dMRI_dir* #remove useless old files
rm -r $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA/dMRI_dir* #remove useless old files
#rename the bval and bvec files in the AP folders
mv $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP/*.bval $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP/"${Subject}_${Session}_dMRI1_AP.bval"
mv $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP/*.bvec $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP/"${Subject}_${Session}_dMRI1_AP.bvec"
mv $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP/*.nii $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP/"${Subject}_${Session}_dMRI1_AP.nii"
mv $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP/*.json $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP/"${Subject}_${Session}_dMRI1_AP.json"
#rename the bval and bvec files in the PA folders
mv $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA/*.bval $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA/"${Subject}_${Session}_dMRI2_PA.bval"
mv $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA/*.bvec $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA/"${Subject}_${Session}_dMRI2_PA.bvec"
mv $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA/*.nii $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA/"${Subject}_${Session}_dMRI2_PA.nii"
mv $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA/*.json $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA/"${Subject}_${Session}_dMRI2_PA.json"

###### STEP 2:
###### Establish files and file structure of HCPproc needed for pipeline steps ######
#####################################################################################
mkdir -p ${HcpDir}/${Subject}/${Session}

#Establish FreeSurfer Inputs	
mkdir ${HcpDir}/${Subject}/${Session}/T1w #make a T1w directory
mkdir ${HcpDir}/${Subject}/${Session}/T2w  #make a T2w directory
ln -s ${BidsDir}/${Subject}/${Session}/anat/${Subject}_${Session}_T1w_raw.nii.gz ${HcpDir}/${Subject}/${Session}/T1w/${Subject}_${Session}_T1w_raw.nii.gz #populate the T1w with the T1 file
ln -s ${BidsDir}/${Subject}/${Session}/anat/${Subject}_${Session}_T2w_raw.nii.gz ${HcpDir}/${Subject}/${Session}/T2w/${Subject}_${Session}_T2w_raw.nii.gz #populate the T2w with the T2 file
mkdir ${HcpDir}/${Subject}/${Session}/gradient_fm #make a gradient field map directory
ln -s "${BidsDir}/${Subject}/${Session}/fmap/${Subject}_${Session}_fm_mag.nii.gz" "${HcpDir}/${Subject}/${Session}/gradient_fm/${Subject}_${Session}_fm_mag.nii.gz" 
ln -s "${BidsDir}/${Subject}/${Session}/fmap/${Subject}_${Session}_fm_phase.nii.gz" "${HcpDir}/${Subject}/${Session}/gradient_fm/${Subject}_${Session}_fm_phase.nii.gz" 
	
#Establish Volume/Surface Processing Inputs
mkdir ${HcpDir}/${Subject}/${Session}/func	#make a func directory for the BOLD scans and SBREF files
mkdir ${HcpDir}/${Subject}/${Session}/fauxbids-se	#make a directory to put the Spin Echo files
ln -s ${BidsDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest1_bold.nii.gz ${HcpDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest1_bold.nii.gz #populate the func folder with the bold rest 1 file
ln -s ${BidsDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest2_bold.nii.gz ${HcpDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest2_bold.nii.gz #populate the func folder with the bold rest 2 file
ln -s ${BidsDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest1_sbref.nii.gz ${HcpDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest1_sbref.nii.gz #populate the func folder with a single-band reference file for rest 1
ln -s ${BidsDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest2_sbref.nii.gz ${HcpDir}/${Subject}/${Session}/func/${Subject}_${Session}_task-rest2_sbref.nii.gz #populate the func folder with a single-band reference file for rest 2
ln -s ${BidsDir}/${Subject}/${Session}/fauxbids-se/${Subject}_${Session}_se_fm_AP.nii.gz ${HcpDir}/${Subject}/${Session}/fauxbids-se/${Subject}_${Session}_se_fm_AP.nii.gz #populate the fake (faux) bids-like folder with a spin echo field map (negative)
ln -s ${BidsDir}/${Subject}/${Session}/fauxbids-se/${Subject}_${Session}_se_fm_PA.nii.gz ${HcpDir}/${Subject}/${Session}/fauxbids-se/${Subject}_${Session}_se_fm_PA.nii.gz #populate the fake (faux) bids-like folder with a spin echo field map (positive)

#Establish Diffusion Inputs
mkdir ${HcpDir}/${Subject}/${Session}/dMRI1_AP	
mkdir ${HcpDir}/${Subject}/${Session}/dMRI2_PA	
ln -s $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP/${Subject}_${Session}_dMRI1_AP.nii ${HcpDir}/${Subject}/${Session}/dMRI1_AP/${Subject}_${Session}_dMRI1_AP.nii #negative encoding dwi file
ln -s $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP/${Subject}_${Session}_dMRI1_AP.bval ${HcpDir}/${Subject}/${Session}/dMRI1_AP/${Subject}_${Session}_dMRI1_AP.bval #negative encoding bval file
ln -s $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI1_AP/${Subject}_${Session}_dMRI1_AP.bvec ${HcpDir}/${Subject}/${Session}/dMRI1_AP/${Subject}_${Session}_dMRI1_AP.bvec #negative encoding bvec file	
ln -s $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA/${Subject}_${Session}_dMRI2_PA.nii ${HcpDir}/${Subject}/${Session}/dMRI2_PA/${Subject}_${Session}_dMRI2_PA.nii #positive encoding dwi file
ln -s $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA/${Subject}_${Session}_dMRI2_PA.bval ${HcpDir}/${Subject}/${Session}/dMRI2_PA/${Subject}_${Session}_dMRI2_PA.bval #positive encoding bval file
ln -s $BidsDir/$Subject/$Session/fauxbids-dwi/dMRI2_PA/${Subject}_${Session}_dMRI2_PA.bvec  ${HcpDir}/${Subject}/${Session}/dMRI2_PA/${Subject}_${Session}_dMRI2_PA.bvec #positive encoding bvec file

done #<<<<END OF SESSION LOOP (session loops also exist in every "batch" scripts below)

###### STEP 3: "Do Work"
###### CALL HCP PIPELINE BATCH SCRIPTS ######
#############################################
#TODO: Figure out why nifti files are being cp'd and renamed (duplicates created by Volume Processing?  ...files sizes don't match!!)

#call the MJK01_HCPproc version of PreFreeSurferPipelineBatch
${HCPscriptsDirectory}/PreFreeSurferPipelineBatch_MJK01_HCPproc.sh \
			--StudyFolder="$HcpDir" \
			--Subject="$Subject"

	#fixing a strange problem with the way the files are named below... NDT 9/29/17
	#problems=$(ls $HcpDir/${Subject}/*/*/*.nii.gz*.nii.gz) #this will find all the files with this erroneous patterns within the specific Subject-#Session folder (don't do this to the entire HCPDir as it will alter other processes)
	#for text in $problems ; do #this will loop through
	#text2=${text/.nii.gz/} #get the filename and create a new string (text2) that doesn't have the first ".nii.gz"
	#mv $text $text2 #then rename the file using mv to be the new string
	#done

#call the MJK01_HCPproc version of FreeSurferPipelineBatch
${HCPscriptsDirectory}/FreeSurferPipelineBatch_MJK01_HCPproc.sh \
			--StudyFolder="$HcpDir" \
			--Subject="$Subject"

#call the MJK01_HCPproc version of PostFreeSurferPipelineBatch
${HCPscriptsDirectory}/PostFreeSurferPipelineBatch_MJK01_HCPproc.sh \
			--StudyFolder="$HcpDir" \
			--Subject="$Subject"

#call the MJK01_HCPproc version of VolumeProcessingPipelineBatch
${HCPscriptsDirectory}/GenericfMRIVolumeProcessingPipelineBatch_MJK01_HCPproc.sh \
			--StudyFolder="$HcpDir" \
			--Subject="$Subject"

#call the MJK01_HCPproc version of SurfaceProcessingPipelineBatch
${HCPscriptsDirectory}/GenericfMRISurfaceProcessingPipelineBatch_MJK01_HCPproc.sh \
			--StudyFolder="$HcpDir" \
			--Subject="$Subject"

#call the MJK01_HCPproc version of DiffusionProcessingPipelineBatch
${HCPscriptsDirectory}/DiffusionPreprocessingBatch_MariaK01_HCPproc.sh \
			--StudyFolder="$HcpDir" \
			--Subject="$Subject"

done #<<<<END SUBJECT LOOP

