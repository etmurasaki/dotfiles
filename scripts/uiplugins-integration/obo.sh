#!/bin/bash

oc create namespace observability-operator

oc label namespace  observability-operator openshift.io/cluster-monitoring="true"

oc project observability-operator

oc new-project perses-dev

operator-sdk run bundle quay.io/rh-ee-pyurkovi/observability-operator-bundle:1.2.1-short-time --namespace observability-operator --security-context-config restricted

