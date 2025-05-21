#!/bin/bash
oc patch clusterversion version --type json -p "$(cat enable-monitoring.yaml)"
kubectl scale --replicas=2 -n openshift-monitoring deployment/cluster-monitoring-operator
kubectl scale --replicas=2 -n openshift-monitoring deployment/monitoring-plugin
