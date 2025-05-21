#!/bin/bash
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-tracing
EOF

oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app.kubernetes.io/name: minio
  name: minio
  namespace: openshift-tracing
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 30Gi
EOF

oc apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: openshift-tracing
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
          image: quay.io/openshifttest/minio:latest
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
EOF

oc apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: openshift-tracing
spec:
  ports:
    - port: 9000
      protocol: TCP
      targetPort: 9000
  selector:
    app.kubernetes.io/name: minio
  type: ClusterIP
EOF

oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: minio
  namespace: openshift-tracing
stringData:
  endpoint: http://minio.openshift-tracing.svc:9000
  bucket: tempo
  access_key_id: tempo
  access_key_secret: supersecret
type: Opaque
EOF

oc apply -f - <<EOF
apiVersion: tempo.grafana.com/v1alpha1
kind:  TempoStack
metadata:
  name: platform
  namespace: openshift-tracing
spec:
  storage:
    secret:
      name: minio
      type: s3
  storageSize: 20Gi
  resources:
    total:
      limits:
        memory: 12Gi
        cpu: 4 
  tenants:
    mode: openshift
    authentication:
      - tenantName: dev
        tenantId: "1610b0c3-c509-4592-a256-a1871353dbfa"
      - tenantName: platform
        tenantId: "1610b0c3-c509-4592-a256-a1871353dbfb"
  template:
    gateway:
      enabled: true
    queryFrontend:
      jaegerQuery:
        enabled: true
EOF

oc apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tempostack-traces-reader
rules:
  - apiGroups:
      - 'tempo.grafana.com'
    resources:
      - platform
    resourceNames:
      - traces
    verbs:
      - 'get'
EOF

oc apply -f - <<EOF
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
EOF

oc apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: view
  namespace: openshift-tracing
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: default
  namespace: openshift-tracing
EOF

oc apply -f - <<EOF
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: platform
  namespace: openshift-tracing
spec:
  config:
    exporters:
      otlp:
        auth:
          authenticator: bearertokenauth
        endpoint: tempo-platform-gateway.openshift-tracing.svc.cluster.local:8090
        headers:
          X-Scope-OrgID: platform
        tls:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt
          insecure: false
      otlp/platform:
        auth:
          authenticator: bearertokenauth
        endpoint: https://tempo-platform-gateway.openshift-tracing.svc.cluster.local:8080
        headers:
          X-Scope-OrgID: platform
        tls:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt
          insecure: false
    extensions:
      bearertokenauth:
        filename: /var/run/secrets/kubernetes.io/serviceaccount/token
    processors:
      k8sattributes: {}
      k8sattributes/ocplog:
        auth_type: serviceAccount
        extract:
          labels:
          - from: pod
            key: app.kubernetes.io/component
            tag_name: app.label.component
          metadata:
          - k8s.pod.name
          - k8s.pod.uid
          - k8s.deployment.name
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.start_time
        passthrough: false
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: connection
    receivers:
      otlp/grpc:
        protocols:
          grpc: {}
      otlp/http:
        protocols:
          http: {}
    service:
      extensions:
      - bearertokenauth
      pipelines:
        traces/grpc:
          exporters:
          - otlp
          processors:
          - k8sattributes/ocplog
          receivers:
          - otlp/grpc
        traces/http:
          exporters:
          - otlp/platform
          processors:
          - k8sattributes/ocplog
          receivers:
          - otlp/http
      telemetry:
        logs:
          development: true
          encoding: json
          level: DEBUG
EOF

oc apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tempostack-traces-write
rules:
  - apiGroups:
      - 'tempo.grafana.com'
    resources:
      - platform
    resourceNames:
      - traces
    verbs:
      - 'create'
EOF

