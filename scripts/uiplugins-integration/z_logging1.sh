#!/bin/bash
# Deploy minio, does not require an operator.

oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: minio
stringData:
  access_key_id: minio
  access_key_secret: minio123
  bucketnames: loki
  endpoint: http://minio.minio.svc:9000
type: Opaque
---
apiVersion: loki.grafana.com/v1
kind: LokiStack
metadata:
  name: logging-loki
  namespace: openshift-logging
spec:
  size: 1x.demo
  storage:
    schemas:
    - version: v12
      effectiveDate: '2022-06-01'
    secret:
      name: minio
      type: s3
  storageClassName: REPLACE
  tenants:
    mode: openshift-logging
EOF

oc create sa logcollector || true
oc adm policy add-cluster-role-to-user collect-application-logs -z logcollector
oc adm policy add-cluster-role-to-user collect-infrastructure-logs -z logcollector
oc adm policy add-cluster-role-to-user logging-collector-logs-writer  -z logcollector
oc adm policy add-cluster-role-to-user lokistack-tenant-logs -z logcollector

oc create sa collector -n openshift-logging
oc adm policy add-cluster-role-to-user logging-collector-logs-writer -z collector -n openshift-logging
oc adm policy add-cluster-role-to-user collect-application-logs -z collector -n openshift-logging
oc adm policy add-cluster-role-to-user collect-audit-logs -z collector -n openshift-logging

cat << EOF | oc apply -f -
apiVersion: observability.openshift.io/v1
kind: ClusterLogForwarder
metadata:
  name: collector
  namespace: openshift-logging
spec:
  serviceAccount:
    name: collector
  outputs:
    - name: default-lokistack
      type: lokiStack
      lokiStack:
        target:
          name: logging-loki
          namespace: openshift-logging
        authentication:
          token:
            from: serviceAccount
      tls:
        ca:
          key: service-ca.crt
          configMapName: openshift-service-ca.crt
  pipelines:
    - name: default-logstore
      inputRefs:
        - application
        - infrastructure
      outputRefs:
        - default-lokistack
EOF

oc apply -f - <<EOF
apiVersion: observability.openshift.io/v1alpha1
kind: UIPlugin
metadata:
  name: logging
spec:
  type: Logging
  logging:
    lokiStack:
      name: logging-loki
    logsLimit: 50
    timeout: 30s
EOF


