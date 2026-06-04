#!/usr/bin/env bash
# Creates a namespace and a pod that periodically writes log lines tagged with
# different levels: critical, error, warning, debug, info, trace, unknown.
#
# Usage:
#   ./k8s-log-levels-demo.sh [NAMESPACE]
# Default namespace: log-level-demo
#
# Teardown:
#   kubectl delete namespace "${NAMESPACE:-log-level-demo}"

set -euo pipefail

NS="${1:-log-level-demo}"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found in PATH" >&2
  exit 1
fi

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-level-logger
  namespace: ${NS}
  labels:
    app: multi-level-logger
spec:
  replicas: 1
  selector:
    matchLabels:
      app: multi-level-logger
  template:
    metadata:
      labels:
        app: multi-level-logger
    spec:
      containers:
        - name: logger
          image: busybox:1.36
          imagePullPolicy: IfNotPresent
          command: ["/bin/sh", "-c"]
          args:
            - |
              set -eu
              i=0
              while true; do
                i=\$((i + 1))
                ts=\$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                echo "ts=\${ts} level=critical seq=\${i} msg=demo critical event"
                echo "ts=\${ts} level=error seq=\${i} msg=demo error event" >&2
                echo "ts=\${ts} level=warning seq=\${i} msg=demo warning event"
                echo "ts=\${ts} level=debug seq=\${i} msg=demo debug event"
                echo "ts=\${ts} level=info seq=\${i} msg=demo info event"
                echo "ts=\${ts} level=trace seq=\${i} msg=demo trace event"
                echo "ts=\${ts} level=unknown seq=\${i} msg=demo unclassified event"
                sleep 5
              done
EOF

echo "Applied namespace ${NS} and Deployment multi-level-logger."
echo "Wait for the pod, then:"
echo "  kubectl -n ${NS} logs -l app=multi-level-logger -f"
echo "Remove with:"
echo "  kubectl delete namespace ${NS}"
