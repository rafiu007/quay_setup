#!/bin/sh
# Thanks to https://gist.github.com/earljon/8579429f90c3480c06eb2bc952255987
HOSTED_ZONE_ID=$1
NAME=$2
JSON_FILE="del-records.json"
echo "Deleting DNS Record set"
aws route53 list-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --output json | jq '[.ResourceRecordSets[] | select(.Name | test("${Name}")) | {ResourceRecordSet: ., Action: "DELETE"}] | {Changes: ., Comment: "Delete record sets for ${NAME}"}' > $JSON_FILE
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch file://$JSON_FILE >/dev/null
echo "Deleting record set ..."
rm -fr $JSON_FILE
echo
echo "Operation Completed."
