#!/bin/bash

######################################################
##						    ##
## Questo script consente di scaricare dei file xml ##
## ad un endpoint e di carcarli su un SOS           ##
##                                                  ##
######################################################
##						    ##
## AUTHOR: Simone Lella				    ##
## CONTACT: lella.s@irea.cnr.it			    ##
## IREA - CNR ©					    ##
##    						    ##
######################################################
#
downloadDir=/home/$USER/LTER_data_download/
scriptDir=`pwd`
urlsos=http://sos-getit.irea.mi/observations/sos

# Chiedo all'utente di inserire il percorso in cui salvare i file
echo -en "Inserire il percorso in cui salvare i file scaricati [$downloadDir] "

read downloadDir

# Se non viene inserito niente rimane il percorso di default che salva i file
# nella cartella LTER_data_download nella cartella dell'utente
if [ -z $downloadDir ]; then
	downloadDir=/home/starterkit/LTER_data_download/
	echo Il path è: $downloadDir
	if [ -d $downloadDir ]; then
		echo "La cartella esiste"
		else
		# Se la cartella LTER_data_download non esiste, viene creata
		mkdir $downloadDir
	fi
else
	echo "Il path è : $downloadDir"
fi

# Chiedo all'utente di inserire l'url del SOS su cui caricare i dati
echo -en "Inserire l'url del SOS  [$urlsos] "

read urlsos 

if [ -z $urlsos ]; then
	urlsos=http://sos-getit.irea.mi/observations/sos
	echo "L'URL è: $urlsos"
else
	echo "L'URL è : $urlsos"
fi



# Accedo alla cartella in cui verranno scaricati i file xml
cd $downloadDir
datainizio=$(date +"%Y-%m-%d-%T")
echo "\n\n [ $datainizio ] ---- INIZIO PROCEDURA ---- " >> log.txt

###########################################################################################################
##												         #
## Inizio procedura per il controllo e lo scaricamento del file LTER.txt contenente l'elenco dei file xml #
##												         #
###########################################################################################################


# Controllo se il file LTER.txt esiste nella cartella
if [ -e LTER.txt ]; then
	# Se esiste, lo scarico con un nuovo nome
	wget -O LTER_1.txt http://datalogger.santateresa.enea.it/Meteo_Station/LTER/LTER.txt
	# Controllo se i file sono uguali
	diff -q LTER.txt LTER_1.txt

	if [ -z $differ ]; then
		# Se sono uguali elimino il file appena scaricato
		echo "[ $(date +"%Y-%m-%d-%T") ] - I file sono uguali, elimino il file appena scaricato" >> log.txt
		rm LTER_1.txt 
	else
		# Se sono diversi, elimino il vecchio file e rinomino quello nuovo come il vecchio
		echo "[ $(date +"%Y-%m-%d-%T") ] - I file sono diversi, elimino il vecchio file e rinomino quello nuovo come LTER.txt" >> log.txt
		rm LTER.txt
		mv LTER_1.txt LTER.txt
	fi
else

# Se non esiste lo scarico
echo "[ $(date +"%Y-%m-%d-%T") ] - Il file LTER.txt non esiste, lo scarico" >> log.txt
wget http://datalogger.santateresa.enea.it/Meteo_Station/LTER/LTER.txt

fi

# Pulisco il file LTER.txt dai caratteri speciali di fine riga e a capo
sed -i 's/\r$//' LTER.txt


########################################################################################################
#												       #
# Fine procedura per il controllo e lo scaricamento del file LTER.txt contenente l'elenco dei file XML #
#												       #
########################################################################################################

#------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------#

########################################################################################################
#												       #
# Inizio  procedura per il controllo e lo scaricamento del file XML                                    #
#												       #
########################################################################################################


# Controllo se i file XML nel file LTER.txt sono presenti nella cartella
count=0
while read line;

do
# Se il file è presente scrivo che è già stato scaricato
if [ -e $line ]; then
	echo "[ $(date +"%Y-%m-%d-%T") ] - File $line già scaricato" >> log.txt
else
	# Se non è presente lo scarico e lo inserisco nel file dei file scaricati
	echo "[ $(date +"%Y-%m-%d-%T") ] - Scarico il file $line" >> log.txt
	((count++))
	wget http://datalogger.santateresa.enea.it/Meteo_Station/LTER/$line
	echo $line >> filescaricati.txt
fi

done < LTER.txt

# Nel log scrivo quanti e quali file sono stati scaricati
echo "[ $(date +"%Y-%m-%d-%T") ] - Sono stati scaricati $count file: " >> log.txt

#while read line;
	
#do

#	echo $line >> log.txt

#done < filescaricati.txt


#######################################################################################################
#												      #
# Fine  procedura per il controllo e lo scaricamento del file XML                                     #
#												      #
#######################################################################################################

#------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------------------------#

########################################################################################################
#												       #
# Inizio procedura esecuzione script caricamento XML nel SOS e controllo file di risposta              #
#												       #
########################################################################################################


while read line;

do
	file=$line".SOS.response.xml"
	$scriptDir/post.sos.sh -e $urlsos $line
	# Se il file di risposta contiene la parola Exception, scrivo l'eccezione nel file di log e aggiungo il file ad un elenco dei file che hanno dato errore nel caricamento
	if grep -q  Exception $file; then

		echo -e "[ $(date +"%Y-%m-%d-%T") ] - Il caricamento del file -- $line -- ha generato la seguente eccezione: \n " >> log.txt
		
		exceptioncode=`sed 's:^.*exceptionCode="::;s:" locator.*$::;s:<.*>::g;s:[[:space:]]::g;/^$/d' $file`
		exceptiontext=`sed 's:^.*<ows\:ExceptionText>::;s:.</ows\:ExceptionText>.*$::;s:<.*>::g;/^$/d' $file`
	
		echo $exceptioncode >> log.txt
		echo -e $exceptiontext "\n" >> log.txt

		# Inserisco l'XML al file che contiene gli XML che hanno generato un errore nel caricamento nel SOS
		echo $line >> errore_SOS.txt
	else
	# Altrimenti scrivo nel log che il file è stato caricato correttamente
	echo "[ $(date +"%Y-%m-%d-%T") ] - Il file -- $line --  è stato caricato correttamente " >> log.txt 

	fi
done < filescaricati.txt


#######################################################################################################
#												      #
# Fine procedura esecuzione script caricamento XML nel SOS e controllo file di risposta               #
#												      #
#######################################################################################################

echo "Inizio"
datainizio=$(date +"%Y-%m-%d-%T")
sleep 10
datafine=$(date +"%Y-%m-%d-%T")
#durata=$((($datafine)-($datainizio)))
echo "Procedura terminata. Controllare il file log.txt in $downloadDir per avere informazioni più dettagliate e su eventuali errori"
echo "---------"
echo "Procedura iniziata: $datainizio"
echo "Procedura terminata: $datafine"
#echo "Tempo impiegato: $durata"
echo "[ $datafine ] ---- FINE PROCEDURA ---- " >> log.txt