oc apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: otel-collector-read-k8sattributes
rules:
- apiGroups: [""]
  resources: ["pods", "namespaces", "nodes"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apps"]
  resources: ["replicasets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["extensions"]
  resources: ["replicasets"]
  verbs: ["get", "list", "watch"]
EOF

oc apply -f - <<EOF
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
    name: platform-collector
    namespace: openshift-tracing
EOF

oc apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: otel-collector-processor
roleRef:
  kind: ClusterRole
  name: otel-collector-read-k8sattributes
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: platform-collector
  namespace: openshift-tracing
EOF

oc apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: generate-traces-grpc
  namespace: openshift-tracing
spec:
  template:
    spec:
      containers:
      - name: telemetrygen
        image: ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.92.0
        args:
        - traces
        - --otlp-endpoint=platform-collector:4317
        - --service=grpc
        - --otlp-insecure
        - --traces=20
      restartPolicy: Never
EOF

oc apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: generate-traces-http
  namespace: openshift-tracing
spec:
  template:
    spec:
      containers:
        - name: telemetrygen
          image: ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.92.0
          args:
            - traces
            - --otlp-endpoint=platform-collector:4318
            - --otlp-http
            - --otlp-insecure
            - --service=http
            - --traces=20
      restartPolicy: Never
EOF

oc apply -f - <<EOF
apiVersion: project.openshift.io/v1
kind: Project
metadata:
  name: tracing-app-hotrod
EOF

oc apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: hotrod
  name: hotrod
  namespace: tracing-app-hotrod
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: hotrod
  template:
    metadata:
      labels:
        app.kubernetes.io/name: hotrod
    spec:
      containers:
      - image: jaegertracing/example-hotrod:1.46
        name: hotrod
        args:
        - all
        - --otel-exporter=otlp
        env:
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: http://platform-collector.openshift-tracing:4318
        ports:
        - containerPort: 8080
          name: frontend
        - containerPort: 8081
          name: customer
        - containerPort: 8083
          name: route
        resources:
          limits:
            cpu: 100m
            memory: 100M
          requests:
            cpu: 100m
            memory: 100M
EOF

oc apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: hotrod
  namespace: tracing-app-hotrod
spec:
  selector:
    app.kubernetes.io/name: hotrod
  ports:
  - name: frontend
    port: 8080
    targetPort: frontend
EOF

oc apply -f - <<EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: hotrod
  namespace: tracing-app-hotrod
spec:
  to:
    kind: Service
    name: hotrod
EOF

oc apply -f - <<EOF
apiVersion: project.openshift.io/v1
kind: Project
metadata:
  name: tracing-app-k6
EOF

oc apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: k6-tracing
  name: k6-tracing
  namespace: tracing-app-k6
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: k6-tracing
  template:
    metadata:
      labels:
        app.kubernetes.io/name: k6-tracing
    spec:
      containers:
      - name: k6-tracing
        image: ghcr.io/grafana/xk6-client-tracing:v0.0.5
        env:
        - name: ENDPOINT
          value: platform-collector.openshift-tracing:4317
EOF

oc apply -f - <<EOF
apiVersion: project.openshift.io/v1
kind: Project
metadata:
  name: tracing-app-telemetrygen
EOF

oc apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: telemetrygen
  name: telemetrygen
  namespace: tracing-app-telemetrygen
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: telemetrygen
  template:
    metadata:
      labels:
        app.kubernetes.io/name: telemetrygen
    spec:
      # in total 5 spans per second are generated, with 2/5 (40%) containing an error
      containers:
      # this generates 3 spans per second
      - name: telemetrygen1
        image: ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.105.0
        args:
          - traces
          - --otlp-endpoint=platform-collector.openshift-tracing:4317
          - --otlp-insecure
          - --duration=1h
          - --service=good_service
          - --rate=3 # spans per second
          - --child-spans=2
      # this generates 2 spans per second with an error status
      - name: telemetrygen2
        image: ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.105.0
        args:
          - traces
          - --otlp-endpoint=platform-collector.openshift-tracing:4317
          - --otlp-insecure
          - --duration=1h
          - --service=faulty_service
          - --rate=2 # spans per second
          - --child-spans=1
          - --status-code=Error
EOF

oc apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: k6-tracing
  name: k6-tracing
  namespace: tracing-app-k6
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: k6-tracing
  template:
    metadata:
      labels:
        app.kubernetes.io/name: k6-tracing
    spec:
      containers:
      - name: k6-tracing
        image: ghcr.io/grafana/xk6-client-tracing:v0.0.5
        env:
        - name: ENDPOINT
          value: platform-collector.openshift-tracing:4317
EOF

oc apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: telemetrygen
  name: telemetrygen
  namespace: tracing-app-telemetrygen
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: telemetrygen
  template:
    metadata:
      labels:
        app.kubernetes.io/name: telemetrygen
    spec:
      # in total 5 spans per second are generated, with 2/5 (40%) containing an error
      containers:
      # this generates 3 spans per second
      - name: telemetrygen1
        image: ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.105.0
        args:
          - traces
          - --otlp-endpoint=platform-collector.openshift-tracing:4317
          - --otlp-insecure
          - --duration=1h
          - --service=good_service
          - --rate=3 # spans per second
          - --child-spans=2
      # this generates 2 spans per second with an error status
      - name: telemetrygen2
        image: ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.105.0
        args:
          - traces
          - --otlp-endpoint=platform-collector.openshift-tracing:4317
          - --otlp-insecure
          - --duration=1h
          - --service=faulty_service
          - --rate=2 # spans per second
          - --child-spans=1
          - --status-code=Error
EOF
