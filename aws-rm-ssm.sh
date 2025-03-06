#!/usr/bin/env bash

aws ssm delete-parameter --name "$1" --region us-east-1
