#!/bin/bash

echo monitoring-deploy

read -p 'tag ' tag

cd /Users/emurasak/workspace/scripts

rm cmo.yaml

./monitoring-disable.sh

cd /Users/emurasak/workspace/scripts

oc project openshift-monitoring

oc get deployment cluster-monitoring-operator -o=yaml > cmo_bkp.yaml

cp cmo_bkp.yaml cmo.yaml

PATCH_JSON='[{"op": "replace", "path": "/spec/template/spec/containers/args/20", "value": "-images=monitoring-plugin=quay.io/rh-ee-emurasak/monitoring-plugin:pf6-3"}]'

oc patch deployment cluster-monitoring-operator -n openshift-monitoring --type=json -p="$PATCH_JSON"

# yq eval -i '.spec.template.spec.containers[0].resources.args = [.spec.template.spec.containers[0].resources.args[] | sub("- -images=mm")

# oc apply -f cmo.yaml

./monitoring-enable.sh