#!/bin/bash

declare -a PEERS=("rosds" "rviz2" "discovery_server")
OUTPUT_PATH="./secret"
DDS_FILE_NAME_1="router-config.server.template.yaml"
DDS_FILE_NAME_2="router-config.client.template.yaml"

mkdir -p $OUTPUT_PATH
cp $DDS_FILE_NAME_1 $OUTPUT_PATH/router-config.server.yaml
cp $DDS_FILE_NAME_2 $OUTPUT_PATH/router-config.client.yaml

for (( j=0; j<${#PEERS[@]}; j++ ));
do
    printf "no %d: generating config for \"%s\"\n" $j "${PEERS[$j]}"
    docker run --rm -it husarnet/husarnet:latest husarnet genid > $OUTPUT_PATH/"id_${PEERS[$j]}"
    sed -i "s/${PEERS[$j]}/$(sed -r 's/([a-f0-9:]*)\s.*/\1/g' $OUTPUT_PATH/id_${PEERS[$j]})/g" $OUTPUT_PATH/router-config.server.yaml
    sed -i "s/${PEERS[$j]}/$(sed -r 's/([a-f0-9:]*)\s.*/\1/g' $OUTPUT_PATH/id_${PEERS[$j]})/g" $OUTPUT_PATH/router-config.client.yaml
done
