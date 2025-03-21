#!/usr/bin/env bash

# This command removes all the objects present in a non-versioned bucket

aws s3 rm s3://$1 --recursive --region us-east-1

# The following command also deletes all objects present in a bucket, but if the previous command has already
# deleted the objects then this will error out since the bucket is already empty.
# Also if you run the previous command on a versioned bucket then it adds a delete marker on top of the existing objects
# which then restrains the next command to work effectively.
# Read about delete markers here (https://docs.aws.amazon.com/AmazonS3/latest/userguide/DeleteMarker.html)

aws s3api delete-objects --bucket $1 --delete "$(aws s3api list-object-versions --bucket $1  | jq '{Objects: [.Versions[] | {Key: .Key, VersionId: .VersionId}], Quiet: true}')"

# This command deletes an empty S3 bucket, however the --force parameter
# can be used to delete the non-versioned objects in the bucket before the bucket is deleted

aws s3 rb s3://$1 --force --region us-east-1
