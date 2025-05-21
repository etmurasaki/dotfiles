#!/bin/bash
cd /Users/emurasak/workspace/aosqe-tools/logging/log_template/korrel8r/
./deploy-trace-operators.sh

oc apply -f - <<EOF
apiVersion: observability.openshift.io/v1alpha1
kind: UIPlugin
metadata:
  name: distributed-tracing
spec:
  type: DistributedTracing
EOF

oc apply -f - <<EOF
# The namespace is auto-deleted by chainsaw after the test run.
apiVersion: v1
kind: Namespace
metadata:
  name: chainsaw-multitenancy
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app.kubernetes.io/name: minio
  name: minio
  namespace: chainsaw-multitenancy
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: chainsaw-multitenancy
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
              mkdir -p /storage/tempo && \
              minio server /storage
          env:
            - name: MINIO_ACCESS_KEY
              value: tempo
            - name: MINIO_SECRET_KEY
              value: supersecret
          image: quay.io/minio/minio:latest
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
kind: Service
metadata:
  name: minio
  namespace: chainsaw-multitenancy
spec:
  ports:
    - port: 9000
      protocol: TCP
      targetPort: 9000
  selector:
    app.kubernetes.io/name: minio
  type: ClusterIP
---
apiVersion: v1
kind: Secret
metadata:
  name: minio
  namespace: chainsaw-multitenancy
stringData:
  endpoint: http://minio:9000
  bucket: tempo
  access_key_id: tempo
  access_key_secret: supersecret
type: Opaque
EOF

#end of 00

oc apply -f - <<EOF
# based on config/samples/openshift/tempo_v1alpha1_multitenancy.yaml
apiVersion: tempo.grafana.com/v1alpha1
kind:  TempoStack
metadata:
  name: simplest
  namespace: chainsaw-multitenancy
spec:
  storage:
    secret:
      name: minio
      type: s3
  storageSize: 1Gi
  resources:
    total:
      limits:
        memory: 3Gi
        cpu: 2000m
  tenants:
    mode: openshift
    authentication:
      - tenantName: dev
        tenantId: "1610b0c3-c509-4592-a256-a1871353dbfa"
      - tenantName: prod
        tenantId: "1610b0c3-c509-4592-a256-a1871353dbfb"
  template:
    gateway:
      enabled: true
    queryFrontend:
      jaegerQuery:
        enabled: true
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tempostack-traces-reader
rules:
  - apiGroups:
      - 'tempo.grafana.com'
    resources:
      - dev
    resourceNames:
      - traces
    verbs:
      - 'get'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tempostack-traces-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tempostack-traces-reader
subjects:
  - kind: Group
    apiGroup: rbac.authorization.k8s.io
    name: system:authenticated
---
# grant the default serviceaccount in the chainsaw-multitenancy namespace
# access to view resource in chainsaw-multitenancy namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: view
  namespace: chainsaw-multitenancy
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: default
  namespace: chainsaw-multitenancy
EOF

#end of 01

oc apply -f - <<EOF
# based on config/samples/otelcol_v1alpha1_openshift.yaml
---
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: dev
  namespace: chainsaw-multitenancy
spec:
  config: |
    extensions:
      bearertokenauth:
        filename: "/var/run/secrets/kubernetes.io/serviceaccount/token"

    receivers:
      otlp/grpc:
        protocols:
          grpc:
      otlp/http:
        protocols:
          http:

    processors:

    exporters:
      otlp:
        endpoint: tempo-simplest-gateway.chainsaw-multitenancy.svc.cluster.local:8090
        tls:
          insecure: false
          ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt"
        auth:
          authenticator: bearertokenauth
        headers:
          X-Scope-OrgID: "dev"
      otlphttp:
        endpoint: https://tempo-simplest-gateway.chainsaw-multitenancy.svc.cluster.local:8080/api/traces/v1/dev
        tls:
          insecure: false
          ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt"
        auth:
          authenticator: bearertokenauth
        headers:
          X-Scope-OrgID: "dev"

    service:
      telemetry:
        logs:
          level: "DEBUG"
          development: true
          encoding: "json"
      extensions: [bearertokenauth]
      pipelines:
        traces/grpc:
          receivers: [otlp/grpc]
          exporters: [otlp]
        traces/http:
          receivers: [otlp/http]
          exporters: [otlphttp]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tempostack-traces-write
rules:
  - apiGroups:
      - 'tempo.grafana.com'
    # this needs to match tenant name in the CR/tenants.yaml and the tenant has be sent in X-Scope-OrgID
    # The API gateway sends the tenantname as resource (res) to OPA sidecar
    resources:
      - dev
    resourceNames:
      - traces
    verbs:
      - 'create'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tempostack-traces
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tempostack-traces-write
subjects:
  - kind: ServiceAccount
    name: dev-collector
    namespace: chainsaw-multitenancy
EOF

#end of 02

oc apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: generate-traces-grpc
  namespace: chainsaw-multitenancy
spec:
  template:
    spec:
      containers:
      - name: telemetrygen
        image: ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.92.0
        args:
        - traces
        - --otlp-endpoint=dev-collector:4317
        - --service=grpc
        - --otlp-insecure
        - --traces=10
      restartPolicy: Never
---
apiVersion: batch/v1
kind: Job
metadata:
  name: generate-traces-http
  namespace: chainsaw-multitenancy
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
            - --service=http
            - --traces=10
      restartPolicy: Never
EOF

#end of 03
