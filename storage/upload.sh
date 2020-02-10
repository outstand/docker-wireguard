#!/bin/sh
aws s3 sync /etc/wireguard/ s3://${S3_BUCKET}/ --exclude 'lock/*'
