#!/bin/sh

set -e

##Running pod-network-loss experiment
echo "############################################################"
echo "#######     RUNNING POD NETWORK LOSS EXPERIMENT      #######"
echo "############################################################"

##Fetching the RBAC file
printf "Creating RBAC for pod-network-loss experiment\n"
git clone https://github.com/litmuschaos/chaos-charts.git

##Changing the required fild
sed -i 's/namespace: default/namespace: '"$APP_NS"'/' chaos-charts/charts/generic/pod-network-loss/rbac.yaml
## Creating the Service Account for the experiment
sh -c "kubectl apply -f chaos-charts/charts/generic/pod-network-loss/rbac.yaml -n $APP_NS"
echo "Service Account has been created"

##Creating pod-network-loss experiment
printf "Creating pod-network-loss experiment\n"
sh -c "kubectl create -f chaos-charts/charts/generic/pod-network-loss/experiment.yaml -n $APP_NS"
echo "Chaos Eperiment has been created"

##Fetching the engine file
printf "Creating engine for pod-network-loss experiment\n"
##Changing the required fild
sed -i "s/namespace: default/namespace: '"$APP_NS"'/g;"\
"s/name: nginx-network-chaos/name: engine8/g;"\
"s/appns: 'default'/appns: "$APP_NS"/g;"\
"s/jobCleanUpPolicy: 'delete'/jobCleanUpPolicy: retain/g;"\
"s/applabel: 'app=nginx'/applabel: '"$APP_LABEL"'/g" chaos-charts/charts/generic/pod-network-loss/engine.yaml
##Modify ENVs of chaos engine
sed -i -e\
"/name: TOTAL_CHAOS_DURATION/{n;s/.*/              value: '"$TOTAL_CHAOS_DURATION"'/};"\
"/name: CPU_CORES/{n;s/.*/              value: '"$CPU_CORES"'/};"\
"/name: NETWORK_PACKET_LOSS_PERCENTAGE/{n;s/.*/              value: '"$NETWORK_PACKET_LOSS_PERCENTAGE"'/};"\
"/name: TARGET_CONTAINER/{n;s/.*/              value: '"$TARGET_CONTAINER"'/}" chaos-charts/charts/generic/pod-network-loss/engine.yaml

## Creating the ChaosEngine for the experiment
sh -c "kubectl apply -f chaos-charts/charts/generic/pod-network-loss/engine.yaml"
echo "ChaosEngine for pod-network-loss has been created"

##Waiting for engine to come in running state
printf "Waiting for the runner pod to come in running state\n"
sleep 15
runnerPodStatus=$(kubectl get pod engine8-runner -n $APP_NS --no-headers -o custom-columns=:status.phase)
echo "$runnerPodStatus"

##Waiting for Runner pod to get completed
while [ $runnerPodStatus != "Succeeded" ]; do
  echo "Runner pod is in ${runnerPodStatus} state please wait"
  runnerPodStatus=$(kubectl get pod engine8-runner -n $APP_NS --no-headers -o custom-columns=:status.phase)
  sleep 10
done

##Getting the experiment pod namespace
jobpodName=$(kubectl get pod -l name=pod-network-loss -n $APP_NS -o custom-columns=:metadata.name)

kubectl logs -f $jobpodName -n $APP_NS

##Getting the verdict of chaosresult
chaosResultVerdict=$(kubectl get chaosresult engine8-pod-network-loss -n $APP_NS -o jsonpath='{.status.experimentstatus.verdict}')
echo "Verdict is: $chaosResultVerdict"
if [ $chaosResultVerdict = "Pass" ]
then
   echo "Congratulations the verdict of the experiment is: ${chaosResultVerdict}"
else
    echo "Chaos result verdict is: ${chaosResultVerdict}"
    exit 1
fi

