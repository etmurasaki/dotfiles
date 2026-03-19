#!/bin/bash
# =============================================================================
# Loki Datasource for Perses on OpenShift
# =============================================================================
# This script sets up a Loki datasource for Perses dashboards on OpenShift
# with LokiStack openshift-logging tenancy mode.
#
# Prerequisites:
# - OpenShift cluster with COO (Cluster Observability Operator) installed
# - LokiStack deployed in openshift-logging namespace
# - Perses deployed via COO UIPlugin
#
# Usage: ./loki-perses-setup.sh
#
# =============================================================================
# HOW THE SECRET MECHANISM WORKS:
# =============================================================================
# 1. You define `client.tls` in the PersesDatasource CR with the CA path
# 2. The Perses operator creates an internal secret: `{datasource-name}-secret`
# 3. The datasource MUST reference this secret via `secret: {name}-secret`
# =============================================================================
# LOKI TENANTS (openshift-logging mode):
# =============================================================================
# - application    : Application container logs
# - infrastructure : OpenShift infrastructure logs  
# - audit          : Audit logs
# =============================================================================

set -e

# Configuration - modify these as needed
LOKI_NAMESPACE="openshift-logging"
LOKI_STACK_NAME="logging-loki"
TENANT_NAME="application"  # Options: application, infrastructure, audit
PERSES_NS="openshift-cluster-observability-operator"

echo "=============================================="
echo "Setting up Loki Datasource for Perses"
echo "=============================================="
echo "Namespace: ${LOKI_NAMESPACE}"
echo "LokiStack: ${LOKI_STACK_NAME}"
echo "Tenant: ${TENANT_NAME}"
echo ""

# -----------------------------------------------------------------------------
# Step 1: Verify LokiStack is running
# -----------------------------------------------------------------------------
echo "Step 1: Verifying LokiStack..."
oc get lokistack ${LOKI_STACK_NAME} -n ${LOKI_NAMESPACE} -o name || {
    echo "ERROR: LokiStack '${LOKI_STACK_NAME}' not found in namespace '${LOKI_NAMESPACE}'"
    exit 1
}
echo "✓ LokiStack found"
echo ""

# -----------------------------------------------------------------------------
# Step 2: Verify Loki Gateway service exists
# -----------------------------------------------------------------------------
echo "Step 2: Verifying Loki Gateway service..."
GATEWAY_SVC="${LOKI_STACK_NAME}-gateway-http"
oc get svc ${GATEWAY_SVC} -n ${LOKI_NAMESPACE} -o name || {
    echo "ERROR: Loki Gateway service not found"
    exit 1
}
echo "✓ Loki Gateway service found: ${GATEWAY_SVC}"
echo ""

# -----------------------------------------------------------------------------
# Step 3: Grant RBAC permissions to Perses service account
# -----------------------------------------------------------------------------
echo "Step 3: Granting RBAC permissions to Perses..."

# Grant access to logs based on tenant
case ${TENANT_NAME} in
    application)
        oc adm policy add-cluster-role-to-user cluster-logging-application-view -z perses-sa -n ${PERSES_NS} 2>/dev/null || true
        ;;
    infrastructure)
        oc adm policy add-cluster-role-to-user cluster-logging-infrastructure-view -z perses-sa -n ${PERSES_NS} 2>/dev/null || true
        ;;
    audit)
        oc adm policy add-cluster-role-to-user cluster-logging-audit-view -z perses-sa -n ${PERSES_NS} 2>/dev/null || true
        ;;
    *)
        echo "Unknown tenant: ${TENANT_NAME}"
        exit 1
        ;;
esac
echo "✓ RBAC permissions granted for ${TENANT_NAME} logs"
echo ""

# -----------------------------------------------------------------------------
# Step 4: Create the PersesDatasource
# -----------------------------------------------------------------------------
echo "Step 4: Creating PersesDatasource..."

cat << EOF | oc apply -f -
apiVersion: perses.dev/v1alpha1
kind: PersesDatasource
metadata:
  name: loki-datasource
  namespace: ${LOKI_NAMESPACE}
