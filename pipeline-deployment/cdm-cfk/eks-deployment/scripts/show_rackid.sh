#!/bin/env bash

KAFKA_PROP_PATH="/opt/confluentinc/etc/kafka/kafka.properties"

if [ -z "$NAMESPACE" ]
then
        echo "Error : variable \$NAMESPACE is not set"
        echo "export $NAMESPACE=\"cdm-kafka\" "
        exit 99
fi


function get_rackid(){
        broker=$1
        RACK_ID="$( kubectl -n ${NAMESPACE} exec $broker -- grep 'broker.rack' $KAFKA_PROP_PATH 2> /dev/null | cut -d"=" -f2 )"
        echo $RACK_ID
}

function get_node_zone_label(){
        node=$1

        ZONE_LABEL="$( kubectl -n ${NAMESPACE} get node ${NODE} \
                -o=custom-columns=NODE:.metadata.name,ZONE:.metadata.labels."topology\.kubernetes\.io/zone" | \
                grep ${NODE} | \
                awk '{print $2}' )"

        echo $ZONE_LABEL
}

while read -r POD READY STATUS RESTARTS AGE IP NODE NOMINATED READINESS
do
        RACKID="$(get_rackid $POD)"
        ZONE="$(get_node_zone_label $NODE)"
        echo "BROKER='$POD' RACKID='$RACKID' NODE='$NODE' NODE_ZONE='$ZONE' "

        #cho $POD

done <<< "$( kubectl -n $NAMESPACE get pods -owide | grep 'kafka-' )"
