# Scale up the Monitoring-plugin
oc scale --replicas=1 -n openshift-monitoring deployment/cluster-monitoring-operator

oc scale --replicas=1 -n openshift-monitoring deployment/monitoring-plugin
