# List down the idle EC2

#!/bin/bash

source ./utils.sh

ACCOUNT_ID = $(get_account_id)
REGION = $(aws configure get region)

echo "Check for idle EC2 instances"

#CPU Utilization below whicch instance is considered to be in idle state

CPU_THRESHOLD = 10

#No of days taken to evaluate it
DAYS = 3

#retrieve list of running instance ids
instance_ids = $(aws ec2 describe-instances\
--filters "Name=instance-state-name , values=running"
--query 'Reservations[*].Instances[*].Instanceid'
--output text)

#Check if no instances were found
if[-z $instance_ids]; then
log_warn "No running ec2 instances"
exit 0
fi

#Loop through each instance id retrieved
for id in $instance_ids; do
  #retrieve instance_type for current instance
  instance_type = $(aws ec2 describe-instances\
  --instance-ids "$id"\
  --query 'Reservations[0].Instances[0].InstanceType' \ 
  --output text
  ) 


  avg_cpu=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=$id \
    --statistics Average \
    --period 86400 \
    --start-time $(date -u -d "$DAYS days ago" +"%Y-%m-%dT%H:%M:%SZ") \
    --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --query 'Datapoints[*].Average' --output text | awk '{ sum+=$1; count++ } END { if (count > 0) print sum/count; else print 0 }')

if ($(echo "$avg_cpu < $CPU_THRESHOLD" | bc -l)); then
log_warn "Idle instance: $id ($instance_type) - Avg CPU: $(avg_cpu)%"
else 
log_success "No idle instances"
fi
done