#!/bin/bash

waitForAci "localhost:{{ .Values.passageextractorAgentstore.aciPort | int }}"

for i in `ls idx/*.idx.gz`;
do
    if [ ! -e $i.indexed ];
    then
        echo "Indexing $i"
        curl -S -s --noproxy "*" --insecure -o $i.indexed "${HTTP_SCHEME}://localhost:$(({{ .Values.passageextractorAgentstore.aciPort | int }}+1))/DREADD?/content/$i"
    fi
done
