#!/bin/bash
# Deploy minio, does not require an operator.

oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: minio
---
# Example secret, copy to client namespace.
apiVersion: v1
kind: Secret
metadata:
  name: minio
  namespace: minio
stringData:
  access_key_id: minio
  access_key_secret: minio123
  bucketnames: loki
  endpoint: http://minio.minio.svc:9000
type: Opaque
---
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: minio
spec:
  ports:
  - port: 9000
    protocol: TCP
    targetPort: 9000
  selector:
    app.kubernetes.io/name: minio
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: minio
  name: minio
  namespace: minio
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: minio
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app.kubernetes.io/name: minio
    spec:
      containers:
      - command:
        - /bin/sh
        - -c
        - |
          mkdir -p /storage/loki && \
          minio server /storage
        env:
        - name: MINIO_ACCESS_KEY
          value: minio
        - name: MINIO_SECRET_KEY
          value: minio123
        image: quay.io/minio/minio
        name: minio
        ports:
        - containerPort: 9000
        volumeMounts:
        - mountPath: /storage
          name: storage
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: minio
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app.kubernetes.io/name: minio
  name: minio
  namespace: minio
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

# oc apply -f - <<EOF
# apiVersion: v1
# kind: Namespace
# metadata:
#   labels:
#     openshift.io/cluster-monitoring: "true"
#   name: openshift-netobserv-operator
# ---
# apiVersion: operators.coreos.com/v1
# kind: OperatorGroup
# metadata:
#   annotations:
#     olm.providedAPIs: "FlowCollector.v1alpha1.flows.netobserv.io,FlowCollector.v1beta1.flows.netobserv.io,FlowCollector.v1beta2.flows.netobserv.io,FlowMetric.v1alpha1.flows.netobserv.io"
#   name: openshift-netobserv-operator-hack
#   namespace: openshift-netobserv-operator
# spec:
#   upgradeStrategy: Default
# ---
# apiVersion: operators.coreos.com/v1alpha1
# kind: Subscription
# metadata:
#   name: netobserv-operator
#   namespace: openshift-netobserv-operator
# spec:
#   channel: stable
#   installPlanApproval: Automatic
#   name: netobserv-operator
#   source: redhat-operators
#   sourceNamespace: openshift-marketplace
# EOF

# oc apply -f - <<EOF
# kind: Namespace
# apiVersion: v1
# metadata:
#   name: openshift-operators-redhat
#   annotations:
#     openshift.io/node-selector: ""
#   labels:
#     openshift.io/cluster-logging: "true"
#     openshift.io/cluster-monitoring: "true"
# EOF

# oc apply -f - <<EOF
# apiVersion: operators.coreos.com/v1
# kind: OperatorGroup
# metadata:
#   name: openshift-operators-redhat
#   namespace: openshift-operators-redhat
# spec: {}
# EOF

# oc apply -f - <<EOF
# apiVersion: operators.coreos.com/v1alpha1
# kind: Subscription
# metadata:
#   name: loki-operator
#   namespace: openshift-operators-redhat
# spec:
#   channel: "stable-6.2"
#   installPlanApproval: Automatic
#   name: loki-operator
#   source: redhat-operators
#   sourceNamespace: openshift-marketplace
# EOF