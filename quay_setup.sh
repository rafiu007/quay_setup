# oc create -f https://raw.githubusercontent.com/minio/minio-operator/master/minio-operator.yaml

check(){
  eval VAR1="$1"
  eval VAR2="$2"
  while true; do
    if [[ $2 == "1" ]]
    then
      echo "Waiting for  secret......................................"
      eval $VAR1
      if [[ $? == "0" ]]
      then
        echo "Secret found..........................................."
        break
      fi
    else
      VAR3=$($VAR1 2>&1)
      echo "Checking for QuayEcosystem................................."
      if [[ $VAR3 == $VAR2 ]]
      then
        break
      fi
    fi
    sleep 1
  done
}

#Create a Project
oc new-project quay-enterprise
# install quay operator
oc apply -f quay-op.yaml
# install cso operator
oc apply -f cso.yaml
# add pull secrete for quay images
oc create secret generic redhat-pull-secret --from-file=".dockerconfigjson=docker_quay.json" --type='kubernetes.io/dockerconfigjson'
#Quay-operator takes some time to come(especially on crc) up so need to wait before bringing up quayecosystem

#code to wait for quay-operator to come up
req="No resources found in quay-enterprise namespace."
com="oc get QuayEcosystem"
check "\${com}" "\${req}"

# create quay instance
oc apply -f quayecosystem.yaml

# add clair v4 config
oc create secret generic con-clair --from-file=./config.yaml
# clair v4 supporting services
oc apply -f jager.yaml
oc apply -f clairv4_db.yaml
oc apply -f clairv4.yaml


#Check if secret is created

com="oc get secrets quay-enterprise-config-secret"
check "\${com}" "1"

#Wait for secret to get populated
com="oc get secrets quay-enterprise-config-secret -o json | jq -r '.data[\"config.yaml\"]' | grep -v null"
check "\${com}" "1"

# enable clair v4 scanning for clairv4 org
# this has to be done after creation of quay-enterprise-config-secret
oc patch secret quay-enterprise-config-secret -p "$(oc get secrets quay-enterprise-config-secret -o json | jq -r '.data["config.yaml"] | @base64d | . + "SECURITY_SCANNER_V4_ENDPOINT: http://clairv4\nSECURITY_SCANNER_V4_NAMESPACE_WHITELIST:\n- clairv4\n\n"| @base64 | {"data":{"config.yaml": .}}')"

