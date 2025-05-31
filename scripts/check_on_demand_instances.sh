#!/bin/bash

source ./utils.sh

ACCOUNT_ID=$(get_account_id)

REGION=$(aws configure get region)

log_info "Checking for On-Demand EC2 instances in $REGION"
echo "------------------------------------------------------------"

# Retrieve details of running EC2 instances
instances=$(aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=running \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,Lifecycle:InstanceLifecycle}' \
  --output json)

# Parse the instances JSON using jq to identify On-Demand instances
echo "$instances" | jq -r '.[][] | select(.Lifecycle == null) | "💸 On-Demand Instance: \(.ID) (\(.Type))"'

# Count the number of On-Demand instances separately
count=$(echo "$instances" | jq '[.[][] | select(.Lifecycle == null)] | length')

# Check if no On-Demand instances were found (count is 0)
if [ "$count" -eq 0 ]; then
  log_success "No On-Demand instances detected."
else
  log_warn "Total On-Demand instances: $count"
  log_info "Consider using Reserved Instances or Savings Plans to save costs."
fi