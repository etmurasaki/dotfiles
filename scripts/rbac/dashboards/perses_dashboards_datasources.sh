#!/bin/bash

oc apply -f - <<EOF
apiVersion: perses.dev/v1alpha1
kind: PersesDashboard
metadata:
  name: openshift-cluster-sample-dashboard
  namespace: perses-dev
spec:
  display:
    name: Kubernetes / Compute Resources / Cluster
  variables:
    - kind: ListVariable
      spec:
        display:
          hidden: false
        allowAllValue: false
        allowMultiple: false
        sort: alphabetical-asc
        plugin:
          kind: PrometheusLabelValuesVariable
          spec:
            labelName: cluster
            matchers:
              - up{job="kubelet", metrics_path="/metrics/cadvisor"}
        name: cluster
  panels:
    "0_0":
      kind: Panel
      spec:
        display:
          name: CPU Utilisation
        plugin:
          kind: StatChart
          spec:
            calculation: mean
            format:
              unit: percent-decimal
            thresholds:
              steps:
                - color: green
                  value: 0
                - color: red
                  value: 80
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: cluster:node_cpu:ratio_rate5m{cluster="$cluster"}
    "0_1":
      kind: Panel
      spec:
        display:
          name: CPU Requests Commitment
        plugin:
          kind: StatChart
          spec:
            calculation: mean
            format:
              unit: percent-decimal
            thresholds:
              steps:
                - color: green
                  value: 0
                - color: red
                  value: 80
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(namespace_cpu:kube_pod_container_resource_requests:sum{cluster="$cluster"}) / sum(kube_node_status_allocatable{job="kube-state-metrics",resource="cpu",cluster="$cluster"})
    "0_2":
      kind: Panel
      spec:
        display:
          name: CPU Limits Commitment
        plugin:
          kind: StatChart
          spec:
            calculation: mean
            format:
              unit: percent-decimal
            thresholds:
              steps:
                - color: green
                  value: 0
                - color: red
                  value: 80
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(namespace_cpu:kube_pod_container_resource_limits:sum{cluster="$cluster"}) / sum(kube_node_status_allocatable{job="kube-state-metrics",resource="cpu",cluster="$cluster"})
    "0_3":
      kind: Panel
      spec:
        display:
          name: Memory Utilisation
        plugin:
          kind: StatChart
          spec:
            calculation: mean
            format:
              unit: percent-decimal
            thresholds:
              steps:
                - color: green
                  value: 0
                - color: red
                  value: 80
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: 1 - sum(:node_memory_MemAvailable_bytes:sum{cluster="$cluster"}) / sum(node_memory_MemTotal_bytes{job="node-exporter",cluster="$cluster"})
    "0_4":
      kind: Panel
      spec:
        display:
          name: Memory Requests Commitment
        plugin:
          kind: StatChart
          spec:
            calculation: mean
            format:
              unit: percent-decimal
            thresholds:
              steps:
                - color: green
                  value: 0
                - color: red
                  value: 80
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(namespace_memory:kube_pod_container_resource_requests:sum{cluster="$cluster"}) / sum(kube_node_status_allocatable{job="kube-state-metrics",resource="memory",cluster="$cluster"})
    "0_5":
      kind: Panel
      spec:
        display:
          name: Memory Limits Commitment
        plugin:
          kind: StatChart
          spec:
            calculation: mean
            format:
              unit: percent-decimal
            thresholds:
              steps:
                - color: green
                  value: 0
                - color: red
                  value: 80
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(namespace_memory:kube_pod_container_resource_limits:sum{cluster="$cluster"}) / sum(kube_node_status_allocatable{job="kube-state-metrics",resource="memory",cluster="$cluster"})
    "1_0":
      kind: Panel
      spec:
        display:
          name: CPU Usage
        plugin:
          kind: TimeSeriesChart
          spec:
            legend:
              mode: list
              position: bottom
              values: []
            visual:
              areaOpacity: 1
              connectNulls: false
              display: line
              lineWidth: 0.25
              stack: all
            yAxis:
              format:
                unit: decimal
              min: 0
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster="$cluster"}) by (namespace)
                  seriesNameFormat: "{{namespace}}"
    "2_0":
      kind: Panel
      spec:
        display:
          name: CPU Quota
        plugin:
          kind: Table
          spec:
            columnSettings:
              - header: Time
                hide: true
                name: Time
              - header: Pods
                name: "Value #A"
              - header: Workloads
                name: "Value #B"
              - header: CPU Usage
                name: "Value #C"
              - header: CPU Requests
                name: "Value #D"
              - header: CPU Requests %
                name: "Value #E"
              - header: CPU Limits
                name: "Value #F"
              - header: CPU Limits %
                name: "Value #G"
              - header: Namespace
                name: namespace
              - header: ""
                name: /.*/
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(kube_pod_owner{job="kube-state-metrics", cluster="$cluster"}) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: count(avg(namespace_workload_pod:kube_pod_owner:relabel{cluster="$cluster"}) by (workload, namespace)) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster="$cluster"}) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(namespace_cpu:kube_pod_container_resource_requests:sum{cluster="$cluster"}) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster="$cluster"}) by (namespace) / sum(namespace_cpu:kube_pod_container_resource_requests:sum{cluster="$cluster"}) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(namespace_cpu:kube_pod_container_resource_limits:sum{cluster="$cluster"}) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster="$cluster"}) by (namespace) / sum(namespace_cpu:kube_pod_container_resource_limits:sum{cluster="$cluster"}) by (namespace)
                  seriesNameFormat: ""
    "3_0":
      kind: Panel
      spec:
        display:
          name: Memory Usage (w/o cache)
        plugin:
          kind: TimeSeriesChart
          spec:
            legend:
              mode: list
              position: bottom
              values: []
            visual:
              areaOpacity: 1
              connectNulls: false
              display: line
              lineWidth: 0.25
              stack: all
            yAxis:
              format:
                unit: bytes
              min: 0
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(container_memory_rss{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", container!=""}) by (namespace)
                  seriesNameFormat: "{{namespace}}"
    "4_0":
      kind: Panel
      spec:
        display:
          name: Requests by Namespace
        plugin:
          kind: Table
          spec:
            columnSettings:
              - header: Time
                hide: true
                name: Time
              - header: Pods
                name: "Value #A"
              - header: Workloads
                name: "Value #B"
              - header: Memory Usage
                name: "Value #C"
              - header: Memory Requests
                name: "Value #D"
              - header: Memory Requests %
                name: "Value #E"
              - header: Memory Limits
                name: "Value #F"
              - header: Memory Limits %
                name: "Value #G"
              - header: Namespace
                name: namespace
              - header: ""
                name: /.*/
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(kube_pod_owner{job="kube-state-metrics", cluster="$cluster"}) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: count(avg(namespace_workload_pod:kube_pod_owner:relabel{cluster="$cluster"}) by (workload, namespace)) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(container_memory_rss{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", container!=""}) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(namespace_memory:kube_pod_container_resource_requests:sum{cluster="$cluster"}) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(container_memory_rss{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", container!=""}) by (namespace) / sum(namespace_memory:kube_pod_container_resource_requests:sum{cluster="$cluster"}) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(namespace_memory:kube_pod_container_resource_limits:sum{cluster="$cluster"}) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(container_memory_rss{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", container!=""}) by (namespace) / sum(namespace_memory:kube_pod_container_resource_limits:sum{cluster="$cluster"}) by (namespace)
                  seriesNameFormat: ""
    "5_0":
      kind: Panel
      spec:
        display:
          name: Current Network Usage
        plugin:
          kind: Table
          spec:
            columnSettings:
              - header: Time
                hide: true
                name: Time
              - header: Current Receive Bandwidth
                name: "Value #A"
              - header: Current Transmit Bandwidth
                name: "Value #B"
              - header: Rate of Received Packets
                name: "Value #C"
              - header: Rate of Transmitted Packets
                name: "Value #D"
              - header: Rate of Received Packets Dropped
                name: "Value #E"
              - header: Rate of Transmitted Packets Dropped
                name: "Value #F"
              - header: Namespace
                name: namespace
              - header: ""
                name: /.*/
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(irate(container_network_receive_bytes_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(irate(container_network_transmit_bytes_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(irate(container_network_receive_packets_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(irate(container_network_transmit_packets_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(irate(container_network_receive_packets_dropped_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(irate(container_network_transmit_packets_dropped_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: ""
    "6_0":
      kind: Panel
      spec:
        display:
          name: Receive Bandwidth
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(irate(container_network_receive_bytes_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: "{{namespace}}"
    "6_1":
      kind: Panel
      spec:
        display:
          name: Transmit Bandwidth
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(irate(container_network_transmit_bytes_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: "{{namespace}}"
    "7_0":
      kind: Panel
      spec:
        display:
          name: "Average Container Bandwidth by Namespace: Received"
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: avg(irate(container_network_receive_bytes_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: "{{namespace}}"
    "7_1":
      kind: Panel
      spec:
        display:
          name: "Average Container Bandwidth by Namespace: Transmitted"
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: avg(irate(container_network_transmit_bytes_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: "{{namespace}}"
    "8_0":
      kind: Panel
      spec:
        display:
          name: Rate of Received Packets
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(irate(container_network_receive_packets_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: "{{namespace}}"
    "8_1":
      kind: Panel
      spec:
        display:
          name: Rate of Transmitted Packets
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(irate(container_network_transmit_packets_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: "{{namespace}}"
    "9_0":
      kind: Panel
      spec:
        display:
          name: Rate of Received Packets Dropped
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(irate(container_network_receive_packets_dropped_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: "{{namespace}}"
    "9_1":
      kind: Panel
      spec:
        display:
          name: Rate of Transmitted Packets Dropped
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum(irate(container_network_transmit_packets_dropped_total{job="kubelet", metrics_path="/metrics/cadvisor", cluster="$cluster", namespace=~".+"}[$__rate_interval])) by (namespace)
                  seriesNameFormat: "{{namespace}}"
    "10_0":
      kind: Panel
      spec:
        display:
          name: IOPS(Reads+Writes)
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: ceil(sum by(namespace) (rate(container_fs_reads_total{job="kubelet", metrics_path="/metrics/cadvisor", id!="", device=~"(/dev.+)|mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+", cluster="$cluster", namespace!=""}[$__rate_interval]) + rate(container_fs_writes_total{job="kubelet", metrics_path="/metrics/cadvisor", id!="", cluster="$cluster", namespace!=""}[$__rate_interval])))
                  seriesNameFormat: "{{namespace}}"
    "10_1":
      kind: Panel
      spec:
        display:
          name: ThroughPut(Read+Write)
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum by(namespace) (rate(container_fs_reads_bytes_total{job="kubelet", metrics_path="/metrics/cadvisor", id!="", device=~"(/dev.+)|mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+", cluster="$cluster", namespace!=""}[$__rate_interval]) + rate(container_fs_writes_bytes_total{job="kubelet", metrics_path="/metrics/cadvisor", id!="", cluster="$cluster", namespace!=""}[$__rate_interval]))
                  seriesNameFormat: "{{namespace}}"
    "11_0":
      kind: Panel
      spec:
        display:
          name: Current Storage IO
        plugin:
          kind: Table
          spec:
            columnSettings:
              - header: Time
                hide: true
                name: Time
              - header: IOPS(Reads)
                name: "Value #A"
              - header: IOPS(Writes)
                name: "Value #B"
              - header: IOPS(Reads + Writes)
                name: "Value #C"
              - header: Throughput(Read)
                name: "Value #D"
              - header: Throughput(Write)
                name: "Value #E"
              - header: Throughput(Read + Write)
                name: "Value #F"
              - header: Namespace
                name: namespace
              - header: ""
                name: /.*/
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum by(namespace) (rate(container_fs_reads_total{job="kubelet", metrics_path="/metrics/cadvisor", device=~"(/dev.+)|mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+", id!="", cluster="$cluster", namespace!=""}[$__rate_interval]))
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum by(namespace) (rate(container_fs_writes_total{job="kubelet", metrics_path="/metrics/cadvisor", device=~"(/dev.+)|mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+", id!="", cluster="$cluster", namespace!=""}[$__rate_interval]))
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum by(namespace) (rate(container_fs_reads_total{job="kubelet", metrics_path="/metrics/cadvisor", device=~"(/dev.+)|mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+", id!="", cluster="$cluster", namespace!=""}[$__rate_interval]) + rate(container_fs_writes_total{job="kubelet", metrics_path="/metrics/cadvisor", device=~"(/dev.+)|mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+", id!="", cluster="$cluster", namespace!=""}[$__rate_interval]))
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum by(namespace) (rate(container_fs_reads_bytes_total{job="kubelet", metrics_path="/metrics/cadvisor", device=~"(/dev.+)|mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+", id!="", cluster="$cluster", namespace!=""}[$__rate_interval]))
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum by(namespace) (rate(container_fs_writes_bytes_total{job="kubelet", metrics_path="/metrics/cadvisor", device=~"(/dev.+)|mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+", id!="", cluster="$cluster", namespace!=""}[$__rate_interval]))
                  seriesNameFormat: ""
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource

                  query: sum by(namespace) (rate(container_fs_reads_bytes_total{job="kubelet", metrics_path="/metrics/cadvisor", device=~"(/dev.+)|mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+", id!="", cluster="$cluster", namespace!=""}[$__rate_interval]) + rate(container_fs_writes_bytes_total{job="kubelet", metrics_path="/metrics/cadvisor", device=~"(/dev.+)|mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+", id!="", cluster="$cluster", namespace!=""}[$__rate_interval]))
                  seriesNameFormat: ""
  layouts:
    - kind: Grid
      spec:
        display:
          title: Headlines
          collapse:
            open: true
        items:
          - x: 0
            "y": 1
            width: 4
            height: 3
            content:
              $ref: "#/spec/panels/0_0"
          - x: 4
            "y": 1
            width: 4
            height: 3
            content:
              $ref: "#/spec/panels/0_1"
          - x: 8
            "y": 1
            width: 4
            height: 3
            content:
              $ref: "#/spec/panels/0_2"
          - x: 12
            "y": 1
            width: 4
            height: 3
            content:
              $ref: "#/spec/panels/0_3"
          - x: 16
            "y": 1
            width: 4
            height: 3
            content:
              $ref: "#/spec/panels/0_4"
          - x: 20
            "y": 1
            width: 4
            height: 3
            content:
              $ref: "#/spec/panels/0_5"
    - kind: Grid
      spec:
        display:
          title: CPU
          collapse:
            open: true
        items:
          - x: 0
            "y": 5
            width: 24
            height: 7
            content:
              $ref: "#/spec/panels/1_0"
    - kind: Grid
      spec:
        display:
          title: CPU Quota
          collapse:
            open: true
        items:
          - x: 0
            "y": 13
            width: 24
            height: 7
            content:
              $ref: "#/spec/panels/2_0"
    - kind: Grid
      spec:
        display:
          title: Memory
          collapse:
            open: true
        items:
          - x: 0
            "y": 21
            width: 24
            height: 7
            content:
              $ref: "#/spec/panels/3_0"
    - kind: Grid
      spec:
        display:
          title: Memory Requests
          collapse:
            open: true
        items:
          - x: 0
            "y": 29
            width: 24
            height: 7
            content:
              $ref: "#/spec/panels/4_0"
    - kind: Grid
      spec:
        display:
          title: Current Network Usage
          collapse:
            open: true
        items:
          - x: 0
            "y": 37
            width: 24
            height: 7
            content:
              $ref: "#/spec/panels/5_0"
    - kind: Grid
      spec:
        display:
          title: Bandwidth
          collapse:
            open: true
        items:
          - x: 0
            "y": 45
            width: 12
            height: 7
            content:
              $ref: "#/spec/panels/6_0"
          - x: 12
            "y": 45
            width: 12
            height: 7
            content:
              $ref: "#/spec/panels/6_1"
    - kind: Grid
      spec:
        display:
          title: Average Container Bandwidth by Namespace
          collapse:
            open: true
        items:
          - x: 0
            "y": 53
            width: 12
            height: 7
            content:
              $ref: "#/spec/panels/7_0"
          - x: 12
            "y": 53
            width: 12
            height: 7
            content:
              $ref: "#/spec/panels/7_1"
    - kind: Grid
      spec:
        display:
          title: Rate of Packets
          collapse:
            open: true
        items:
          - x: 0
            "y": 61
            width: 12
            height: 7
            content:
              $ref: "#/spec/panels/8_0"
          - x: 12
            "y": 61
            width: 12
            height: 7
            content:
              $ref: "#/spec/panels/8_1"
    - kind: Grid
      spec:
        display:
          title: Rate of Packets Dropped
          collapse:
            open: true
        items:
          - x: 0
            "y": 69
            width: 12
            height: 7
            content:
              $ref: "#/spec/panels/9_0"
          - x: 12
            "y": 69
            width: 12
            height: 7
            content:
              $ref: "#/spec/panels/9_1"
    - kind: Grid
      spec:
        display:
          title: Storage IO
          collapse:
            open: true
        items:
          - x: 0
            "y": 77
            width: 12
            height: 7
            content:
              $ref: "#/spec/panels/10_0"
          - x: 12
            "y": 77
            width: 12
            height: 7
            content:
              $ref: "#/spec/panels/10_1"
    - kind: Grid
      spec:
        display:
          title: Storage IO - Distribution
          collapse:
            open: true
        items:
          - x: 0
            "y": 85
            width: 24
            height: 7
            content:
              $ref: "#/spec/panels/11_0"
  duration: 1h
EOF

oc apply -f - <<EOF
apiVersion: perses.dev/v1alpha1
kind: PersesDashboard
metadata:
  name: perses-dashboard-sample
  namespace: perses-dev
spec:
  display:
    name: Perses Dashboard Sample
    description: This is a sample dashboard
  duration: 5m
  datasources:
    PrometheusLocal:
      default: false
      plugin:
        kind: PrometheusDatasource
        spec:
          proxy:
            kind: HTTPProxy
            spec:
              url: http://localhost:9090
  variables:
    - kind: ListVariable
      spec:
        name: job
        allowMultiple: false
        allowAllValue: false
        plugin:
          kind: PrometheusLabelValuesVariable
          spec:
            labelName: job
    - kind: ListVariable
      spec:
        name: instance
        allowMultiple: false
        allowAllValue: false
        plugin:
          kind: PrometheusLabelValuesVariable
          spec:
            labelName: instance
            matchers:
              - up{job=~"$job"}
    - kind: ListVariable
      spec:
        name: interval
        plugin:
          kind: StaticListVariable
          spec:
            values:
              - 1m
              - 5m
    - kind: TextVariable
      spec:
        name: text
        value: test
        constant: true
  panels:
    defaultTimeSeriesChart:
      kind: Panel
      spec:
        display:
          name: Default Time Series Panel
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: up
    seriesTest:
      kind: Panel
      spec:
        display:
          name: '~130 Series'
          description: This is a line chart
        plugin:
          kind: TimeSeriesChart
          spec:
            yAxis:
              format:
                unit: bytes
                shortValues: true
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: rate(caddy_http_response_duration_seconds_sum[$interval])
    basicEx:
      kind: Panel
      spec:
        display:
          name: Single Query
        plugin:
          kind: TimeSeriesChart
          spec:
            yAxis:
              format:
                unit: decimal
            legend:
              position: right
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  seriesNameFormat: Node memory - {{device}} {{instance}}
                  query:
                    1 - node_filesystem_free_bytes{job='$job',instance=~'$instance',fstype!="rootfs",mountpoint!~"/(run|var).*",mountpoint!=""}
                    / node_filesystem_size_bytes{job='$job',instance=~'$instance'}
    legendEx:
      kind: Panel
      spec:
        display:
          name: Legend Example
        plugin:
          kind: TimeSeriesChart
          spec:
            legend:
              position: bottom
            yAxis:
              show: true
              format:
                unit: bytes
                shortValues: true
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  seriesNameFormat: Node memory total
                  query:
                    node_memory_MemTotal_bytes{job='$job',instance=~'$instance'}
                    - node_memory_MemFree_bytes{job='$job',instance=~'$instance'} -
                    node_memory_Buffers_bytes{job='$job',instance=~'$instance'} - node_memory_Cached_bytes{job='$job',instance=~'$instance'}
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  seriesNameFormat: Memory (buffers) - {{instance}}
                  query: node_memory_Buffers_bytes{job='$job',instance=~'$instance'}
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  seriesNameFormat: Cached Bytes
                  query: node_memory_Cached_bytes{job='$job',instance=~'$instance'}
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  seriesNameFormat: MemFree Bytes
                  query: node_memory_MemFree_bytes{job='$job',instance=~'$instance'}
    testNodeQuery:
      kind: Panel
      spec:
        display:
          name: Test Query
          description: Description text
        plugin:
          kind: TimeSeriesChart
          spec:
            yAxis:
              format:
                unit: decimal
                decimalPlaces: 2
            legend:
              position: right
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: node_load15{instance=~"(demo.do.prometheus.io:9100)",job='$job'}
                  seriesNameFormat: Test {{job}} {{instance}}
    testQueryAlt:
      kind: Panel
      spec:
        display:
          name: Test Query Alt
          description: Description text
        plugin:
          kind: TimeSeriesChart
          spec:
            legend:
              position: right
            yAxis:
              format:
                unit: percent-decimal
                decimalPlaces: 1
            thresholds:
              steps:
                - value: 0.4
                  name: 'Alert: Warning condition example'
                - value: 0.75
                  name: 'Alert: Critical condition example'
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: node_load1{instance=~"(demo.do.prometheus.io:9100)",job='$job'}
    cpuLine:
      kind: Panel
      spec:
        display:
          name: CPU - Line (Multi Series)
          description: This is a line chart test
        plugin:
          kind: TimeSeriesChart
          spec:
            yAxis:
              show: false
              label: CPU Label
              format:
                unit: percent-decimal
                decimalPlaces: 0
            legend:
              position: bottom
            thresholds:
              steps:
                - value: 0.2
                - value: 0.35
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  seriesNameFormat: '{{mode}} mode - {{job}} {{instance}}'
                  query: avg without (cpu)(rate(node_cpu_seconds_total{job='$job',instance=~'$instance',mode!="nice",mode!="steal",mode!="irq"}[$interval]))
    cpuGauge:
      kind: Panel
      spec:
        display:
          name: CPU - Gauge (Multi Series)
          description: This is a gauge chart test
        plugin:
          kind: GaugeChart
          spec:
            calculation: last-number
            format:
              unit: percent-decimal
            thresholds:
              steps:
                - value: 0.2
                - value: 0.35
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  seriesNameFormat: '{{mode}} mode - {{job}} {{instance}}'
                  query: avg without (cpu)(rate(node_cpu_seconds_total{job='$job',instance=~'$instance',mode!="nice",mode!="steal",mode!="irq"}[$interval]))
    statSm:
      kind: Panel
      spec:
        display:
          name: Stat Sm
        plugin:
          kind: StatChart
          spec:
            calculation: mean
            format:
              unit: decimal
              decimalPlaces: 1
              shortValues: true
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: node_time_seconds{job='$job',instance=~'$instance'} - node_boot_time_seconds{job='$job',instance=~'$instance'}
    gaugeRAM:
      kind: Panel
      spec:
        display:
          name: RAM Used
          description: This is a stat chart
        plugin:
          kind: GaugeChart
          spec:
            calculation: last-number
            format:
              unit: percent
            thresholds:
              steps:
                - value: 85
                - value: 95
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query:
                    100 - ((node_memory_MemAvailable_bytes{job='$job',instance=~'$instance'}
                    * 100) / node_memory_MemTotal_bytes{job='$job',instance=~'$instance'})
    statRAM:
      kind: Panel
      spec:
        display:
          name: RAM Used
          description: This is a stat chart
        plugin:
          kind: StatChart
          spec:
            calculation: last-number
            format:
              unit: percent
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query:
                    100 - ((node_memory_MemAvailable_bytes{job='$job',instance=~'$instance'}
                    * 100) / node_memory_MemTotal_bytes{job='$job',instance=~'$instance'})
    statTotalRAM:
      kind: Panel
      spec:
        display:
          name: RAM Total
          description: This is a stat chart
        plugin:
          kind: StatChart
          spec:
            calculation: last-number
            format:
              unit: bytes
              decimalPlaces: 1
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: node_memory_MemTotal_bytes{job='$job',instance=~'$instance'}
    statMd:
      kind: Panel
      spec:
        display:
          name: Stat Md
        plugin:
          kind: StatChart
          spec:
            calculation: sum
            format:
              unit: decimal
              decimalPlaces: 2
              shortValues: true
            sparkline:
              color: '#e65013'
              width: 1.5
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query:
                    avg(node_load15{job='node',instance=~'$instance'}) /  count(count(node_cpu_seconds_total{job='node',instance=~'$instance'})
                    by (cpu)) * 100
    statLg:
      kind: Panel
      spec:
        display:
          name: Stat Lg
          description: This is a stat chart
        plugin:
          kind: StatChart
          spec:
            calculation: mean
            format:
              unit: percent
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query:
                    (((count(count(node_cpu_seconds_total{job='$job',instance=~'$instance'})
                    by (cpu))) - avg(sum by (mode)(rate(node_cpu_seconds_total{mode="idle",job='$job',instance=~'$instance'}[$interval]))))
                    * 100) / count(count(node_cpu_seconds_total{job='$job',instance=~'$instance'})
                    by (cpu))
    gaugeEx:
      kind: Panel
      spec:
        display:
          name: Gauge Ex
          description: This is a gauge chart
        plugin:
          kind: GaugeChart
          spec:
            calculation: last-number
            format:
              unit: percent
            thresholds:
              steps:
                - value: 85
                - value: 95
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query:
                    (((count(count(node_cpu_seconds_total{job='$job',instance=~'$instance'})
                    by (cpu))) - avg(sum by (mode)(rate(node_cpu_seconds_total{mode="idle",job='$job',instance=~'$instance'}[$interval]))))
                    * 100) / count(count(node_cpu_seconds_total{job='$job',instance=~'$instance'})
                    by (cpu))
    gaugeAltEx:
      kind: Panel
      spec:
        display:
          name: Gauge Alt Ex
          description: GaugeChart description text
        plugin:
          kind: GaugeChart
          spec:
            calculation: last-number
            format:
              unit: percent-decimal
              decimalPlaces: 1
            thresholds:
              steps:
                - value: 0.5
                  name: 'Alert: Warning condition example'
                - value: 0.75
                  name: 'Alert: Critical condition example'
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: node_load15{instance=~'$instance',job='$job'}
    gaugeFormatTest:
      kind: Panel
      spec:
        display:
          name: Gauge Format Test
        plugin:
          kind: GaugeChart
          spec:
            calculation: last-number
            format:
              unit: bytes
            max: 95000000
            thresholds:
              steps:
                - value: 71000000
                - value: 82000000
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: node_time_seconds{job='$job',instance=~'$instance'} - node_boot_time_seconds{job='$job',instance=~'$instance'}
  layouts:
    - kind: Grid
      spec:
        display:
          title: Row 1
          collapse:
            open: true
        items:
          - x: 0
            'y': 0
            width: 2
            height: 3
            content:
              '$ref': '#/spec/panels/statRAM'
          - x: 0
            'y': 4
            width: 2
            height: 3
            content:
              '$ref': '#/spec/panels/statTotalRAM'
          - x: 2
            'y': 0
            width: 4
            height: 6
            content:
              '$ref': '#/spec/panels/statMd'
          - x: 6
            'y': 0
            width: 10
            height: 6
            content:
              '$ref': '#/spec/panels/statLg'
          - x: 16
            'y': 0
            width: 4
            height: 6
            content:
              '$ref': '#/spec/panels/gaugeFormatTest'
          - x: 20
            'y': 0
            width: 4
            height: 6
            content:
              '$ref': '#/spec/panels/gaugeRAM'
    - kind: Grid
      spec:
        display:
          title: Row 2
          collapse:
            open: true
        items:
          - x: 0
            'y': 0
            width: 12
            height: 6
            content:
              '$ref': '#/spec/panels/legendEx'
          - x: 12
            'y': 0
            width: 12
            height: 6
            content:
              '$ref': '#/spec/panels/basicEx'
    - kind: Grid
      spec:
        display:
          title: Row 3
          collapse:
            open: false
        items:
          - x: 0
            'y': 0
            width: 24
            height: 6
            content:
              '$ref': '#/spec/panels/cpuGauge'
          - x: 0
            'y': 6
            width: 12
            height: 8
            content:
              '$ref': '#/spec/panels/cpuLine'
          - x: 12
            'y': 0
            width: 12
            height: 8
            content:
              '$ref': '#/spec/panels/defaultTimeSeriesChart'
EOF

oc apply -f - <<EOF
apiVersion: perses.dev/v1alpha1
kind: PersesDashboard
metadata:
    name: prometheus-overview
    namespace: perses-dev
spec:
    display:
        name: Prometheus / Overview
    variables:
        - kind: ListVariable
          spec:
            display:
                name: job
                hidden: false
            allowAllValue: false
            allowMultiple: false
            plugin:
                kind: PrometheusLabelValuesVariable
                spec:
                    datasource:
                        kind: PrometheusDatasource
                        
                    labelName: job
                    matchers:
                        - prometheus_build_info{}
            name: job
        - kind: ListVariable
          spec:
            display:
                name: instance
                hidden: false
            allowAllValue: false
            allowMultiple: false
            plugin:
                kind: PrometheusLabelValuesVariable
                spec:
                    datasource:
                        kind: PrometheusDatasource
                        
                    labelName: instance
                    matchers:
                        - prometheus_build_info{job="$job"}
            name: instance
    panels:
        "0_0":
            kind: Panel
            spec:
                display:
                    name: Prometheus Stats
                plugin:
                    kind: Table
                    spec:
                        columnSettings:
                            - name: job
                              header: Job
                            - name: instance
                              header: Instance
                            - name: version
                              header: Version
                            - name: value
                              hide: true
                            - name: timestamp
                              hide: true
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: count by (job, instance, version) (prometheus_build_info{instance=~"$instance",job=~"$job"})
        "1_0":
            kind: Panel
            spec:
                display:
                    name: Target Sync
                    description: Monitors target synchronization time for Prometheus instances
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: seconds
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (job, scrape_job, instance) (
                                      rate(prometheus_target_sync_length_seconds_sum{instance=~"$instance",job=~"$job"}[$__rate_interval])
                                    )
                                seriesNameFormat: '{{job}} - {{instance}} - Metrics'
        "1_1":
            kind: Panel
            spec:
                display:
                    name: Targets
                    description: Shows discovered targets across Prometheus instances
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: sum by (job, instance) (prometheus_sd_discovered_targets{instance=~"$instance",job=~"$job"})
                                seriesNameFormat: '{{job}} - {{instance}} - Metrics'
        "2_0":
            kind: Panel
            spec:
                display:
                    name: Average Scrape Interval Duration
                    description: Shows average interval between scrapes for Prometheus targets
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: seconds
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |4-
                                      rate(
                                        prometheus_target_interval_length_seconds_sum{instance=~"$instance",job=~"$job"}[$__rate_interval]
                                      )
                                    /
                                      rate(
                                        prometheus_target_interval_length_seconds_count{instance=~"$instance",job=~"$job"}[$__rate_interval]
                                      )
                                seriesNameFormat: '{{job}} - {{instance}} - {{interval}} Configured'
        "2_1":
            kind: Panel
            spec:
                display:
                    name: Scrape failures
                    description: Shows scrape failure metrics for Prometheus targets
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (job, instance) (
                                      rate(
                                        prometheus_target_scrapes_exceeded_body_size_limit_total{instance=~"$instance",job=~"$job"}[$__rate_interval]
                                      )
                                    )
                                seriesNameFormat: 'exceeded body size limit: {{job}} - {{instance}} - Metrics'
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (job, instance) (
                                      rate(
                                        prometheus_target_scrapes_exceeded_sample_limit_total{instance=~"$instance",job=~"$job"}[$__rate_interval]
                                      )
                                    )
                                seriesNameFormat: 'exceeded sample limit: {{job}} - {{instance}} - Metrics'
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (job, instance) (
                                      rate(
                                        prometheus_target_scrapes_sample_duplicate_timestamp_total{instance=~"$instance",job=~"$job"}[$__rate_interval]
                                      )
                                    )
                                seriesNameFormat: 'duplicate timestamp: {{job}} - {{instance}} - Metrics'
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (job, instance) (
                                      rate(
                                        prometheus_target_scrapes_sample_out_of_bounds_total{instance=~"$instance",job=~"$job"}[$__rate_interval]
                                      )
                                    )
                                seriesNameFormat: 'out of bounds: {{job}} - {{instance}} - Metrics'
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (job, instance) (
                                      rate(
                                        prometheus_target_scrapes_sample_out_of_order_total{instance=~"$instance",job=~"$job"}[$__rate_interval]
                                      )
                                    )
                                seriesNameFormat: 'out of order: {{job}} - {{instance}} - Metrics'
        "2_2":
            kind: Panel
            spec:
                display:
                    name: Appended Samples
                    description: Shows rate of samples appended to Prometheus TSDB
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    rate(
                                      prometheus_tsdb_head_samples_appended_total{instance=~"$instance",job=~"$job"}[$__rate_interval]
                                    )
                                seriesNameFormat: '{{job}} - {{instance}} - {{remote_name}} - {{url}}'
        "3_0":
            kind: Panel
            spec:
                display:
                    name: Head Series
                    description: Shows number of series in Prometheus TSDB head
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: prometheus_tsdb_head_series{instance=~"$instance",job=~"$job"}
                                seriesNameFormat: '{{job}} - {{instance}} - Head Series'
        "3_1":
            kind: Panel
            spec:
                display:
                    name: Head Chunks
                    description: Shows number of chunks in Prometheus TSDB head
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: prometheus_tsdb_head_chunks{instance=~"$instance",job=~"$job"}
                                seriesNameFormat: '{{job}} - {{instance}} - Head Chunks'
        "4_0":
            kind: Panel
            spec:
                display:
                    name: Query Rate
                    description: Shows Prometheus query rate metrics
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    rate(
                                      prometheus_engine_query_duration_seconds_count{instance=~"$instance",job=~"$job",slice="inner_eval"}[$__rate_interval]
                                    )
                                seriesNameFormat: '{{job}} - {{instance}} - Query Rate'
        "4_1":
            kind: Panel
            spec:
                display:
                    name: Stage Duration
                    description: Shows duration of different Prometheus query stages
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: seconds
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    max by (slice) (
                                      prometheus_engine_query_duration_seconds{instance=~"$instance",job=~"$job",quantile="0.9"}
                                    )
                                seriesNameFormat: '{{slice}} - Duration'
    layouts:
        - kind: Grid
          spec:
            display:
                title: Prometheus Stats
            items:
                - x: 0
                  "y": 0
                  width: 24
                  height: 8
                  content:
                    $ref: '#/spec/panels/0_0'
        - kind: Grid
          spec:
            display:
                title: Discovery
            items:
                - x: 0
                  "y": 0
                  width: 12
                  height: 8
                  content:
                    $ref: '#/spec/panels/1_0'
                - x: 12
                  "y": 0
                  width: 12
                  height: 8
                  content:
                    $ref: '#/spec/panels/1_1'
        - kind: Grid
          spec:
            display:
                title: Retrieval
            items:
                - x: 0
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/2_0'
                - x: 8
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/2_1'
                - x: 16
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/2_2'
        - kind: Grid
          spec:
            display:
                title: Storage
            items:
                - x: 0
                  "y": 0
                  width: 12
                  height: 8
                  content:
                    $ref: '#/spec/panels/3_0'
                - x: 12
                  "y": 0
                  width: 12
                  height: 8
                  content:
                    $ref: '#/spec/panels/3_1'
        - kind: Grid
          spec:
            display:
                title: Query
            items:
                - x: 0
                  "y": 0
                  width: 12
                  height: 8
                  content:
                    $ref: '#/spec/panels/4_0'
                - x: 12
                  "y": 0
                  width: 12
                  height: 8
                  content:
                    $ref: '#/spec/panels/4_1'
    duration: 1h
EOF

oc apply -f - <<EOF
apiVersion: perses.dev/v1alpha1
kind: PersesDashboard
metadata:
    name: thanos-compact-overview
    namespace: perses-dev
spec:
    display:
        name: Thanos / Compact / Overview
    variables:
        - kind: ListVariable
          spec:
            display:
                name: job
                hidden: false
            allowAllValue: false
            allowMultiple: true
            plugin:
                kind: PrometheusLabelValuesVariable
                spec:
                    datasource:
                        kind: PrometheusDatasource
                        
                    labelName: job
                    matchers:
                        - thanos_build_info{container="thanos-compact"}
            name: job
        - kind: ListVariable
          spec:
            display:
                name: namespace
                hidden: false
            allowAllValue: false
            allowMultiple: false
            plugin:
                kind: PrometheusLabelValuesVariable
                spec:
                    datasource:
                        kind: PrometheusDatasource
                        
                    labelName: namespace
                    matchers:
                        - thanos_status{}
            name: namespace
    panels:
        "0_0":
            kind: Panel
            spec:
                display:
                    name: TODO Compaction Blocks
                    description: Shows number of blocks planned to be compacted.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: decimal
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: sum by (namespace, job) (thanos_compact_todo_compaction_blocks{job=~"$job",namespace="$namespace"})
                                seriesNameFormat: '{{job}} {{namespace}}'
        "0_1":
            kind: Panel
            spec:
                display:
                    name: TODO Compactions
                    description: Shows number of compaction operations to be done.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: decimal
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: sum by (namespace, job) (thanos_compact_todo_compactions{job=~"$job",namespace="$namespace"})
                                seriesNameFormat: '{{job}} {{namespace}}'
        "0_2":
            kind: Panel
            spec:
                display:
                    name: TODO Deletions
                    description: Shows number of blocks that have crossed their retention periods.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: decimal
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: sum by (namespace, job) (thanos_compact_todo_deletion_blocks{job=~"$job",namespace="$namespace"})
                                seriesNameFormat: '{{job}} {{namespace}}'
        "0_3":
            kind: Panel
            spec:
                display:
                    name: TODO Downsamples
                    description: Shows number of blocks to be downsampled.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: decimal
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: sum by (namespace, job) (thanos_compact_todo_downsample_blocks{job=~"$job",namespace="$namespace"})
                                seriesNameFormat: '{{job}} {{namespace}}'
        "1_0":
            kind: Panel
            spec:
                display:
                    name: Group Compactions
                    description: Shows rate of execution of compaction operations against blocks in a bucket, split by compaction resolution.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: counts/sec
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (namespace, job, resolution) (
                                      rate(thanos_compact_group_compactions_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                    )
                                seriesNameFormat: 'Resolution: {{resolution}} - {{job}} {{namespace}}'
        "1_1":
            kind: Panel
            spec:
                display:
                    name: Group Compaction Errors
                    description: Shows the percentage of errors compared to the total number of executed compaction operations against blocks stored in bucket.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: percent
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |4-
                                        sum by (namespace, job) (
                                          rate(
                                            thanos_compact_group_compactions_failures_total{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                          )
                                        )
                                      /
                                        sum by (namespace, job) (
                                          rate(thanos_compact_group_compactions_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                        )
                                    *
                                      100
                                seriesNameFormat: '{{job}} {{namespace}}'
        "2_0":
            kind: Panel
            spec:
                display:
                    name: Downsample Rate
                    description: Shows rate of execution of downsample operations against blocks stored in a bucket, split by resolution.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: counts/sec
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (namespace, job, resolution) (
                                      rate(thanos_compact_downsample_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                    )
                                seriesNameFormat: 'Resolution: {{resolution}} - {{job}} {{namespace}}'
        "2_1":
            kind: Panel
            spec:
                display:
                    name: Downsample Errors
                    description: Shows the percentage of downsample errors compared to the total number of downsample operations done on block in buckets.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: percent
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |4-
                                        sum by (namespace, job) (
                                          rate(thanos_compact_downsample_failed_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                        )
                                      /
                                        sum by (namespace, job) (
                                          rate(thanos_compact_downsample_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                        )
                                    *
                                      100
                                seriesNameFormat: '{{job}} {{namespace}}'
        "2_2":
            kind: Panel
            spec:
                display:
                    name: Downsample Durations
                    description: Shows the p50, p90, and p99 of the time it takes to complete downsample operation against blocks in a bucket, split by resolution.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: seconds
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 0.5
                            palette:
                                mode: auto
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    histogram_quantile(
                                      0.5,
                                      sum by (namespace, job, resolution, le) (
                                        rate(
                                          thanos_compact_downsample_duration_seconds_bucket{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                        )
                                      )
                                    )
                                seriesNameFormat: 'p50 Resolution: {{resolution}} - {{job}} {{namespace}}'
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    histogram_quantile(
                                      0.9,
                                      sum by (namespace, job, resolution, le) (
                                        rate(
                                          thanos_compact_downsample_duration_seconds_bucket{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                        )
                                      )
                                    )
                                seriesNameFormat: 'p90 Resolution: {{resolution}} - {{job}} {{namespace}}'
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    histogram_quantile(
                                      0.99,
                                      sum by (namespace, job, resolution, le) (
                                        rate(
                                          thanos_compact_downsample_duration_seconds_bucket{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                        )
                                      )
                                    )
                                seriesNameFormat: 'p99 Resolution: {{resolution}} - {{job}} {{namespace}}'
        "3_0":
            kind: Panel
            spec:
                display:
                    name: Sync Meta Rate
                    description: Shows rate of syncing block meta files from bucket into memory.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: counts/sec
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (namespace, job) (
                                      rate(thanos_blocks_meta_syncs_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                    )
                                seriesNameFormat: '{{job}} {{namespace}}'
        "3_1":
            kind: Panel
            spec:
                display:
                    name: Sync Meta Errors
                    description: Shows percentage of errors of meta file sync operation compared to total number of meta file syncs from bucket.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: percent
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |4-
                                        sum by (namespace, job) (
                                          rate(thanos_blocks_meta_sync_failures_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                        )
                                      /
                                        sum by (namespace, job) (
                                          rate(thanos_blocks_meta_syncs_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                        )
                                    *
                                      100
                                seriesNameFormat: '{{job}} {{namespace}}'
        "3_2":
            kind: Panel
            spec:
                display:
                    name: Sync Meta Durations
                    description: Shows p50, p90 and p99 durations of the time it takes to sync meta files from blocks in bucket.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: seconds
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 0.5
                            palette:
                                mode: auto
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    histogram_quantile(
                                      0.5,
                                      sum by (namespace, job, le) (
                                        rate(
                                          thanos_blocks_meta_sync_duration_seconds_bucket{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                        )
                                      )
                                    )
                                seriesNameFormat: p50 {{job}} {{namespace}}
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    histogram_quantile(
                                      0.9,
                                      sum by (namespace, job, le) (
                                        rate(
                                          thanos_blocks_meta_sync_duration_seconds_bucket{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                        )
                                      )
                                    )
                                seriesNameFormat: p90 {{job}} {{namespace}}
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    histogram_quantile(
                                      0.99,
                                      sum by (namespace, job, le) (
                                        rate(
                                          thanos_blocks_meta_sync_duration_seconds_bucket{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                        )
                                      )
                                    )
                                seriesNameFormat: p99 {{job}} {{namespace}}
        "4_0":
            kind: Panel
            spec:
                display:
                    name: Deletion Rate
                    description: Shows the deletion rate of blocks already marked for deletion.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: counts/sec
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (namespace, job) (
                                      rate(thanos_compact_blocks_cleaned_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                    )
                                seriesNameFormat: '{{job}} {{namespace}}'
        "4_1":
            kind: Panel
            spec:
                display:
                    name: Deletion Errors
                    description: Shows rate of deletion failures for blocks already marked for deletion.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: counts/sec
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (namespace, job) (
                                      rate(
                                        thanos_compact_block_cleanup_failures_total{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                      )
                                    )
                                seriesNameFormat: '{{job}} {{namespace}}'
        "4_2":
            kind: Panel
            spec:
                display:
                    name: Marking Rate
                    description: Shows the rate at which blocks are marked for deletion (from GC and retention policy).
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: counts/sec
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (namespace, job) (
                                      rate(
                                        thanos_compact_blocks_marked_total{job=~"$job",marker="deletion-mark.json",namespace="$namespace"}[$__rate_interval]
                                      )
                                    )
                                seriesNameFormat: '{{job}} {{namespace}}'
        "5_0":
            kind: Panel
            spec:
                display:
                    name: Bucket Operations
                    description: Shows rate of executions of operations against object storage bucket.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: requests/sec
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (namespace, job, operation) (
                                      rate(thanos_objstore_bucket_operations_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                    )
                                seriesNameFormat: '{{job}} {{operation}} {{namespace}}'
        "5_1":
            kind: Panel
            spec:
                display:
                    name: Bucket Operation Errors
                    description: Shows percentage of errors of operations against object storage bucket.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: percent
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |4-
                                        sum by (namespace, job, operation) (
                                          rate(
                                            thanos_objstore_bucket_operation_failures_total{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                          )
                                        )
                                      /
                                        sum by (namespace, job, operation) (
                                          rate(thanos_objstore_bucket_operations_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                        )
                                    *
                                      100
                                seriesNameFormat: '{{job}} {{operation}} {{namespace}}'
        "5_2":
            kind: Panel
            spec:
                display:
                    name: Bucket Operation Latency
                    description: Shows latency of operations against object storage bucket.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: seconds
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 0.5
                            palette:
                                mode: auto
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    histogram_quantile(
                                      0.99,
                                      sum by (namespace, job, operation, le) (
                                        rate(
                                          thanos_objstore_bucket_operation_duration_seconds_bucket{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                        )
                                      )
                                    )
                                seriesNameFormat: p99 {{job}} {{operation}} {{namespace}}
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    histogram_quantile(
                                      0.9,
                                      sum by (namespace, job, operation, le) (
                                        rate(
                                          thanos_objstore_bucket_operation_duration_seconds_bucket{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                        )
                                      )
                                    )
                                seriesNameFormat: p90 {{job}} {{operation}} {{namespace}}
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    histogram_quantile(
                                      0.5,
                                      sum by (namespace, job, operation, le) (
                                        rate(
                                          thanos_objstore_bucket_operation_duration_seconds_bucket{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                        )
                                      )
                                    )
                                seriesNameFormat: p50 {{job}} {{operation}} {{namespace}}
        "6_0":
            kind: Panel
            spec:
                display:
                    name: Halted Compactors
                    description: Shows compactors that have been halted due to unexpected errors.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: decimal
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: sum by (namespace, job) (thanos_compact_halted{job=~"$job",namespace="$namespace"})
                                seriesNameFormat: '{{job}} {{namespace}}'
        "7_0":
            kind: Panel
            spec:
                display:
                    name: Garbage Collection
                    description: Shows rate of execution of removal of blocks, if their data is available as part of a block with a higher compaction level.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: counts/sec
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    sum by (namespace, job) (
                                      rate(thanos_compact_garbage_collection_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                    )
                                seriesNameFormat: '{{job}} {{namespace}}'
        "7_1":
            kind: Panel
            spec:
                display:
                    name: Garbage Collection Errors
                    description: Shows the percentage of garbage collection operations that resulted in errors.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: percent
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 1
                            palette:
                                mode: auto
                            stack: all
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |4-
                                        sum by (namespace, job) (
                                          rate(
                                            thanos_compact_garbage_collection_failures_total{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                          )
                                        )
                                      /
                                        sum by (namespace, job) (
                                          rate(thanos_compact_garbage_collection_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                        )
                                    *
                                      100
                                seriesNameFormat: '{{job}} {{namespace}}'
        "7_2":
            kind: Panel
            spec:
                display:
                    name: Garbage Collection Durations
                    description: Shows p50, p90 and p99 of how long it takes to execute garbage collection operations.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                        yAxis:
                            format:
                                unit: seconds
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 0.5
                            palette:
                                mode: auto
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    histogram_quantile(
                                      0.5,
                                      sum by (namespace, job, le) (
                                        rate(
                                          thanos_compact_garbage_collection_duration_seconds_bucket{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                        )
                                      )
                                    )
                                seriesNameFormat: p50 {{job}} {{namespace}}
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    histogram_quantile(
                                      0.9,
                                      sum by (namespace, job, le) (
                                        rate(
                                          thanos_compact_garbage_collection_duration_seconds_bucket{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                        )
                                      )
                                    )
                                seriesNameFormat: p90 {{job}} {{namespace}}
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: |-
                                    histogram_quantile(
                                      0.99,
                                      sum by (namespace, job, le) (
                                        rate(
                                          thanos_compact_garbage_collection_duration_seconds_bucket{job=~"$job",namespace="$namespace"}[$__rate_interval]
                                        )
                                      )
                                    )
                                seriesNameFormat: p99 {{job}} {{namespace}}
        "8_0":
            kind: Panel
            spec:
                display:
                    name: CPU Usage
                    description: Shows the CPU usage of the component.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                            values:
                                - last
                        yAxis:
                            format:
                                unit: decimal
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 0.5
                            palette:
                                mode: auto
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: rate(process_cpu_seconds_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                seriesNameFormat: '{{pod}}'
        "8_1":
            kind: Panel
            spec:
                display:
                    name: Memory Usage
                    description: Shows various memory usage metrics of the component.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                            values:
                                - last
                        yAxis:
                            format:
                                unit: bytes
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 0.5
                            palette:
                                mode: auto
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: go_memstats_alloc_bytes{job=~"$job",namespace="$namespace"}
                                seriesNameFormat: Alloc All {{pod}}
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: go_memstats_heap_alloc_bytes{job=~"$job",namespace="$namespace"}
                                seriesNameFormat: Alloc Heap {{pod}}
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: rate(go_memstats_alloc_bytes_total{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                seriesNameFormat: Alloc Rate All {{pod}}
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: rate(go_memstats_heap_alloc_bytes{job=~"$job",namespace="$namespace"}[$__rate_interval])
                                seriesNameFormat: Alloc Rate Heap {{pod}}
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: go_memstats_stack_inuse_bytes{job=~"$job",namespace="$namespace"}
                                seriesNameFormat: Inuse Stack {{pod}}
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: go_memstats_heap_inuse_bytes{job=~"$job",namespace="$namespace"}
                                seriesNameFormat: Inuse Heap {{pod}}
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: process_resident_memory_bytes{job=~"$job",namespace="$namespace"}
                                seriesNameFormat: Resident Memory {{pod}}
        "8_2":
            kind: Panel
            spec:
                display:
                    name: Goroutines
                    description: Shows the number of goroutines being used by the component.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                            values:
                                - last
                        yAxis:
                            format:
                                unit: decimal
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 0.5
                            palette:
                                mode: auto
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: go_goroutines{job=~"$job",namespace="$namespace"}
                                seriesNameFormat: '{{pod}}'
        "8_3":
            kind: Panel
            spec:
                display:
                    name: GC Duration
                    description: Shows the Go garbage collection pause durations for the component.
                plugin:
                    kind: TimeSeriesChart
                    spec:
                        legend:
                            position: bottom
                            mode: table
                            values:
                                - last
                        yAxis:
                            format:
                                unit: seconds
                        visual:
                            display: line
                            lineWidth: 0.25
                            areaOpacity: 0.5
                            palette:
                                mode: auto
                queries:
                    - kind: TimeSeriesQuery
                      spec:
                        plugin:
                            kind: PrometheusTimeSeriesQuery
                            spec:
                                datasource:
                                    kind: PrometheusDatasource
                                    
                                query: go_gc_duration_seconds{job=~"$job",namespace="$namespace"}
                                seriesNameFormat: '{{quantile}} - {{pod}}'
    layouts:
        - kind: Grid
          spec:
            display:
                title: TODO Operations
            items:
                - x: 0
                  "y": 0
                  width: 6
                  height: 6
                  content:
                    $ref: '#/spec/panels/0_0'
                - x: 6
                  "y": 0
                  width: 6
                  height: 6
                  content:
                    $ref: '#/spec/panels/0_1'
                - x: 12
                  "y": 0
                  width: 6
                  height: 6
                  content:
                    $ref: '#/spec/panels/0_2'
                - x: 18
                  "y": 0
                  width: 6
                  height: 6
                  content:
                    $ref: '#/spec/panels/0_3'
        - kind: Grid
          spec:
            display:
                title: Group Compactions
            items:
                - x: 0
                  "y": 0
                  width: 12
                  height: 8
                  content:
                    $ref: '#/spec/panels/1_0'
                - x: 12
                  "y": 0
                  width: 12
                  height: 8
                  content:
                    $ref: '#/spec/panels/1_1'
        - kind: Grid
          spec:
            display:
                title: Downsample Operations
            items:
                - x: 0
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/2_0'
                - x: 8
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/2_1'
                - x: 16
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/2_2'
        - kind: Grid
          spec:
            display:
                title: Sync Meta
            items:
                - x: 0
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/3_0'
                - x: 8
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/3_1'
                - x: 16
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/3_2'
        - kind: Grid
          spec:
            display:
                title: Block Deletion
            items:
                - x: 0
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/4_0'
                - x: 8
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/4_1'
                - x: 16
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/4_2'
        - kind: Grid
          spec:
            display:
                title: Bucket Operations
            items:
                - x: 0
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/5_0'
                - x: 8
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/5_1'
                - x: 16
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/5_2'
        - kind: Grid
          spec:
            display:
                title: Halted Compactors
            items:
                - x: 0
                  "y": 0
                  width: 24
                  height: 8
                  content:
                    $ref: '#/spec/panels/6_0'
        - kind: Grid
          spec:
            display:
                title: Garbage Collection
            items:
                - x: 0
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/7_0'
                - x: 8
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/7_1'
                - x: 16
                  "y": 0
                  width: 8
                  height: 8
                  content:
                    $ref: '#/spec/panels/7_2'
        - kind: Grid
          spec:
            display:
                title: Resources
            items:
                - x: 0
                  "y": 0
                  width: 6
                  height: 8
                  content:
                    $ref: '#/spec/panels/8_0'
                - x: 6
                  "y": 0
                  width: 6
                  height: 8
                  content:
                    $ref: '#/spec/panels/8_1'
                - x: 12
                  "y": 0
                  width: 6
                  height: 8
                  content:
                    $ref: '#/spec/panels/8_2'
                - x: 18
                  "y": 0
                  width: 6
                  height: 8
                  content:
                    $ref: '#/spec/panels/8_3'
    duration: 1h
EOF

oc apply -f - <<EOF
apiVersion: perses.dev/v1alpha1
kind: PersesDatasource
metadata:
  name: thanos-querier-datasource
  namespace: perses-dev
spec:
  config:
    display:
      name: "Thanos Querier Datasource"
    default: true
    plugin:
      kind: "PrometheusDatasource"
      spec:
        proxy:
          kind: HTTPProxy
          spec:
            url: https://thanos-querier.openshift-monitoring.svc.cluster.local:9091
            secret: thanos-querier-datasource-secret
  client:
    tls:
      enable: true
      caCert:
        type: file
        certPath: /ca/service-ca.crt
EOF

oc apply -f - <<EOF
apiVersion: perses.dev/v1alpha1
kind: PersesDatasource
metadata:
  name: perses-datasource-sample
  namespace: perses-dev
spec:
  config:
    display:
      name: 'Default Datasource'
    default: true
    plugin:
      kind: 'PrometheusDatasource'
      spec:
        directUrl: 'https://prometheus.demo.prometheus.io'
EOF