#!/bin/bash

DEPLOY_NUM=1
POD_NUM=1
BASE_NAME=sina-test
NAMESPACE=sina-test
TEMPLATE_FILE=pod.json
PIPE_COUNT=20

function createDeploy(){
    id=$1
    kubectl apply -f /tmp/svcsvc$id/ --recursive
    rm -rf /tmp/svcsvc${id}
}
function gen_pod(){
    p_id=$1
    f_id=$2
    d_idx=$3
    svcName="${BASE_NAME}-${p_id}"
    deployName="${BASE_NAME}-${d_idx}"
    f_pod=${pod//POD_NAME/${deployName}}
    f_pod=${f_pod//SVC_NAME/${svcName}}
    mkdir -p /tmp/svcsvc$f_id
    echo $f_pod > /tmp/svcsvc$f_id/${p_id}.json
}

function createPods(){
    j=1
    d=1
    for i in $(seq 1 ${DEPLOY_NUM});do
        gen_pod $i $j $d
        j=$(($j+1))
        d=$(($d+1))
        if [ $j -gt $PIPE_COUNT ] ; then
            j=1
        fi
        if [ $j -gt $POD_NUM ] ; then
            d=1
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

function checkPodsCreate(){
    finishedPods=0
    while [[ ${finishedPods} -ne ${TOTAL_POD_NUM} ]];do
        finishedPods=`kubectl -n ${NAMESPACE} get vs | grep ${BASE_NAME}| grep -v "NAME"| wc -l`
    done
    echo "All vs created:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

function checkPodsScheduled(){
    finishedPods=0
    while [[ ${finishedPods} -ne ${TOTAL_POD_NUM} ]];do
        finishedPods=`kubectl -n ${NAMESPACE} get pod | grep ${BASE_NAME}| grep -v "NAME" | grep -v "Pending" | wc -l`
    done
    echo "All pods scheduled:      `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

function checkPodsRunning(){
    finishedPods=0
    outarray=(1 2 4 8 16 32 64 128 256 512 1024 2048)
    finalarray=(8 4 2 1 0)
    while [[ ${finishedPods} -ne ${TOTAL_POD_NUM} ]];do
        if [[ -f /tmp/debug ]]; then
            echo ${finishedPods} ${TOTAL_POD_NUM}
        fi
        first=${outarray[0]}
        final=${finalarray[0]}
        finishedPods=`kubectl -n ${NAMESPACE} get vs | grep ${BASE_NAME}| grep -v "NAME" | wc -l`
        if [[ $finishedPods -ge $first ]]; then
             echo "First $first($finishedPods) SVC Running:            `date +%Y-%m-%d' '%H:%M:%S.%N`"
             outarray=(${outarray[@]:1})
        fi
        if [[ $finishedPods -ge $(($TOTAL_POD_NUM-$final)) ]]; then
             echo "Final $final($finishedPods) SVC Running:            `date +%Y-%m-%d' '%H:%M:%S.%N`"
             finalarray=(${finalarray[@]:1})
        fi
    done
    echo "All vs Running:         `date +%Y-%m-%d' '%H:%M:%S.%N`"
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
        *)
            echo "unknown option: $1 $2"
            exit 1
            ;;
        esac
done

POD_TEMPLATE=`cat ${TEMPLATE_FILE} | sed "s/^[ \t]*//g"| sed ":a;N;s/\n//g;ta"`
pod=${POD_TEMPLATE//NAMESPACE/${NAMESPACE}}
pod=${pod//POD_NUM/${POD_NUM}}
echo "Test start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
createPods
TOTAL_POD_NUM=$(( DEPLOY_NUM ))
checkPodsRunning
echo "Test finished:           `date +%Y-%m-%d' '%H:%M:%S.%N`"
