#!/bin/bash
kubectl patch Scheduler cluster --type='json' -p '[{ "op": "replace", "path": "/spec/mastersSchedulable", "value": true }]'

oc create namespace observability-operator

oc label namespace observability-operator openshift.io/cluster-monitoring="true"

oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: ImageDigestMirrorSet
metadata:
  name: idms-coo
spec:
  imageDigestMirrors:
  - mirrors:
    - registry.stage.redhat.io
    source: registry.redhat.io
EOF

oc project observability-operator

operator-sdk run bundle quay.io/rh-ee-emurasak/observability-operator-bundle:1.3.1-a --namespace observability-operator --security-context-config restricted
# operator-sdk run bundle quay.io/rh-ee-emurasak/observability-operator-bundle:1.3.1-a --namespace observability-operator

