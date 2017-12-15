#!/bin/bash

# PURPOSE: call irea SOS service given post request file(name)
# USAGE: <script name> <post request filename>
# 			this script writes the response content in the working directory and opens it with the default xml editor
# AUTHOR: tagliolato.p@irea.cnr.it

display_help() {
	echo "Usage: $(basename $0) [-h] [-a <application>] [-e <sos endpoint>] <sos request file>"	
	echo "-a	open resulting xml within the given application"
	echo "-e	post request to the given sos endpoint"
	echo "-h	display help"		
}

# check envir
for tool in getopts curl open; do
	if ! type $tool >/dev/null 2>&1; 
	then
		echo "  ERROR: \"$tool\" not found." >&2
		echo "       This is needed by $(basename $0) to work. Check your" >&2
		echo "       \$PATH variable or install the tool \"$tool\"." >&2
		#echo "       try the following:"
		#echo "       export PATH=\"\$PATH:/usr/local/pgsql/bin\" "
		exit 2
	fi
done


while getopts "a:e:h" opt; do
  case $opt in
     a)
      OPEN="apri"
      XMLApp="$OPTARG"
      if [ "$XMLApp" = "" ]
      then
      	echo "OPEN WITH default XML application"
      else
	  	echo "OPEN WITH = $XMLApp"
	  fi      
      shift $((OPTIND-1))
      ;;
     e)
      ENDPOINT="$OPTARG"
      if [ "$ENDPOINT" = "" ]
      	then
		ENDPOINT = "http://10.0.0.100/observations/sos"
        	echo "POST to default ENDPOINT: $ENDPOINT"
      	else
                echo "ENDPOINT = $ENDPOINT"
      fi
      shift $((OPTIND-1))
      ;;
     h)
      display_help
      exit 0
      ;;
    \?)
      echo "  Invalid option: -$OPTARG" >&2
      display_help && exit 2
      ;;
  esac
done

# check input
echo "OPEN= $OPEN"
echo "ENDPOINT=$ENDPOINT"
if [ "$1" == "" ] 
then
	display_help
	echo "  input mancante $1" >&2
	#echo "$@" >&2
	exit 1
else
	if [ -f $1 ]
	then 
		curl -v -X POST -d @$1 $ENDPOINT --header "Content-Type:text/xml" > $1.SOS.response.xml
		if [ "$OPEN" == "apri" ]
		then
			if [ "$XMLApp" != "" ]
			then
				open $1.SOS.response.xml -a $XMLApp
			else
				open $1.SOS.response.xml
			fi
		fi
	else 
		echo "  la risorsa $1 non esiste" >&2
		exit 2
	fi
fi
