#!/bin/bash
oc patch clusterversion version --type json -p "$(cat disable-monitoring.yaml)"
kubectl scale --replicas=0 -n openshift-monitoring deployment/cluster-monitoring-operator
kubectl scale --replicas=0 -n openshift-monitoring deployment/monitoring-plugin
kubectl delete ConsolePlugin monitoring-plugin
