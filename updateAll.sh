#! /bin/bash

source variables.conf

PLAYPORT=9000
INDEXNAME=edoweb

curl -s -XGET localhost:9200/$INDEXNAME/part,issue,journal,monograph,volume,file/_search -d'{"query":{"match_all":{}},"fields":["/@id"],"size":"50000"}'|egrep -o "$INDEXNAME:[^\"]*" >$ARCHIVE_HOME/logs/pids.txt

curl -s -XGET localhost:9200/$INDEXNAME/journal/_search -d '{"query":{"match_all":{}},"fields":["/@id"],"size":"50000"}'|grep -o "$INDEXNAME:[^\"]*" >$ARCHIVE_HOME/logs/journalPids.txt

num=`cat $ARCHIVE_HOME/logs/journalPids.txt|wc -l`
echo "Try to load $num journal resources to cache:"
cat $ARCHIVE_HOME/logs/journalPids.txt | parallel curl -s -uedoweb-admin:$PASSWORD -XGET http://localhost:$PLAYPORT/resource/{}/all -H"accept: application/json"  >$ARCHIVE_HOME/logs/initCache-`date +"%Y%m%d"`.log 2>&1

num=`cat $ARCHIVE_HOME/logs/pids.txt|wc -l`
echo "Update $num resources. Details under $ARCHIVE_HOME/logs/pids.txt." 

echo "lobidify"
cat $ARCHIVE_HOME/logs/pids.txt | parallel curl -s -uedoweb-admin:$PASSWORD -XPOST http://localhost:$PLAYPORT/utils/lobidify/{} -H"accept: application/json"  >$ARCHIVE_HOME/logs/lobidify-`date +"%Y%m%d"`.log 2>&1

echo "enrich"
cat $ARCHIVE_HOME/logs/pids.txt | parallel curl -s -uedoweb-admin:$PASSWORD -XPOST http://localhost:$PLAYPORT/resource/{}/metadata/enrich -H"accept: application/json"  >$ARCHIVE_HOME/logs/enrich-`date +"%Y%m%d"`.log 2>&1

echo "index"
cat $ARCHIVE_HOME/logs/pids.txt | parallel curl -s -uedoweb-admin:$PASSWORD -XPOST http://localhost:$PLAYPORT/utils/index/{} -H"accept: application/json"  >$ARCHIVE_HOME/logs\
/index-`date +"%Y%m%d"`.log 2>&1