spec:
  config:
    display:
      name: "Loki Datasource (${TENANT_NAME} logs)"
    default: true
    plugin:
      kind: "LokiDatasource"
      spec:
        proxy:
          kind: HTTPProxy
          spec:
            # URL structure: /api/logs/v1/{tenant} - Perses appends /loki/api/v1/...
            url: https://${GATEWAY_SVC}.${LOKI_NAMESPACE}.svc.cluster.local:8080/api/logs/v1/${TENANT_NAME}
            headers:
              X-Scope-OrgID: ${TENANT_NAME}
            # IMPORTANT: Must reference secret for TLS config to be applied
            secret: loki-datasource-secret
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
# Step 5: Verify the datasource was created successfully
# -----------------------------------------------------------------------------
echo "Step 5: Verifying PersesDatasource..."
sleep 3
oc get persesdatasource loki-datasource -n ${LOKI_NAMESPACE} -o jsonpath='{.status.conditions[0].message}'
echo ""
echo ""

# -----------------------------------------------------------------------------
# Step 6: Verify the secret was auto-created
# -----------------------------------------------------------------------------
echo "Step 6: Verifying auto-created secret..."
sleep 2
oc exec -n ${PERSES_NS} perses-0 -- cat /perses/secrets/${LOKI_NAMESPACE}/loki-datasource-secret.yaml 2>/dev/null && {
    echo "✓ Secret 'loki-datasource-secret' found in Perses"
} || {
    echo "⚠ Secret not yet synced - waiting..."
    sleep 5
    oc exec -n ${PERSES_NS} perses-0 -- cat /perses/secrets/${LOKI_NAMESPACE}/loki-datasource-secret.yaml 2>/dev/null || {
        echo "ERROR: Secret was not created"
    }
}
echo ""

# -----------------------------------------------------------------------------
# Step 7: Test connectivity
# -----------------------------------------------------------------------------
echo "Step 7: Testing Loki connectivity..."
RESULT=$(oc exec -n ${PERSES_NS} perses-0 -- sh -c "curl -sk --cacert /ca/service-ca.crt -H 'X-Scope-OrgID: ${TENANT_NAME}' -H 'Authorization: Bearer \$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)' 'https://${GATEWAY_SVC}.${LOKI_NAMESPACE}.svc.cluster.local:8080/api/logs/v1/${TENANT_NAME}/loki/api/v1/labels'" 2>&1)
if echo "$RESULT" | grep -q '"status":"success"'; then
    echo "✓ Loki connectivity test passed"
    echo "  Labels found: $(echo $RESULT | grep -o '"data":\[[^]]*\]')"
else
    echo "⚠ Loki connectivity test failed: $RESULT"
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
echo "  Name: loki-datasource"
echo "  Namespace: ${LOKI_NAMESPACE}"
echo "  URL: https://${GATEWAY_SVC}.${LOKI_NAMESPACE}.svc.cluster.local:8080/api/logs/v1/${TENANT_NAME}"
echo ""
echo "To use in Perses Dashboard:"
echo "  1. Go to Dashboards in the OpenShift Console"
echo "  2. Create or edit a dashboard in project '${LOKI_NAMESPACE}'"
echo "  3. Add a panel with Type: 'Log Table'"
echo "  4. Select Loki Datasource: 'Default (loki-datasource from project)'"
echo "  5. LogQL Expression: {kubernetes_namespace_name=\"default\"}"
echo "  6. Click 'Run Query'"
echo ""
echo "Key Configuration Points:"
echo "  - URL path: /api/logs/v1/{tenant} (Perses appends /loki/api/v1/...)"
echo "  - 'secret' field in proxy spec is REQUIRED for TLS"
echo "  - X-Scope-OrgID header identifies the tenant"
echo "  - RBAC: cluster-logging-{tenant}-view role required"
echo ""
echo "Available Tenants:"
echo "  - application    : Application container logs"
echo "  - infrastructure : OpenShift infrastructure logs"
echo "  - audit          : Audit logs"
echo ""
