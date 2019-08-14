#!/bin/bash

echo 'Deploy to S3'
aws s3 sync public s3://mengwei.me --region=us-west-1 --delete