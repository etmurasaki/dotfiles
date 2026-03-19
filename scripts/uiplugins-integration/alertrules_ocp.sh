#!/bin/bash
# Creates the same alert rules from acm1.sh as a PrometheusRule in OCP native monitoring.
# These will appear in the Administrator perspective under Observe > Alerting.

oc apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: alertrule-testing
  namespace: openshift-monitoring
  labels:
    role: alert-rules
spec:
  groups:
    - name: alertrule-testing
      rules:
        - alert: Watchdog
          annotations:
            summary: An alert that should always be firing to certify that Alertmanager is working properly.
            description: This is an alert meant to ensure that the entire alerting pipeline is functional.
          expr: vector(1)
          labels:
            instance: "local"
            cluster: "local"
            clusterID: "111111111"
            severity: info
        - alert: Watchdog-spoke
          annotations:
            summary: An alert that should always be firing to certify that Alertmanager is working properly.
            description: This is an alert meant to ensure that the entire alerting pipeline is functional.
          expr: vector(1)
          labels:
            instance: "spoke"
            cluster: "spoke"
            clusterID: "22222222"
            severity: warning
    - name: cluster-health
      rules:
        - alert: ClusterCPUHealth-jb
          annotations:
            summary: Notify when CPU utilization on a cluster is greater than the defined utilization limit
            description: "The cluster has a high CPU usage: core for."
          expr: |
            max(cluster:cpu_usage_cores:sum) by (clusterID, cluster, prometheus) > 0
          labels:
            cluster: "{{ \$labels.cluster }}"
            prometheus: "{{ \$labels.prometheus }}"
            severity: critical
EOF
