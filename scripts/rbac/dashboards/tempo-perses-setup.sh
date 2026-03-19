#!/bin/bash
# =============================================================================
# Tempo Datasource for Perses on OpenShift
# =============================================================================
# This script sets up a Tempo datasource for Perses dashboards on OpenShift
# with TempoStack multi-tenancy enabled.
#
# Prerequisites:
# - OpenShift cluster with COO (Cluster Observability Operator) installed
# - TempoStack deployed (via tracing.sh or similar)
# - Perses deployed via COO UIPlugin
#
# Usage: ./tempo-perses-setup.sh
#
# =============================================================================
# HOW THE SECRET MECHANISM WORKS:
# =============================================================================
# 1. You define `client.tls` in the PersesDatasource CR with the CA path
# 2. The Perses operator reads this and creates an internal Perses secret
#    named `{datasource-name}-secret` with the TLS configuration
# 3. The secret is stored at: /perses/secrets/{namespace}/{name}-secret.yaml
#    with content like:
#      spec:
#        tlsConfig:
#          caFile: /ca/service-ca.crt
# 4. The datasource MUST reference this secret via `secret: {name}-secret`
#    in the proxy spec for the TLS config to be actually used
# =============================================================================

set -e

# Configuration - modify these as needed
TEMPO_NAMESPACE="chainsaw-multitenancy"
TEMPO_STACK_NAME="simplest"
TENANT_NAME="dev"

echo "=============================================="
echo "Setting up Tempo Datasource for Perses"
echo "=============================================="
echo "Namespace: ${TEMPO_NAMESPACE}"
echo "TempoStack: ${TEMPO_STACK_NAME}"
echo "Tenant: ${TENANT_NAME}"
echo ""

# -----------------------------------------------------------------------------
# Step 1: Verify TempoStack is running
# -----------------------------------------------------------------------------
echo "Step 1: Verifying TempoStack..."
oc get tempostack ${TEMPO_STACK_NAME} -n ${TEMPO_NAMESPACE} -o name || {
    echo "ERROR: TempoStack '${TEMPO_STACK_NAME}' not found in namespace '${TEMPO_NAMESPACE}'"
    echo "Please run tracing.sh first to deploy the TempoStack"
    exit 1
}
echo "✓ TempoStack found"
echo ""

# -----------------------------------------------------------------------------
# Step 2: Verify Tempo Gateway service exists
# -----------------------------------------------------------------------------
echo "Step 2: Verifying Tempo Gateway service..."
GATEWAY_SVC="tempo-${TEMPO_STACK_NAME}-gateway"
oc get svc ${GATEWAY_SVC} -n ${TEMPO_NAMESPACE} -o name || {
    echo "ERROR: Tempo Gateway service not found"
    exit 1
}
echo "✓ Tempo Gateway service found: ${GATEWAY_SVC}"
echo ""

# -----------------------------------------------------------------------------
# Step 3: Create the PersesDatasource
# -----------------------------------------------------------------------------
echo "Step 3: Creating PersesDatasource..."

# Key configuration notes:
# - URL must include /tempo suffix for multi-tenant gateway
# - secret reference is required for TLS to work
# - X-Scope-OrgID header identifies the tenant

cat << EOF | oc apply -f -
apiVersion: perses.dev/v1alpha1
kind: PersesDatasource
metadata:
  name: tempo-datasource
  namespace: ${TEMPO_NAMESPACE}
spec:
  config:
    display:
      name: "Tempo Datasource"
    default: true
    plugin:
      kind: "TempoDatasource"
      spec:
        proxy:
          kind: HTTPProxy
          spec:
            # IMPORTANT: URL must end with /tempo for the multi-tenant gateway
            url: https://${GATEWAY_SVC}.${TEMPO_NAMESPACE}.svc.cluster.local:8080/api/traces/v1/${TENANT_NAME}/tempo
            headers:
              X-Scope-OrgID: ${TENANT_NAME}
            # IMPORTANT: Must reference secret for TLS config to be applied
            secret: tempo-datasource-secret
  client:
    tls:
      enable: true
      caCert:
        type: file
        # This path is where COO mounts the OpenShift service CA in Perses
        certPath: /ca/service-ca.crt
EOF

echo "✓ PersesDatasource created"
echo ""

