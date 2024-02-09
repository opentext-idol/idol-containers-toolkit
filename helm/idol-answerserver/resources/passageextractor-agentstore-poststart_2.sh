#!/bin/bash

waitForAci "localhost {{ .Values.passageextractorAgentstore.aciPort | int }}"

for i in `ls idx/*.idx.gz`;
do
    if [ ! -e $i.indexed ];
    then
        echo "Indexing $i"
         curl -s --noproxy -o doc.txt "http://localhost:$(({{ .Values.passageextractorAgentstore.aciPort | int }}+1))/DREADD?/content/$i"
        touch $i.indexed
    fi
done
rm doc.txt*