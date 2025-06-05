#!/bin/bash

oc create namespace observability-operator

oc label namespace  observability-operator openshift.io/cluster-monitoring="true"

oc project observability-operator

operator-sdk run bundle quay.io/rh-ee-emurasak/observability-operator-bundle:1.2.0-alpha --namespace observability-operator --security-context-config restricted

