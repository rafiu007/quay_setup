# oc create -f https://raw.githubusercontent.com/minio/minio-operator/master/minio-operator.yaml
#Create a Project
oc new-project quay-enterprise
# install quay operator
oc apply -f quay-op.yaml
# install cso operator
oc apply -f cso.yaml
# add pull secrete for quay images
oc create secret generic redhat-pull-secret --from-file=".dockerconfigjson=docker_quay.json" --type='kubernetes.io/dockerconfigjson'
#CSO takes a lot of time to come up so need to wait before bringing up quayecosystem
#sleep 5m
#code to wait for CSO to come up
oc get QuayEcosystem
while true; do
  oc get QuayEcosystem
  if [ "$?" == "0" ]; then
    oc apply -f quayecosystem.yaml
    break
  fi
  sleep 1
done
# create quay instance
#oc apply -f quayecosystem.yaml

# enable clair v4 scanning for clairv4 org
# this has to be done after creation of quay-enterprise-config-secret
oc patch secret quay-enterprise-config-secret -p "$(oc get secrets quay-enterprise-config-secret -o json | jq -r '.data["config.yaml"] | @base64d | . + "SECURITY_SCANNER_V4_ENDPOINT: http://clairv4\nSECURITY_SCANNER_V4_NAMESPACE_WHITELIST:\n- clairv4\n\n"| @base64 | {"data":{"config.yaml": .}}')"
# add clair v4 config
oc create secret generic con-clair --from-file=./config.yaml
# clair v4 supporting services
oc apply -f jager.yaml
oc apply -f clairv4_db.yaml
oc apply -f clairv4.yaml
