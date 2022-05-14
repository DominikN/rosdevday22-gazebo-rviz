#!/bin/bash

declare -a PEERS=("rosds" "rviz2")
OUTPUT_PATH="./secret"
DDS_FILE_NAME_1="dds-config.server.template.xml"
DDS_FILE_NAME_2="dds-config.client.template.xml"

mkdir -p $OUTPUT_PATH
cp $DDS_FILE_NAME_1 $OUTPUT_PATH/dds-config.server.xml
cp $DDS_FILE_NAME_2 $OUTPUT_PATH/dds-config.client.xml

for (( j=0; j<${#PEERS[@]}; j++ ));
do
    printf "no %d: generating config for \"%s\"\n" $j "${PEERS[$j]}"
    docker run --rm -it husarnet/husarnet:latest husarnet genid > $OUTPUT_PATH/"id_${PEERS[$j]}"
    sed -i "s/${PEERS[$j]}/$(sed -r 's/([a-f0-9:]*)\s.*/\1/g' $OUTPUT_PATH/id_${PEERS[$j]})/g" $OUTPUT_PATH/dds-config.server.xml
    sed -i "s/${PEERS[$j]}/$(sed -r 's/([a-f0-9:]*)\s.*/\1/g' $OUTPUT_PATH/id_${PEERS[$j]})/g" $OUTPUT_PATH/dds-config.client.xml
done
