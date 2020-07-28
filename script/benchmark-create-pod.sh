#!/bin/bash

POD_NUM=500
BASE_NAME=sina-test
NAMESPACE=sina-test
TEMPLATE_FILE=pod.json

function createPod(){
    id=${1}
    podName="${BASE_NAME}-${id}"
    pod=${POD_TEMPLATE//POD_NAME/${podName}}
    pod=${pod//NAMESPACE/${NAMESPACE}}
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
            echo "     -h, --help            show brief help"
            echo "     --pod-num             set pods number to create. Default: 500"
            echo "     --name                set pod base name, will use this name and id to generate pod name. Default: sina-test"
            echo "     --namespace           set namespace to create pod, this namespace should already created. Default: sina-test"
            echo "     --pod-template        the file path of pod template in json format"
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
        --pod-template)
            TEMPLATE_FILE=${2}
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
POD_TEMPLATE=`cat ${TEMPLATE_FILE} | sed "s/^[ \t]*//g"| sed ":a;N;s/\n//g;ta"`
echo "Test start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
createPods
checkPodsCreate
checkPodsScheduled
checkPodsRunning
echo "Test finished:           `date +%Y-%m-%d' '%H:%M:%S.%N`"
