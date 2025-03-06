#!/usr/bin/env bash

aws s3 rm s3://$1 --recursive --region us-east-1
aws s3api delete-objects --bucket $1 --delete "$(aws s3api list-object-versions --bucket $1  | jq '{Objects: [.Versions[] | {Key: .Key, VersionId: .VersionId}], Quiet: true}')"
aws s3 rb s3://$1 --force --region us-east-1
