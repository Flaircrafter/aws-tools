#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# Exaples:
# move-s3-objects.sh my_bucket objects moved_objects
# result in mv my_bucket objects moved_objects/objects

#BUCKET=my_bucket
#OBJ_PREFIX=target-prefix-object-key # No slashes /
#OBJ_NEW_PATH=new_key_path # Must not start or end with slash /

BUCKET=$1
OBJ_PREFIX=$2
OBJ_NEW_PATH=$3

[ -z "$BUCKET" ] && echo "BUCKET is required" && exit 1
[ -z "$OBJ_PREFIX" ] && echo "OBJ_PREFIX is required" && exit 1
[ -z "$OBJ_NEW_PATH" ] && echo "OBJ_NEW_PATH is required" && exit 1


function move_objects() {
	while IFS= read -r line; do
    echo "aws s3 mv s3://${BUCKET}/$line s3://${BUCKET}/${OBJ_NEW_PATH}/$line" && \
		aws s3 mv s3://${BUCKET}/$line s3://${BUCKET}/${OBJ_NEW_PATH}/${line} ; \
	done < ${OBJ_PREFIX}
}

# List objects and create a output file
aws s3api list-objects-v2 --bucket ${BUCKET} --prefix ${OBJ_PREFIX} | \
jq --raw-output '.Contents[].Key' | tee ${OBJ_PREFIX}

while true; do
    read -p "Do you wish to move these objects to this path $OBJ_NEW_PATH?" yn
    case $yn in
        [Yy]* ) move_objects; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
