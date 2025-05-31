#!/bin/bash

source ./main.sh

ACCOUNT_ID=$(get_account_id)

REGION=$(aws configure get region)

log_info "Check any ebs volume are forgotten to delete in $REGION"

# Retrieve details of EBS volumes that are unattached (status=available)
# The 'aws ec2 describe-volumes' command queries EBS volume information
# --filters Name=status,Values=available limits to volumes not attached to any EC2 instance
# --query uses a structured JSON format to extract specific fields:
#   - ID: VolumeId (unique identifier of the volume)
#   - Size: Size (volume size in GiB)
#   - Created: CreateTime (creation timestamp of the volume)
#   - Tags: Tags (volume tags, if any)
volumes=$(aws ec2 describe-volumes \
--filters Name=status, Values=available \
--query 'Volumes[*].{ID:VolumeId,Size:Size,Created:CreateTime,Tags:Tags}' \
--output json)


# Check if no unattached volumes were found 
if[ -z $volumes ]  || [ "$volumes" == '[]' ]; then 
log_success "No unattached EBS volumes"
exit 0
fi

echo "$volumes" | jq -r '.[] | 
"Unattached EBS Volume: \(.ID)\n    Size: \(.Size) GiB\n    Created: \(.Created)\n    Tags: \(.Tags // "None")\n""