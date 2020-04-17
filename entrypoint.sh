#!/bin/sh

set -e

# Extract the base64 encoded config data and write this to the KUBECONFIG
echo "$KUBE_CONFIG_DATA" | base64 --decode > /tmp/config
export KUBECONFIG=/tmp/config

# Delete kubernetes pod 
sh -c "kubectl${KUBECTL_VERSION:+.${KUBECTL_VERSION}} delete pod ${pod_name} -n ${namespace}"
