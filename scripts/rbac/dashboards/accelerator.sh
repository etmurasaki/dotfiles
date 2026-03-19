#!/bin/bash

#git clone git@github.com:yevgeny-shnaidman/kernel-module-management.git
#cd kernel-module-management
#git checkout yevgeny/test-perses-dashboard

cd /Users/emurasak/workspace/kernel-module-management/
make deploy IMG=quay.io/yshnaidm/kmmo:simulate-metrics KUBECONFIG=/Users/emurasak/Downloads/kubeconfig