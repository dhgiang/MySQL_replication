#!/bin/bash

ACTION=$1
AGE=$2

if [ -z $ACTION ];
then
        echo "Usage $1: Define ACTION of backup or delete"
        exit 1
fi

if [ "$ACTION" = "delete" ] && [ -z $AGE ];
then
        echo "please enter the age of backups you would like to delete"
        exit 1
fi

function backup_ebs () {
        for instance in $(aws ec2 describe-instances --filters "Name=tag-key,Values=slave" | jq .Reservations[].Instances[].InstanceId | sed 's/\"//g')
        do


        for volume in $(aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=$instance" | jq .Volumes[].VolumeId | sed 's/\"//g')
        do
                echo Creating snapshot for $volume $(aws ec2 create-snapshot --volume-id $volume --description "backup-script-for-slave")
        done
   done
}

function delete_snapshots () {
        for snapshot in $(aws ec2 describe-snapshots --filters Name=description,Values=backup-script | jq .Snapshots[].SnapshotId | sed 's/\"//g')
        do
                SNAPSHOTDATE=$(aws ec2 describe-snapshots --filters Name=snapshot-id,Values=$snapshot | jq .Snapshots[].StartTime | cut -d T -f1 | sed 's/\"//g')
                STARTDATE=$(date +%s)
                ENDDATE=$(date -d $SNAPSHOTDATE +%s)
                INTERVAL=$[ (STARTDATE -ENDDATE) / (60*60*24) ]
                if (( $INTERVAL >= $AGE ));
                   then
                        echo "Deleting snapshot $snapshot"
                        aws ec2 delete-snapshot --snapshot-id $snapshot
                fi
        done
}

case $ACTION in
        "backup") backup_ebs ;;
        "delete") delete_snapshots ;;
esac
