#!/bin/bash

   echo "-------------------"
Echo "Header preparation script"
   echo "-------------------"

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

LINES=$(cat $LIST)
for LINE in $LINES
do
   echo "-------------------"
Echo "Creating file for $LINE"
   echo "-------------------"
say -o "$SCRIPT_DIR/$FORMAT/$LINE.$FORMAT" "$LINE"
done

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

mkdir $OUTPUTDIR/headers
   echo "-------------------"
echo "making header files"
   echo "-------------------"

cd $OUTPUTDIR/mp3
FILES=*
for f in $FILES
do
   echo "-------------------"
   echo "Making headers from File: $f"
   echo "-------------------"
   XXD -i $f $OUTPUTDIR/headers/${f%.*}.h
done

cd $OUTPUTDIR/headers
Ls > ../speechSamples.h
LINES=$(cat ../speechSamples.h)

Echo "Creating the speech array"

Echo "{nullptr, nullptr}};" > ../tmpArray.txt

for LINE in $LINES
do
FILENOEXT=$(basename $LINE .h)
FILENOCAPS=$(echo "$FILENOEXT" | tr '[:lower:]' '[:upper:]')

   echo "-------------------"
Echo "adding $LINE to array"
   echo "-------------------"

Echo '{"'$FILENOCAPS'", new MemoryStream('$FILENOEXT'_mp3, '$FILENOEXT'_mp3_len)},' | cat - tmpArray.txt > temp && mv temp ../tmpArray.txt
done

echo "AudioDictionaryEntry MyAudioDictionaryValues[] = {" | cat - ../tmpArray.txt > temp && mv temp ../tmpArray.txt
Mv ../tmpArray.txt ../speechArray.h

echo "creating header list"

for LINE in $LINES
do
    echo "#include \"/headers/$LINE\"" >> ../tmpSamples.txt
done
Mv ../tmpSamples.txt ../speechSamples.h

   echo "-------------------"
Echo "Adding pragma and const"
   echo "-------------------"

for i in $(find ./ -name '*.h');
do
echo -n "const " | cat - $i > /tmp/$i && mv /tmp/$i $i
echo "#pragma once" | cat - $i > /tmp/$i && mv /tmp/$i $i
done

   echo "-------------------"
Echo "Script finished"
   echo "-------------------"
