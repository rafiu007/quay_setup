**Follow the below steps to set up quay with clairv4(modified claircore with crda) scanning**


1. Create a project on your cluster

2. move into the cluster using oc project <name>

3. Create the redhat-pull secret using the below command

```oc create secret generic redhat-pull-secret --from-file=".dockerconfigjson=config1.json" --type='kubernetes.io/dockerconfigjson'```

4. Install the Quay operator from operators hub

5. use the below command to deploy quay with clair v2 scanning in non tls mode.
```oc apply -f quayecosystem.yaml```

6. Create the config for cliarv4 using the below command.
```oc create  secret generic con-clair --from-file=./config.yaml```

7. run jager
```oc apply -f jager.yaml```

8. run postgres-db for clair v4
```oc apply -f clairv4_db.yaml```

9. run clair v4
```oc apply -f clairv4.yaml```

10. use oc get routes to get the endpoints for quay and qauay-config.

11. download config.tar.gz from quay-config ui.

12. unpack it and add the below lines to config.yaml.

```SECURITY_SCANNER_V4_ENDPOINT: http://clairv4```
```SECURITY_SCANNER_V4_NAMESPACE_WHITELIST:```
```  - "clairv4"```


13. create another tar.gz from the new config and upload this through quay-config ui.
```tar -czvf quaypj.tar.gz extra_ca_certs config.yaml```

14. Wait for pod to restart


15. Configure podman to interact with non tls quay.Use the below commands
```cd /etc/containers```
```vi registries.conf```

16. Add the route for quay in the insecure registries and save the file.

17. Push and pull with podman.

18. create pull secret for cso.(optional)
```oc create secret generic pull-secret --from-file=".dockerconfigjson=pullsec.json" --type='kubernetes.io/dockerconfigjson'```
