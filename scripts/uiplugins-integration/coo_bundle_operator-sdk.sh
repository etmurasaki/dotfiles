#!/bin/bash
echo COO install through COO Bundle

kubectl patch Scheduler cluster --type='json' -p '[{ "op": "replace", "path": "/spec/mastersSchedulable", "value": true }]'

read -p 'bundle ' bundle

oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: ImageDigestMirrorSet
metadata:
 name: idms-coo
spec:
 imageDigestMirrors:
 - mirrors:
   - quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator
   source: registry.redhat.io/cluster-observability-operator
EOF

oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  labels:
    openshift.io/cluster-monitoring: "true"
  name: openshift-cluster-observability-operator
EOF

oc project openshift-cluster-observability-operator

operator-sdk run bundle ${bundle} --install-mode AllNamespaces --security-context-config restricted
