#!/bin/bash

source ./utils.sh

ACCOUNT_ID=$(get_account_id)

REGION=$(aws configure get region)

THRESHOLD_DAYS=30

log_info "Checking old RDS snapshots i.e, older than $THRESHOLD_DAYS days in $REGION"

#Convert the threshold date to UTC
cutoff_date=$(date -u -d "$THRESHOLD_DAYS days ago" +"%Y-%m-%dT%H:%M:%SZ")

#Retrieve details of RDS snapshots older than the cutoff date
snapshots=$(aws rds describe-db-snapshots \
  --query "DBSnapshots[?SnapshotCreateTime<'$cutoff_date'].[DBSnapshotIdentifier,DBInstanceIdentifier,SnapshotCreateTime,SnapshotType]" \
  --output json)

#Check if no snapshots were found 
if [-z "$snapshots"] || ["$snapshots" == "[]"]; then
log_success "Success!! No snapshots were found older than $THRESHOLD_DAYS days"
exit 0
fi

# Parse the snapshots JSON and format the output using jq
# For each snapshot, print a warning with details:
# - .0: DBSnapshotIdentifier (snapshot name)
# - .1: DBInstanceIdentifier (associated RDS instance)
# - .2: SnapshotCreateTime (creation timestamp)
# - .3: SnapshotType (e.g., manual or automated)
echo "$snapshots" | jq -r '.[] | 
  "Snapshot: \(.0)\n    Instance: \(.1)\n     Created: \(.2)\n     Type: \(.3)\n"'
