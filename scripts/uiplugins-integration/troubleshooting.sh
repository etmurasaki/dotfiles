#!/bin/bash
oc apply -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bad-deployment
  namespace: default
spec:
  selector:
    matchLabels:
      app: bad-deployment
  template:
    metadata:
      labels:
        app: bad-deployment
    spec:
      containers:
      - name: bad-deployment
        image: quay.io/openshift-logging/vector:5.8
EOF


oc apply -f - <<EOF
apiVersion: observability.openshift.io/v1alpha1
kind: UIPlugin
metadata:
  name: troubleshooting-panel
spec:
  type: TroubleshootingPanel
EOF

