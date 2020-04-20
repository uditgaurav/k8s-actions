#!/bin/sh

set -e

# Extract the base64 encoded config data and write this to the KUBECONFIG
echo "$KUBE_CONFIG_DATA" | base64 --decode > /tmp/config
export KUBECONFIG=/tmp/config

# Delete kubernetes pod 
##sh -c "kubectl${KUBECTL_VERSION:+.${KUBECTL_VERSION}} delete pod ${POD_DELETE} -n ${NAMESPACE}"

####################################
#######     POD-DELETE       #######
####################################

##Fetching the RBAC file
printf "Creating RBAC for pod-delete experiment\n"
wget -O rbac.yml https://raw.githubusercontent.com/litmuschaos/chaos-charts/master/charts/generic/pod-delete/rbac.yaml
##Changing the required fild
sed -i 's/namespace: default/namespace: '"$namespace"'/' rbac.yml
## Creating the Service Account for the experiment
kubectl apply -f rbac.yml -n $namespace
echo "Service Account has been created"

##Creating pod-delete experiment
printf "Creating pod-delete experiment\n"
kubectl create -f https://raw.githubusercontent.com/litmuschaos/chaos-charts/master/charts/generic/pod-delete/experiment.yaml -n $namespace
echo "Service Account has been created"

##Fetching the engine file
printf "Creating engine for pod-delete experiment\n"
wget -O engine.yml https://raw.githubusercontent.com/litmuschaos/chaos-charts/master/charts/generic/pod-delete/engine.yaml
##Changing the required fild
sed -i "s/namespace: default/namespace: '"$namespace"'/g;"\
"s/appns: 'default'/appns: "$namespace"/g;"\
"s/jobCleanUpPolicy: 'delete'/jobCleanUpPolicy: retain/g;"\
"s/applabel: 'app=nginx'/applabel: '"$app_label"'/g" engine.yml
## Creating the ChaosEngine for the experiment
kubectl apply -f engine.yml
echo "ChaosEngine for pod-delete has been created"

##Waiting for engine to come in running state
printf "Waiting for the runner pod to come in running state\n"
sleep 15
runnerPodStatus=$(kubectl get pod nginx-chaos-runner -n $namespace --no-headers -o custom-columns=:status.phase)
echo "$runnerPodStatus"

echo "Now wait for runner pod completion"
runnerPodStatus=$(kubectl get pod nginx-chaos-runner -n $namespace --no-headers -o custom-columns=:status.phase)
##Waiting for Runner pod to get completed
while [ $runnerPodStatus != "Succeeded" ]; do
  echo "Runner pod is in ${runnerPodStatus} state please wait"
  runnerPodStatus=$(kubectl get pod nginx-chaos-runner -n $namespace --no-headers -o custom-columns=:status.phase)
  sleep 10
done

##Getting the experiment pod namespace
jobpodName=$(kubectl get pod -l name=pod-delete -n litmus -o custom-columns=:metadata.name)

kubectl logs $jobpodName -n litmus

##Getting the verdict of chaosresult
chaosResultVerdict=$(kubectl get chaosresult nginx-chaos-pod-delete -n litmus -o jsonpath='{.status.experimentstatus.verdict}')

if [ ${chaosResultVerdict} == "Pass" ]
then
   echo "Congratulations the verdict of the experiment is: ${chaosResultVerdict}"
else
    echo "chaos result verdict is: ${chaosResultVerdict}"
    exit 1
fi
