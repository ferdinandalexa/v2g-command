#!/bin/bash

# Check that all dependencies required are installed
# or else display a message with all missing dependencies. 
if ! command -v "ffmpeg" &> /dev/null
then
	echo "\"ffmpeg\" is required to work".
	echo Use \"apt-get install ffmpeg\" or \"apt install ffmpeg\" to install it.
	exit
fi

# Get options given by the user and save the values.
while getopts "d:f:" OPTIONS;
do
	case $OPTIONS in
		d) DIR=$OPTARG;;
		f) FORMAT=$OPTARG;;
	esac
done

printf "Searching %s files in %s\n" .$FORMAT $DIR
RESULTS=$(find $DIR -type f -name "*.$FORMAT")

# Check contents $RESULTS:
# 	* $RESULTS is not empty
#		1. Create a function to get the process 
#		   convertion status and print it.
#		2. Iterate for each result to convert it
#		   to .gif.
#		3. Save .gif to the source of the
#		   converted file.
#
#	* $RESULTS is empty
#		1. Return that the files with the 
#		   provided format were not found in the
#		   path given by user.
if [[ -n $RESULTS ]]
then  
	process_end(){
		GET_PROGRESS=`grep -e 'progress=*' $1 | tail -1`
		STATUS="$GET_PROGRESS"

		if [[ $STATUS = 'progress=end' ]];
		then
			MSG="\e[32mCOMPLETED"
			echo -ne "\r$MSG"
		fi
	}

	COUNT_RESULTS=$(wc -l <<< $RESULTS)
	printf "%s files found\n" $COUNT_RESULTS
	
	PROGRESS_FILE="./.progress"
	touch $PROGRESS_FILE

	for i in $RESULTS;
	do
		GIF_NAME="`echo $i | sed \"s/\.$FORMAT/.gif/\"`"

		printf "\n"
		printf "\e[33mConverting file: %s\n" $i
		
		EXEC_FFMPEG=`ffmpeg -loglevel error -progress $PROGRESS_FILE -i $i $GIF_NAME`
		
		$EXEC_FFMPEG &
		process_end $PROGRESS_FILE &
		wait

		printf ": "
		printf "\e[32m%s was created\n" $GIF_NAME

		truncate -s 0 $PROGRESS_FILE
	done

	rm -rf ./.progress
else
	printf "\e[31m.%s files were not found.\n" $FORMAT
	exit
fi
