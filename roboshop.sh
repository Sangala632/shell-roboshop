#!/bin/bash
export PATH=/usr/local/bin:/usr/bin:/bin

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0868578a5e618f64a"
ZONE_ID="Z100104611ELJF6AI8M2E"
DOMAIN_NAME="daws84s.site"

for instance in "$@"
do
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance IP: $IP"

    cat <<EOF > /tmp/record.json
{
    "Comment": "UPSERT record",
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "$RECORD_NAME",
          "Type": "A",
          "TTL": 1,
          "ResourceRecords": [
            {
              "Value": "$IP"
            }
          ]
        }
      }
    ]
}
EOF

    aws route53 change-resource-record-sets \
      --hosted-zone-id $ZONE_ID \
      --change-batch file:///tmp/record.json
done