# -----------------------------------------------------------------------------
# Step 4: Verify the datasource was created successfully
# -----------------------------------------------------------------------------
echo "Step 4: Verifying PersesDatasource..."
sleep 3
oc get persesdatasource tempo-datasource -n ${TEMPO_NAMESPACE} -o jsonpath='{.status.conditions[0].message}'
echo ""
echo ""

# -----------------------------------------------------------------------------
# Step 4b: Verify the secret was auto-created by Perses operator
# -----------------------------------------------------------------------------
# NOTE: The Perses operator automatically creates the secret from the 
# client.tls configuration. The secret contains tlsConfig.caFile pointing
# to the CA certificate path.
echo "Step 4b: Verifying auto-created secret..."
echo "The Perses operator automatically creates 'tempo-datasource-secret' from client.tls config"

# Check if secret exists in Perses internal storage
PERSES_NS="openshift-cluster-observability-operator"
oc exec -n ${PERSES_NS} perses-0 -- cat /perses/secrets/${TEMPO_NAMESPACE}/tempo-datasource-secret.yaml 2>/dev/null && {
    echo "✓ Secret 'tempo-datasource-secret' found in Perses"
} || {
    echo "⚠ Secret not yet synced - waiting 5 more seconds..."
    sleep 5
    oc exec -n ${PERSES_NS} perses-0 -- cat /perses/secrets/${TEMPO_NAMESPACE}/tempo-datasource-secret.yaml 2>/dev/null || {
        echo "ERROR: Secret was not created. Check Perses operator logs."
    }
}
echo ""

# -----------------------------------------------------------------------------
# Step 5: Generate test traces (optional)
# -----------------------------------------------------------------------------
echo "Step 5: Generating test traces..."
read -p "Generate test traces? (y/N): " generate_traces
if [[ "$generate_traces" =~ ^[Yy]$ ]]; then
    # Delete existing jobs if they exist
    oc delete job generate-traces-grpc generate-traces-http -n ${TEMPO_NAMESPACE} 2>/dev/null || true
    
    cat << EOF | oc apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: generate-traces-grpc
  namespace: ${TEMPO_NAMESPACE}
spec:
  template:
    spec:
      containers:
      - name: telemetrygen
        image: ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.92.0
        args:
        - traces
        - --otlp-endpoint=dev-collector:4317
        - --service=grpc-test-service
        - --otlp-insecure
        - --traces=20
      restartPolicy: Never
---
apiVersion: batch/v1
kind: Job
metadata:
  name: generate-traces-http
  namespace: ${TEMPO_NAMESPACE}
spec:
  template:
    spec:
      containers:
        - name: telemetrygen
          image: ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.92.0
          args:
            - traces
            - --otlp-endpoint=dev-collector:4318
            - --otlp-http
            - --otlp-insecure
            - --service=http-test-service
            - --traces=20
      restartPolicy: Never
EOF
    echo "✓ Test trace jobs created"
    echo "Waiting for jobs to complete..."
    sleep 10
    oc get jobs -n ${TEMPO_NAMESPACE} | grep generate
fi
echo ""

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo "=============================================="
echo "Setup Complete!"
echo "=============================================="
echo ""
echo "PersesDatasource Details:"
echo "  Name: tempo-datasource"
echo "  Namespace: ${TEMPO_NAMESPACE}"
echo "  URL: https://${GATEWAY_SVC}.${TEMPO_NAMESPACE}.svc.cluster.local:8080/api/traces/v1/${TENANT_NAME}/tempo"
echo ""
echo "To use in Perses Dashboard:"
echo "  1. Go to Dashboards in the OpenShift Console"
echo "  2. Create or edit a dashboard in project '${TEMPO_NAMESPACE}'"
echo "  3. Add a panel with Type: 'Trace Table'"
echo "  4. Select Tempo Datasource: 'Default (tempo-datasource from project)'"
echo "  5. TraceQL Expression: {} (empty query to get all traces)"
echo "  6. Click 'Run Query'"
echo ""
echo "Key Configuration Points:"
echo "  - URL must include '/tempo' suffix for multi-tenant gateway"
echo "  - 'secret' field in proxy spec is REQUIRED for TLS"
echo "  - X-Scope-OrgID header identifies the tenant"
echo "  - TLS uses OpenShift service CA at /ca/service-ca.crt"
echo ""
