#! /bin/sh

#{{- if .Values.enablePdf2 }} use pdf2
sed -i 's/230=pdf$/230=pdf2/' /view/filters/formats_e.ini
#{{- end }}
