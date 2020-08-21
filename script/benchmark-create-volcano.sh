#!/bin/bash

DEPLOY_NUM=1
POD_NUM=500
BASE_NAME=sina-test
NAMESPACE=sina-test
TEMPLATE_FILE=pod.json
PIPE_COUNT=20

function createDeploy(){
    id=$1
    kubectl apply -f /tmp/volcanojobvolcanojob$id/ --recursive
    rm -rf /tmp/volcanojobvolcanojob${id}
}
function gen_pod(){
    p_id=$1
    f_id=$2
    podName="${BASE_NAME}-${p_id}"
    f_pod=${pod//POD_NAME/${podName}}
    f_pod=${f_pod//EVS_PVC_NAME/${podName}}
    mkdir -p /tmp/volcanojobvolcanojob$f_id
    echo $f_pod > /tmp/volcanojobvolcanojob$f_id/${p_id}.json
}

function createPods(){
    j=1
    for i in $(seq 1 ${DEPLOY_NUM});do
        gen_pod $i $j
        j=$(($j+1))
        if [ $j -gt $PIPE_COUNT ] ; then
            j=1
        fi
    done
    if [[ $DEPLOY_NUM -gt $PIPE_COUNT ]]; then
        for i in $(seq 1 $PIPE_COUNT);do
            createDeploy ${i} &
        done
    else
        for i in $(seq 1 $DEPLOY_NUM);do
            createDeploy ${i} &
        done
    fi
}

function checkPodsRunning(){
    finishedPods=0
    outarray=(1 2 4 8 16 32 64 128 256 512 1024 2048)
    finalarray=(8 4 2 1 0)
    final=${finalarray[0]}
    while [[ $final -ge $TOTAL_POD_NUM ]]; do
        finalarray=(${finalarray[@]:1})
        final=${finalarray[0]}
    done
    created=0
    scheduled=0
    running=0
    while [[ ${finishedPods} -ne ${TOTAL_POD_NUM} ]];do
        if [[ -f /tmp/debug ]]; then
            echo ${finishedPods} ${TOTAL_POD_NUM}
        fi
        first=${outarray[0]}
        final=${finalarray[0]}
        ret=`kubectl -n ${NAMESPACE} get pod | grep ${BASE_NAME}| grep -v "NAME"`
        
        if [[ ${created} -eq 0 ]]; then
             finishedPods=`echo "$ret" |grep ${BASE_NAME} | wc -l`
             if [[ ${finishedPods} -eq ${TOTAL_POD_NUM} ]]; then
                 created=1
                 echo "All pods created:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
             fi
        fi

        if [[ ${scheduled} -eq 0 ]]; then
             finishedPods=`echo "$ret" |grep ${BASE_NAME}|  grep -v "Pending"| wc -l`
             if [[ ${finishedPods} -eq ${TOTAL_POD_NUM} ]]; then
                 scheduled=1
                 echo "All pods scheduled:       `date +%Y-%m-%d' '%H:%M:%S.%N`"
             fi
        fi

        
        if [[ ${running} -eq 0 ]]; then
             finishedPods=`echo "$ret" | grep ${BASE_NAME}| grep -e "Running" -e "Completed"| wc -l`
             if [[ $finishedPods -ge $first ]]; then
                 echo "First $first($finishedPods) Pod Running:            `date +%Y-%m-%d' '%H:%M:%S.%N`"
                 outarray=(${outarray[@]:1})
             fi
             if [[ $finishedPods -ge $(($TOTAL_POD_NUM-$final)) ]]; then
                 echo "Final $final($finishedPods) Pod Running:            `date +%Y-%m-%d' '%H:%M:%S.%N`"
                 finalarray=(${finalarray[@]:1})
             fi
             if [[ ${finishedPods} -eq ${TOTAL_POD_NUM} ]]; then
                 running=1
                 echo "All pods Running:       `date +%Y-%m-%d' '%H:%M:%S.%N`"
             fi
        fi
        finishedPods=`echo "$ret" | grep ${BASE_NAME}| grep  "Completed" | wc -l`
    done
    echo "All pods Completed:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

function getPingServer(){
    PINGSERVER=`kubectl -n ${NAMESPACE} get pods perf-server-1 -o=jsonpath='{.status.podIP}'`
}

function getCostEach(){
    kubectl get events -ojson -n ${NAMESPACE} > /tmp/curl-get-event.log
    kubectl get pods -ojson -n ${NAMESPACE} > /tmp/curl-get-event.log
}

SCRIPT=$(basename $0)
while test $# -gt 0; do
    case $1 in
        -h | --help)
            echo "${SCRIPT} - for create pod benchmark"
            echo " "
            echo "     options:"
            echo "     -h, --help            show brief help"
            echo "     --deploy-num          set deploy number to create. Default: 1"
            echo "     --pod-num             set pods number to create. Default: 500"
            echo "     --image               set pods image"
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
        --deploy-num)
            DEPLOY_NUM=${2}
            shift 2
            ;;
        --image)
            POD_IMAGE=${2}
            shift 2
            ;;
        *)
            echo "unknown option: $1 $2"
            exit 1
            ;;
        esac
done

getPingServer
POD_TEMPLATE=`cat ${TEMPLATE_FILE} | sed "s/^[ \t]*//g"| sed ":a;N;s/\n//g;ta"`
pod=${POD_TEMPLATE//NAMESPACE/${NAMESPACE}}
pod=${pod//PINGSERVER/${PINGSERVER}}
pod=${pod//POD_NUM/${POD_NUM}}
pod=${pod//POD_IMAGE/${POD_IMAGE}}
date +%Y-%m-%d' '%H:%M:%S > /tmp/begin
echo "Test start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
createPods
TOTAL_POD_NUM=$(( DEPLOY_NUM * POD_NUM ))
checkPodsRunning
getCostEach
echo "Test finished:           `date +%Y-%m-%d' '%H:%M:%S.%N`"

