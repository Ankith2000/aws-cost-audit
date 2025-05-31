# This script queries AWS for a list of budget names
# For each budget, checks if notifications are set up and logs appropriate messages.


#!/bin/bash

source ./utils.sh

ACCOUNT_ID = $(get_account_id)

if [-z "$ACCOUNT_ID"]: then
    log_error "Failed to fetch account_id"
    exit 1
fi

log_info "Checking the budgets for AWS Account: $ACCOUNT_ID"
echo "-----------------------------------------"

# Retrieve a list of budget names from AWS using the AWS CLI
# The output is piped to 'jq' (a JSON processor) to extract just the BudgetName fields
budget_names=$(aws budgets describe-budgets \
  --account-id "$ACCOUNT_ID" \
  --output json | jq -r '.Budgets[].BudgetName')


# Check if no budgets were found (budget_names is empty)
if [-z "$budget_names"]: then
     log_warn "No budgets for this account"
     exit 0
fi

#Loop to read each budget names
while IFS= read -r budget_name; do
 log_info "Budget: $budget_name"

#Check for any notifications associated for the budget
notifications = $(aws budgets describe-notifications-for-budget \
    --account-id "$ACCOUNT_ID" \ 
    --budget-name "$budget_name" \
    --query 'Notifications' \
    --output text)

#If no notifications
if [ -z "$notifications"]; then
 log_warn "No alerts configured"
 else
 log_success "Alerts are there!!"
fi

done <<< "$budget_names"

