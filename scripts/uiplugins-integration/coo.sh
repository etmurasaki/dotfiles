#!/bin/bash
kubectl patch Scheduler cluster --type='json' -p '[{ "op": "replace", "path": "/spec/mastersSchedulable", "value": true }]'

oc create namespace openshift-cluster-observability-operator

oc label namespace  openshift-cluster-observability-operator openshift.io/cluster-monitoring="true"

oc project openshift-cluster-observability-operator

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

operator-sdk run bundle quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:52f65ea303b34b2a62ac26e5f8298881b3fa41854a939e1a920a4b814f95948c --namespace openshift-cluster-observability-operator --security-context-config restricted

