#!/bin/bash

DEPLOY_NUM=1
POD_NUM=500
BASE_NAME=sina-test
NAMESPACE=sina-test
STORAGE=10Gi
TEMPLATE_FILE=pod.json
PIPE_COUNT=20
PASSWORD=`head /dev/urandom |cksum |md5sum |cut -c 1-30`
echo PASSWORD=$PASSWORD

function createPvc(){
   id=$1
   kubectl apply -f pvc-$PASSWORD$id/ --recursive
   rm -rf pvc-$PASSWORD${id}
}

function gen_pod(){
    p_id=$1
    f_id=$2
    podName="${BASE_NAME}-${p_id}"
    f_pod=${pod//EVS_PVC_NAME/${podName}}
    f_pod=${f_pod//AZ/${az}}
    mkdir -p pvc-$PASSWORD$f_id
    echo $f_pod > pvc-$PASSWORD$f_id/${p_id}.json
}

function genPods(){
    j=1
    for i in $(seq 1 ${DEPLOY_NUM});do
        gen_pod $i $j
        j=$(($j+1))
        if [ $j -gt $PIPE_COUNT ] ; then
            j=1
        fi
    done
}
function createPods(){
    if [[ $DEPLOY_NUM -gt $PIPE_COUNT ]]; then
        for i in $(seq 1 $PIPE_COUNT);do
            createPvc ${i} &
        done
    else
        for i in $(seq 1 $DEPLOY_NUM);do
            createPvc ${i} &
        done
    fi
}

function checkPodsCreate(){
    finishedPods=0
    while [[ ${finishedPods} -ne ${TOTAL_POD_NUM} ]];do
        finishedPods=`kubectl -n ${NAMESPACE} get pvc | grep ${BASE_NAME}| grep -v "NAME"| wc -l`
    done
    echo "All pvc created:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

function checkPodsRunning(){
    finishedPods=0
    while [[ ${finishedPods} -ne ${TOTAL_POD_NUM} ]];do
        finishedPods=`kubectl -n ${NAMESPACE} get pvc | grep ${BASE_NAME}| grep -v "NAME" | grep  "Bound" | wc -l`
    done
    echo "All pvc Bound:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
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
            echo "     --name                set pod base name, will use this name and id to generate pod name. Default: sina-test"
            echo "     --namespace           set namespace to create pod, this namespace should already created. Default: sina-test"
            echo "     --pod-template        the file path of pod template in json format"
            echo "     --storage             the pvc or nfs storage size to create. Default: 10Gi"
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
        --template)
            TEMPLATE_FILE=${2}
            shift 2
            ;;
        --pvc-size)
            STORAGE=${2}
            shift 2
            ;;
        --pvc-num)
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
pod=${pod//STORAGE/${STORAGE}}
genPods
echo "Test start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
createPods
TOTAL_POD_NUM=$(( DEPLOY_NUM * 1 ))
checkPodsCreate
checkPodsRunning
echo "Test finished:           `date +%Y-%m-%d' '%H:%M:%S.%N`"
