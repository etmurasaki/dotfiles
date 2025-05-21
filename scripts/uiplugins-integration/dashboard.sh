#!/bin/bash
oc apply -f - <<EOF
apiVersion: observability.openshift.io/v1alpha1
kind: UIPlugin
metadata:
  name: dashboards
spec:
  type: Dashboards
EOF

oc apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-datasource-test
  namespace: openshift-config-managed
  labels:
    console.openshift.io/dashboard-datasource: 'true'
data:
  'dashboard-datasource.yaml': |-
    kind: "Datasource"
    metadata:
      name: "prometheus-datasource-test"
      project: "openshift-config-managed"
    spec:
      plugin:
        kind: "PrometheusDatasource"
        spec:
          direct_url: "https://thanos-querier.openshift-monitoring.svc.cluster.local:9091"
EOF

cd /Users/emurasak/workspace/dotfiles-eve/scripts/uiplugins-integration
oc create configmap test-db-plugin-admin --from-file=prometheus.json -n openshift-config-managed
oc -n openshift-config-managed label cm test-db-plugin-admin console.openshift.io/dashboard=true

