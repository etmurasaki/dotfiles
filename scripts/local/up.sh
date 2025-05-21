#!/bin/bash

cd /Users/emurasak/workspace/console-eve

oc process -f examples/console-oauth-client.yaml | oc apply -f -
oc get oauthclient console-oauth-client -o jsonpath='{.secret}' > examples/console-client-secret
oc apply -f examples/secret.yaml
oc extract secret/off-cluster-token -n openshift-console --to ./examples --confirm
export BRIDGE_PLUGINS="monitoring-plugin=http://localhost:9001"
./examples/run-bridge.sh
