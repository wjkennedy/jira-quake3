wget ftp://ftp.idsoftware.com/idstuff/quake3/linux/linuxq3ademo-1.11-6.x86.gz.sh

#Download may be quite slow, but once it’s done issue the following command (discussed here) to extract the data:
 
tail +165 ./linuxq3ademo-1.11-6.x86.gz.sh | gzip -cd | tar xvof -
