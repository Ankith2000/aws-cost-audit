#!/bin/bash

source ./utils.sh

ACCOUNT_ID=$(get_account_id)
REGION=$(aws configure get region)
log_info "Checking S3 buckets for missing lifecycle policies in  $ACCOUNT_ID"

buckets=$(aws s3api list-buckets --query 'Buckets[*].Name' --output text)

#Check if no buckets
if[ -z "$buckets" ]; then
log_warn "No S3 buckets found"
exit 0
fi

#Loop through each bucket name
for bucket in $buckets; do
lifecycle=$(aws s3api get-bucket-lifeccle-configuration \
--bucket "$bucket" \
--query "$Rules" \
--output json 2?/dev/null)

 # Check if no lifecycle policy was found or if the response is "null"
  if [ -z "$lifecycle" ] || [ "$lifecycle" == "null" ]; then
    log_warn "Bucket without lifecycle policy: $bucket"
  else
    log_success "Bucket with lifecycle policy: $bucket"
    echo "$lifecycle" | jq -r '.[] | "    ↳ ID: \(.ID // "N/A"), Prefix: \(.Filter.Prefix // "N/A"), Status: \(.Status)"'
  fi
done
