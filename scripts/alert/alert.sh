#!/bin/bash

namespace=$1

read -p "Enter the namespace: " namespace

if [ -z "$namespace" ]; then
    echo "Error: Namespace cannot be empty."
    exit 1
fi

oc apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: story-rules
  namespace: openshift-monitoring
spec:
  groups:
  - name: alerting rules
    rules:
    - alert: Testalert
      expr: vector(1)
      labels:
        severity: none
        namespace: $namespace
      annotations:
        message: This is an alert meant to ensure that the entire alerting pipeline is functional. 
EOF