#!/bin/bash

########################################################
##						                              ##
## This script allows users to download some XML file ##
## from a specified endpoint and to upload them into  ##
## an SOS                                             ##
##                                                    ##
########################################################
##						                              ##
## AUTHOR: Simone Lella				                  ##
## CONTACT: lella.s@irea.cnr.it			              ##
## IREA - CNR ©					                      ##
##    		  				                          ##
########################################################

### Fare controllo se il file error.txt è vuoto
### se non lo è ciclo per i nomi elencati e riprovo a caricare gli XML
### se non dà errori elimino il file XML dalla cartella error e dal file error.txt
### e scrivo nel log che il caricamento è andato a buon fine
### se dà errori scrivo nel log che ha dato nuovamente errori
### e lo elimino dalla cartella in modo che sia riscaricato


# Default directory where save XML. This folder can be changed
downloadDir=/home/$USER/upload_observations/
errorDir=$downloadDir/error
# Directory where scritp is saved
scriptDir=`pwd`
# Default URL of SOS
urlsos=http://sos-getit.irea.mi/observations/sos

# Check if the directory where save XML exsists. If exists, all subdirectory and default files are existing
if [ -d $downloadDir ]; then
    echo ""
    else
    # Create directory where download XML
    mkdir $downloadDir
    # Create directory where move files with SOS upload error
    mkdir $errorDir
    # Create file with the history of downloaded files
    touch $downloadDir/historydownloadedfiles.txt
fi

# Users can enter the path where download and save XML files
#echo -en "Inserire il percorso in cui salvare i file scaricati [$downloadDir] "

#read downloadDir

# If left empty, the default directory will be used
#if [ -z $downloadDir ]; then
#	downloadDir=/home/$USER/upload_observations/
#	echo Path : $downloadDir
	# Check if the directory exists
#	if [ -d $downloadDir ]; then
#		echo "Folder $downloadDir exists"
#		else
		# If the directory doesn't exist, it will be created
#		mkdir $downloadDir
#	fi
#else
#	echo "Path : $downloadDir"
#fi


# Users can enter the URL to the SOS service 
#echo -en "Inserire l'url del SOS  [$urlsos] "

#read urlsos 

#if [ -z $urlsos ]; then
#	urlsos=http://sos-getit.irea.mi/observations/sos
#	echo "L'URL è: $urlsos"
#else
#	echo "L'URL è : $urlsos"
#fi



# Access the folder where XML will be saved
cd $downloadDir
# Begin procedure date and time
begindate=$(date +"%Y-%m-%d-%T")
echo -e "\n\n [ $begindate ] ---- BEGIN ---- " >> log.txt

###########################################################################################################
#                                                                                                         #
# Check and download file LTER.txt conaining the XML file list - BEGIN                                    #
#                                                                                                         #
###########################################################################################################


# Check if LTER.txt already exists in the folder
if [ -e LTER.txt ]; then
	# If it exists, the file will be downloaded again with a new name
	wget -O LTER_1.txt http://datalogger.santateresa.enea.it/Meteo_Station/LTER/LTER.txt
	# Check if file are different
	diff -q LTER.txt LTER_1.txt

	if [ -z $differ ]; then
		# If files aren't different, the file just downloaded will be deleted
		echo "[ $(date +"%Y-%m-%d-%T") ] - Files are not different, last file downloaded had been deleted" >> log.txt
		rm LTER_1.txt 
	else
		# If files are different, the oldest file will be deleted and the new one will be renamed like the oldest
		echo "[ $(date +"%Y-%m-%d-%T") ] - Files are different, old file has been deleted and new file has been renamed as LTER.txt" >> log.txt
		rm LTER.txt
		mv LTER_1.txt LTER.txt
	fi
else

# If LTER.txt doesn't exist, it will be downloaded
echo "[ $(date +"%Y-%m-%d-%T") ] - File LTER.txt doesn't exist, it will be downloaded" >> log.txt
wget http://datalogger.santateresa.enea.it/Meteo_Station/LTER/LTER.txt

fi

# Cleaning file from end line and new line characters
sed -i 's/\r$//' LTER.txt


