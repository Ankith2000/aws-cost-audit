#!/bin/bash

ACCOUNT_ID = $(aws sts get-caller-identity --query Account --output text)
REGION = $(aws configure get region)

echo "Cost audit started on $(date + '%d-%b-%Y %H:%M:%S')"
echo "Account : $ACCOUNT_ID | Region: $REGION"
echo "----------------------------------------"

#Call individual scripts

echo "\n-- Check budget and delete unused ones"
./check_budgets.sh

echo "\n-- Check idle ec2 instances"
./check_idle_ec2.sh

echo "\n-- Check Untagged Resources"
./check_untagged_resources.sh

echo "\n-- Check S3 Lifecycle"
./check_s3_lifecycle.sh

echo "\n-- Check Old RDS snapshots"
./check_old_rds_snapshots.sh

echo "\n-- Check idle load balancers"
./check_idle_load_balancers.sh

echo "\n-- Check Forgotten EBS"
./check_forgotten_ebs.sh

echo -e "\n AWS Audit Completed"