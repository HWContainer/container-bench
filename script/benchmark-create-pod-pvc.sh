#!/bin/bash

POD_NUM=500
BASE_NAME=sina-test
PVC_PREFIX=sina-pvc
NAMESPACE=sina-test
POD_TEMPLATE='{"apiVersion":"v1","kind":"Pod","metadata":{"labels":{"app":"PODNAME"},"name":"PODNAME","namespace":"NAMESPACE"},"spec":{"containers":[{"command":["/bin/bash","-c","while true;do sleep 1;done"],"image":"swr.cn-north-4.myhuaweicloud.com/hwstaff_z00425431/usergraph-ml:1.0.130","imagePullPolicy":"Always","lifecycle":{"postStart":{"exec":{"command":["/bin/bash","-c","sleep 1"]}}},"volumeMounts":[{"name":"cci-evs","mountPath":"/tmp/evs0/k06kzcdt"}],"name":"container-0","resources":{"limits":{"cpu":"16","memory":"32Gi"},"requests":{"cpu":"16","memory":"32Gi"}},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File"}],"dnsPolicy":"Default","imagePullSecrets":[{"name":"imagepull-secret"}],"restartPolicy":"Always","schedulerName":"default-scheduler","terminationGracePeriodSeconds":30,"nodeSelector":{"node.cci.io/allowed-on-poc-dedicated-node":"sina"},"volumes":[{"persistentVolumeClaim":{"claimName":"PVC_NAME"},"name":"cci-evs"}],"tolerations":[{"effect":"NoSchedule","key":"node.cci.io/allowed-on-poc-dedicated-node","operator":"Equal","value":"sina"}]}}'

function createPod(){
    id=${1}
    podName="${BASE_NAME}-${id}"
    pvcName="${PVC_PREFIX}-${id}"
    pod=${POD_TEMPLATE//PODNAME/${podName}}
    pod=${pod//NAMESPACE/${NAMESPACE}}
    pod=${pod//PVC_NAME/${pvcName}}
    curl -k -X POST -H "Content-Type:application/json" -H "X-Auth-Token:${token}" $endpoint/api/v1/namespaces/${NAMESPACE}/pods -d "${pod}" -s 2>&1 >> /tmp/curl-create-pod.log
}

function createPods(){
    for i in $(seq 1 ${POD_NUM});do
        createPod ${i} &
    done
}

function checkPodsCreate(){
    finishedPods=0
    while [[ ${finishedPods} -ne ${POD_NUM} ]];do
        finishedPods=`kubectl -n ${NAMESPACE} get pod | grep ${BASE_NAME}| grep -v "NAME"| wc -l`
    done
    echo "All pods created:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

function checkPodsScheduled(){
    finishedPods=0
    while [[ ${finishedPods} -ne ${POD_NUM} ]];do
        finishedPods=`kubectl -n ${NAMESPACE} get pod | grep ${BASE_NAME}| grep -v "NAME" | grep -v "Pending" | wc -l`
    done
    echo "All pods scheduled:      `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

function checkPodsRunning(){
    finishedPods=0
    while [[ ${finishedPods} -ne ${POD_NUM} ]];do
        finishedPods=`kubectl -n ${NAMESPACE} get pod | grep ${BASE_NAME}| grep -v "NAME" | grep  "Running" | wc -l`
    done
    echo "All pods Running:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

SCRIPT=$(basename $0)
while test $# -gt 0; do
    case $1 in
        -h | --help)
            echo "${SCRIPT} - for create pod benchmark"
            echo " "
            echo "     options:"
            echo "     -h, --help           show brief help"
            echo "     --pod-num             set pods number to create. Default: 500"
            echo "     --name                set pod base name, will use this name and id to generate pod name. Default: sina-test"
            echo "     --pvc-prefix          name prefix for pvc to bind to pod. Default: sina-pvc"
            echo "     --namespace           set namespace to create pod, this namespace should already created. Default: sina-test"
            echo ""
            exit 0
            ;;
        --name)
            BASE_NAME=${2}
            shift 2
            ;;
        --namespace)
            NAMESPACE=${2}
            shift 2
            ;;
        --pvc-prefix)
            PVC_PREFIX=${2}
            shift 2
            ;;
        --pod-num)
            POD_NUM=${2}
            shift 2
            ;;
        *)
            echo "unknown option: $1 $2"
            exit 1
            ;;
        esac
done

echo "Test start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
createPods
checkPodsCreate
checkPodsScheduled
checkPodsRunning
echo "Test finished:           `date +%Y-%m-%d' '%H:%M:%S.%N`"

