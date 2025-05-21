#!/bin/bash

oc apply -f - <<EOF
apiVersion: loki.grafana.com/v1
kind: LokiStack
metadata:
  name: loki
  namespace: openshift-netobserv-operator
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
    mode: openshift-network
EOF

echo "wait 2 minutes unitl loki is ready"
for i in `seq 1 4`; do
    	if oc get pods loki-ingester-0 -n openshift-netobserv-operator |grep Running; then
	        echo "lokistack is ready"
		break
	fi
	sleep 30
done

echo "#Create FlowCollector"
cat <<EOF |oc apply -f -
apiVersion: flows.netobserv.io/v1beta2
kind: FlowCollector
metadata:
  annotations:
    flows.netobserv.io/flowcollectorlegacy-namespace: openshift-netobserv-operator
    flows.netobserv.io/flpparent-namespace: openshift-netobserv-operator
  name: cluster
spec:
  agent:
    ebpf:
      cacheActiveTimeout: 5s
      cacheMaxFlows: 100000
      excludeInterfaces:
      - lo
      imagePullPolicy: IfNotPresent
      kafkaBatchSize: 1048576
      logLevel: info
      metrics:
        server:
          tls:
            insecureSkipVerify: false
            type: Disabled
      resources:
        limits:
          memory: 800Mi
        requests:
          cpu: 100m
          memory: 50Mi
      sampling: 50
    ipfix:
      cacheActiveTimeout: 20s
      cacheMaxFlows: 400
      clusterNetworkOperator:
        namespace: openshift-network-operator
      forceSampleAll: false
      ovnKubernetes:
        containerName: ovnkube-node
        daemonSetName: ovnkube-node
        namespace: ovn-kubernetes
      sampling: 400
    type: eBPF
  consolePlugin:
    advanced:
      port: 9001
      register: true
    autoscaler:
      maxReplicas: 3
      status: Disabled
    enable: true
    imagePullPolicy: IfNotPresent
    logLevel: info
    portNaming:
      enable: true
    quickFilters:
    - default: true
      filter:
        flow_layer: '"app"'
      name: Applications
    - filter:
        flow_layer: '"infra"'
      name: Infrastructure
    - default: true
      filter:
        dst_kind: '"Pod"'
        src_kind: '"Pod"'
      name: Pods network
    - filter:
        dst_kind: '"Service"'
      name: Services network
    replicas: 1
    resources:
      limits:
        memory: 100Mi
      requests:
        cpu: 100m
        memory: 50Mi
  deploymentModel: Direct
  kafka:
    address: ""
    sasl:
      clientIDReference:
        namespace: ""
      clientSecretReference:
        namespace: ""
      type: Disabled
    tls:
      caCert:
        namespace: ""
      enable: false
      insecureSkipVerify: false
      userCert:
        namespace: ""
    topic: ""
  loki:
    advanced:
      staticLabels:
        app: netobserv-flowcollector
      writeMaxBackoff: 5s
      writeMaxRetries: 2
      writeMinBackoff: 1s
    enable: true
    lokiStack:
      name: loki
      namespace: openshift-netobserv-operator
    manual:
      authToken: Disabled
      ingesterUrl: http://loki:3100/
      querierUrl: http://loki:3100/
      statusTls:
        caCert:
          namespace: ""
        enable: false
        insecureSkipVerify: false
        userCert:
          namespace: ""
      tenantID: netobserv
      tls:
        caCert:
          namespace: ""
        enable: false
        insecureSkipVerify: false
        userCert:
          namespace: ""
    microservices:
      ingesterUrl: http://loki-distributor:3100/
      querierUrl: http://loki-query-frontend:3100/
      tenantID: netobserv
      tls:
        caCert:
          namespace: ""
        enable: false
        insecureSkipVerify: false
        userCert:
          namespace: ""
    mode: LokiStack
    monolithic:
      tenantID: netobserv
      tls:
        caCert:
          namespace: ""
        enable: false
        insecureSkipVerify: false
        userCert:
          namespace: ""
      url: http://loki:3100/
    readTimeout: 30s
    writeBatchSize: 102400
    writeBatchWait: 1s
    writeTimeout: 10s
  namespace: netobserv
  processor:
    advanced:
      conversationEndTimeout: 10s
      conversationHeartbeatInterval: 30s
      conversationTerminatingTimeout: 5s
      dropUnusedFields: true
      enableKubeProbes: true
      healthPort: 8080
      port: 2055
      profilePort: 6060
    clusterName: ""
    imagePullPolicy: IfNotPresent
    kafkaConsumerAutoscaler:
      maxReplicas: 3
      status: Disabled
    kafkaConsumerBatchSize: 10485760
    kafkaConsumerQueueCapacity: 1000
    kafkaConsumerReplicas: 3
    logLevel: info
    logTypes: Flows
    metrics:
      server:
        tls:
          insecureSkipVerify: false
          type: Disabled
    multiClusterDeployment: false
    resources:
      limits:
        memory: 800Mi
      requests:
        cpu: 100m
        memory: 100Mi
    subnetLabels: {}
  prometheus:
    querier:
      manual:
        forwardUserToken: false
        tls:
          caCert:
            namespace: ""
          enable: false
          insecureSkipVerify: false
          userCert:
            namespace: ""
        url: http://prometheus:9090
      mode: Auto
      timeout: 30s
EOF