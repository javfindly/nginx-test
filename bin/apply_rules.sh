#!/bin/bash -l

BASE_DIR=$1
APPLY_DIR=$2
SERVERS_FILE=$3

if [[ $BASE_DIR == "" || $APPLY_DIR == "" || $SERVERS_FILE == "" ]]; then
        echo "Invalid params"
        echo "You must user BASE_DIR APPLY_DIR SERVERS_FILE"
        exit 1
fi


BKP_FOLDER=$APPLY_DIR/bkp
BKP_FILE=`date +"%Y%m%d%H%M%S"`.tar.gz

NEW_POOLS_FILE=$BASE_DIR/pools
NEW_RULES_FILE=$BASE_DIR/rules
NEW_SUBDOMAINS_FILE=$BASE_DIR/subdomains

POOLS=$APPLY_DIR/conf/pools/
RULES=$APPLY_DIR/conf/rules/
SUBDOMAIN=$APPLY_DIR/conf/subdomains/


echo "Generating BackUps"
mkdir -p $BKP_FOLDER
tar -cvzf $BKP_FOLDER/$BKP_FILE $POOLS $RULES $SUBDOMAINS
echo "BKP File $BKP_FOLDER/$BKP_FILE"

if [[ -d $NEW_POOLS_FILE ]]; then
	echo "Copying $NEW_POOLS_FILE to $POOLS"
	cp -rf $NEW_POOLS_FILE/* $POOLS
fi

if [[ -d $NEW_RULES_FILE ]]; then
	echo "Copying $NEW_RULES_FILE to $RULES"
	cp -fr $NEW_RULES_FILE/* $RULES
fi

if [[ -d $NEW_SUBDOMAINS_FILE ]]; then
        echo "Copying $NEW_SUBDOMAINS_FILE to $SUBDOMAIN"
        cp -fr $NEW_SUBDOMAINS_FILE/* $SUBDOMAIN
fi


chown oraweb:dba $POOLS
chown oraweb:dba $RULES
chown oraweb:dba $SUBDOMAINS
echo

ls -l $POOLS
ls -l $RULES
ls -l $SUBDOMAINS

echo "Reloading..."
su - oraweb -c "/department/deploy/bin/test/reload_all.sh $SERVERS_FILE"
echo "Reload done"
#echo "Notifying NewRelic..."
#cd $REPO/bin
#./notify-newrelic
echo "Done."
