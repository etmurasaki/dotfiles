#!/bin/bash

# Generate a random filename
RANDOM_FILE="/tmp/coo_monitoring_csv_$(date +%s%N).yaml"

read -p "MCP_IMAGE: " mcp_image
export MCP_IMAGE="$mcp_image"

read -p "COO_OBO_NAMESPACE: " coo_obo_namespace
export COO_OBO_NAMESPACE="$coo_obo_namespace"

COO_CSV_NAME=$(oc get csv --namespace="${COO_OBO_NAMESPACE}" | grep "cluster-observability-operator" | awk '{print $1}')

oc get csv "${COO_CSV_NAME}" -n "${COO_OBO_NAMESPACE}" -o yaml > "${RANDOM_FILE}"

# Patch the CSV file env vars
sed -i "s#value: .*monitoring-console-plugin.*#value: ${MCP_IMAGE}#g" "${RANDOM_FILE}"

# Patch the CSV file related images
sed -i "s#^\([[:space:]]*- image:\).*monitoring-console-plugin.*#\1 ${MCP_IMAGE}#g" "${RANDOM_FILE}"

# Apply the patched CSV resource file
oc replace -f "${RANDOM_FILE}"

# Wait for the operator to reconcile the change and make sure all the pods are running.
sleep 25
OUTPUT=`oc wait --for=condition=ready pods -l app.kubernetes.io/name=observability-operator -n "${COO_OBO_NAMESPACE}" --timeout=60s`
echo "${OUTPUT}"

rm "${RANDOM_FILE}"