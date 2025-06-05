
# !!! DON'T USE ROSA CLUSTER IT WON'T WORK -- BECAUSE IT'S MANAGED SERVICE!!!

### Hierarchy Tree for Monitoring-plugin: How resources are managed 
* Cluster Version Operator 
    * Cluster Monitoring Operator 
        * Monitoring-Plugin

### Option 1 to Deploy Monitoring-plugin image 
1) Set CMO to unmanaged though: https://access.redhat.com/solutions/6548111 (Red Hat associate access required)
2) and modify the CMO deployment spec to reference your image (https://github.com/openshift/cluster-monitoring-operator/blob/5d1fd1bb52eeb9b2f877c45de0cf93e2f9fffb95/manifests/0000_50_cluster-monitoring-operator_05-deployment.yaml#L76)

### Option 2 to Deploy Monitoring-plugin image 
With cluster-bot  `/launch openshift/monitoring-plugin#xxx aws` where xxx is your PR number



