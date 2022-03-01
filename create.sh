#!/bin/bash

#This script generates speech samples for the Arduino Simple TTS library
# Written by Ashley Cox, ashleycox.co.uk
# No guarantees are given as to the suitability or stability of the script
# no liability of any form is accepted, use at your own risk
# Written and tested on MacOS 12

   echo "-------------------"
Echo "Header preparation script"
   echo "-------------------"

# First we define some variables

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

OUTPUTDIR=${1:-$SCRIPT_DIR}
FORMAT=${2:-aiff}
LIST=${3:-$SCRIPT_DIR/samples.txt}
SAMPLERATE=${4:-24000}
BITDEPTH=${5:-32k}

   echo "-------------------"
Echo "Creating Audio Files"
   echo "-------------------"

mkdir $OUTPUTDIR/$FORMAT

# Loop through our input text file line by line
# Speak each line, to an audio file using the say command

LINES=$(cat $LIST)
for LINE in $LINES
do
   echo "-------------------"
Echo "Creating file for $LINE"
   echo "-------------------"
say -o "$SCRIPT_DIR/$FORMAT/$LINE.$FORMAT" "$LINE"
done

# Convert the files we just created to mp3 files using ffmpeg and the sample rate and bit depth defined above

   echo "-------------------"
Echo "Converting files to $BITDEPTH / $SAMPLERATE mp3"
   echo "-------------------"

mkdir $OUTPUTDIR/mp3
cd $OUTPUTDIR/$FORMAT

FILES=*
for f in $FILES
do
   echo "-------------------"
   echo "Converting File: $f"
   echo "-------------------"
   ffmpeg -hide_banner -loglevel error -i $f -vn -ar $SAMPLERATE -ac 1 -b:a $BITDEPTH $OUTPUTDIR/mp3/${f%.*}.mp3
done

#We now need somewhere to store our c header files

mkdir $OUTPUTDIR/headers
   echo "-------------------"
echo "making header files"
   echo "-------------------"

# We loop through the directory of mp3 output files we crated above
# We process each file to produce a c header file to include in our program

cd $OUTPUTDIR/mp3
FILES=*
for f in $FILES
do
   echo "-------------------"
   echo "Making headers from File: $f"
   echo "-------------------"
   XXD -i $f $OUTPUTDIR/headers/${f%.*}.h
done

# We now want to create an array containing all of our samples to use in our sketch
# First, we move to the directory where we stored our headers

cd $OUTPUTDIR/headers

# Then, list that directory out to a file in our scripts root directory

Ls > ../speechSamples.h

# We want to read the file we just created, line-by-line

LINES=$(cat ../speechSamples.h)

Echo "Creating the speech array"

# The file is produced from back to front, so this is actually the last line in our file

Echo "{nullptr, nullptr}};" > ../tmpArray.txt

# Loop through the file and add an array entry for each sample

for LINE in $LINES
do

# Strip the extension from the file to get the name to use in our array

FILENOEXT=$(basename $LINE .h)

# Create a variable storing the name in uppercase letters

FILENOCAPS=$(echo "$FILENOEXT" | tr '[:lower:]' '[:upper:]')

   echo "-------------------"
Echo "adding $LINE to array"
   echo "-------------------"

# Create the array entry

Echo '{"'$FILENOCAPS'", new MemoryStream('$FILENOEXT'_mp3, '$FILENOEXT'_mp3_len)},' | cat - ../tmpArray.txt > temp && mv temp ../tmpArray.txt
done

# Finally, add the first line that initialises the array to our file.

echo "AudioDictionaryEntry MyAudioDictionaryValues[] = {" | cat - ../tmpArray.txt > temp && mv temp ../tmpArray.txt
Mv ../tmpArray.txt ../speechArray.h

echo "creating header list"

# We use the variable created above, but add include statements to each line to make the file more useful in our sketches

for LINE in $LINES
do
    echo "#include \"headers/$LINE\"" >> ../tmpSamples.txt
done
Mv ../tmpSamples.txt ../speechSamples.h

   echo "-------------------"
Echo "Adding pragma and const"
   echo "-------------------"

# The arrays that hold our hex characters need to be defined as const to be stored in program memory
# We also want to add a pragma definition so that each header file can only be included once.

for i in $(find ./ -name '*.h');
do
echo -n "const " | cat - $i > /tmp/$i && mv /tmp/$i $i
echo "#pragma once" | cat - $i > /tmp/$i && mv /tmp/$i $i
done

   echo "-------------------"
Echo "Script finished"
   echo "-------------------"
