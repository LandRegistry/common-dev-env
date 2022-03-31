#!/bin/bash

# This is an example fragment that creates a new S3 bucket in localstack (if it doesn't already exist),
# wipes the contents of said bucket, and enables versioning on said bucket.
# Each command will be run sequentially in the container.
awslocal s3 mb s3://example-bucket
awslocal s3 rm s3://example-bucket --recursive
awslocal s3api put-bucket-versioning --bucket example-bucket --versioning-configuration Status=Enabled
