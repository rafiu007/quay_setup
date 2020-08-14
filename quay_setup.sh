# oc create -f https://raw.githubusercontent.com/minio/minio-operator/master/minio-operator.yaml

exec_and_wait(){
  while true; do
    eval $1
    if [[ $? == 0 ]]
    then
      break
    fi
    sleep 1
  done
}

#Create a Project
oc new-project quay-enterprise
# install quay operator
oc apply -f quay-op.yaml
# add pull secrete for quay images
oc create secret generic redhat-pull-secret --from-file=".dockerconfigjson=docker_quay.json" --type='kubernetes.io/dockerconfigjson'
#Quay-operator takes some time to come(especially on crc) up so need to wait before bringing up quayecosystem

#code to wait for quay-operator to come up
command=
exec_and_wait "oc get pods -o json | jq -r '.items[0].status.phase' | grep Running"

# create quay instance
oc apply -f quayecosystem.yaml

# add clair v4 config
oc create secret generic con-clair --from-file=./config.yaml
# clair v4 supporting services
oc apply -f jager.yaml
oc apply -f clairv4_db.yaml
oc apply -f clairv4.yaml


#Check if secret is created
exec_and_wait "oc get secrets quay-enterprise-config-secret"

#Wait for secret to get populated
exec_and_wait "oc get secrets quay-enterprise-config-secret -o json | jq -r '.data[\"config.yaml\"]' | grep -v null"

# enable clair v4 scanning for clairv4 org
# this has to be done after creation of quay-enterprise-config-secret
oc patch secret quay-enterprise-config-secret -p "$(oc get secrets quay-enterprise-config-secret -o json | jq -r '.data["config.yaml"] | @base64d | . + "SECURITY_SCANNER_V4_ENDPOINT: http://clairv4\nSECURITY_SCANNER_V4_NAMESPACE_WHITELIST:\n- clairv4\n\n"| @base64 | {"data":{"config.yaml": .}}')"

# install cso operator
oc apply -f cso.yaml