########################################################################################################
#												                                                       #
# Chek and download file LTER.txt - END                                                                # 
#												                                                       #
########################################################################################################

#------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------#

########################################################################################################
#                                                                                                      #
# Check and download XML files - BEGIN                                                                 #
#                                                                                                      #
########################################################################################################


# Check if files XML listed in LTER.txt exist in the folder
count=0
while read line;

do
# If file exists in the folder of downloaded and if it exists in error folder, I will write in the log file that it has been already downloaded
#if [ -e $line ] && [ -e error/$line ]; then
#	echo "[ $(date +"%Y-%m-%d-%T") ] - File $line already downloaded" >> log.txt
#else
#	# If file doesn't exist, it will be downloaded and it will be included in a file which contains a list of downloaded file
#	echo "[ $(date +"%Y-%m-%d-%T") ] - Downloading file $line" >> log.txt
#	((count++))
#	wget http://datalogger.santateresa.enea.it/Meteo_Station/LTER/$line
#	echo $line >> downloadedfiles.txt

#fi

# If file name exists in the history file , in the log file it will be written that it has been already downloaded
if [ grep -Fxq "$line" historydownloadedfiles.txt ]; then
    echo "[ $(date +"%Y-%m-%d-%T") ] - File $line already downloaded" >> log.txt
else
    #If filename doesn't exist, it will be downloaded and it will be included in a file which contains a list of downloaded file
    echo "[ $(date +"%Y-%m-%d-%T") ] - Downloading file $line" >> log.txt
	((count++))
	wget http://datalogger.santateresa.enea.it/Meteo_Station/LTER/$line
	# Insert XML filename in file with a list of XML to be processed by the script post.sos.sh
	echo $line >> downloadedfiles.txt
	# Insert XML filename in a file with the list with all XML downloaded
    echo $line >> historydownloadedfiles.txt

done < LTER.txt

# Writing in log file how many file have been downloaded 
echo "[ $(date +"%Y-%m-%d-%T") ] - $count file has been downloaded: " >> log.txt


#######################################################################################################
#												                                                      #
# Check and download XML files - END			                                                      #
#												                                                      #
#######################################################################################################

#------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------#

########################################################################################################
#												                                                       #
# Running script for uploading XML into SOS and check response files - BEGIN		                   #
#												                                                       #
########################################################################################################

err=0
while read line;

do
	file=$line".SOS.response.xml"
	$scriptDir/post.sos.sh -e $urlsos $line
	# If the response file contains the word Exception, the exception will be written in the log file
	if grep -q  Exception $file; then
		((err++))
		echo -e "[ $(date +"%Y-%m-%d-%T") ] - $line -- uploading has produced the following exception: \n " >> log.txt
		
		exceptioncode=`sed 's:^.*exceptionCode="::;s:" locator.*$::;s:<.*>::g;s:[[:space:]]::g;/^$/d' $file`
		exceptiontext=`sed 's:^.*<ows\:ExceptionText>::;s:.</ows\:ExceptionText>.*$::;s:<.*>::g;/^$/d' $file`
	
		echo $exceptioncode >> log.txt
		echo -e $exceptiontext "\n" >> log.txt

		# The file which has generated the exception will be added to a list of file which has failed the upload and it will be moved to "error" folder
		echo $line >> $errorDir/error.txt
		mv $line $errorDir
		mv $file $errorDir
	else
	# If no exception will be found, a row in the log file will be written specifying that the upload was OK
	echo "[ $(date +"%Y-%m-%d-%T") ] - $line has been uploaded without errors " >> log.txt

	fi
done < downloadedfiles.txt
echo "During uploading $err files have returned some exception and have been saved in $errorDir"


#######################################################################################################
#												                                                      #
# Running script for uploading XML into SOS and check response files - END                            #
#												                                                      #
#######################################################################################################


enddate=$(date +"%Y-%m-%d-%T")
#durata=$((($datafine)-($datainizio)))
echo "Procedure finished. Check the file log.txt in $downloadDir to get more detailed information about the procedure and about errors"
echo "---------"
echo "Procedure begin at: $begindate"
echo "Procedure end at: $enddate"
#echo "Tempo impiegato: $durata"
echo "[ $enddate ] ---- END ---- " >> log.txt


