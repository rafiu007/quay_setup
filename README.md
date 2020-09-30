## Deployment of Quay, Clairv4 with CRDA on Openshift 4.x

### 1. Create Openshift cluster > 4.5
#### 1.1. Cleanup DNS Recordsets on AWS Ephimeral cluster (pre-install)
Below script would help you to reuse the same cluster subdomain for each new cluster deployment.
Note: Make sure that you set correct values to `HOSTED_ZONE_ID` and `NAME`.

```bash
#!/bin/sh
# Thanks to https://gist.github.com/earljon/8579429f90c3480c06eb2bc952255987

HOSTED_ZONE_ID="..."
NAME="..."

JSON_FILE="del-records.json"

echo "Deleting DNS Record set"
aws route53 list-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --output json | jq '[.ResourceRecordSets[] | select(.Name | test("${Name}")) | {ResourceRecordSet: ., Action: "DELETE"}] | {Changes: ., Comment: "Delete record sets for ${NAME}"}' > $JSON_FILE
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch file://$JSON_FILE >/dev/null
echo "Deleting record set ..."
rm -fr $JSON_FILE
echo
echo "Operation Completed."
```

### 2. Use Let's Encrypt certificates on Ingress controller 
#### 2.1. Get certificate pair (One time process)
Follow https://github.com/redhat-cop/openshift-4-alpha-enablement/blob/2d128d28496378e609c00da5312a3a3500fa1702/Lets_Encrypt_Certificates_for_OCP4.adoc
#### 2.2. Use certificate pair on Ingress (post-install)
Note: It is assumed that cert files are present in $PWD/certificates.

```sh
# Let's encrypt related setups
export CERTDIR=$PWD/certificates
oc create secret tls router-certs --cert=${CERTDIR}/fullchain.pem --key=${CERTDIR}/key.pem -n openshift-ingress
oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec": { "defaultCertificate": { "name": "router-certs" }}}'
```
#### 2.3. Enable Enterprise Operators on OKD (Not required for OCP)
```yaml
# To enable enterprise operators on OKD
(
cat <<EOF
apiVersion: config.openshift.io/v1
kind: OperatorHub
metadata:
  name: cluster
spec:
  disableAllDefaultSources: true
  sources:
  - disabled: false
    name: redhat-operators
  - disabled: false
    name: community-operators
EOF
 ) | oc apply -f -
```

### 3. Deploy Quay, CSO
```sh
bash quay_setup.sh
```

### All in one
Note: It is assumed that `install-config` has been created and stored in $PWD using `$INSTALLER_DIR/openshift-install --dir=. create install-config`.

```bash
bash pre-install.sh && $INSTALLER_DIR/openshift-install --dir . create cluster && bash post-install.sh && bash quay_setup.sh
```
