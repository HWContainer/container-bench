#!/bin/bash

DEPLOY_NUM=1
POD_NUM=500
BASE_NAME=sina-test
NAMESPACE=sina-test

function checkPodsRunning(){
    pre_created=0
    pre_scheduled=0
    pre_running=0
    pre_completed=0
    pre_readys=0
    while [[ ! -f finish ]];do
        if [[ -f start ]]; then 
            echo "at `date +%Y-%m-%d' '%H:%M:%S.%N`: receive presure start"
            rm -f start
        fi
        if [[ -f stop ]]; then 
            echo "at `date +%Y-%m-%d' '%H:%M:%S.%N`: receive presure stop"
            rm -f stop
        fi

        ret=`kubectl get pod ${NAMESPACE} | grep ${BASE_NAME}| grep -v "NAME"`
        
        finishedPods=`echo "$ret" |grep ${BASE_NAME} | wc -l`
        created=$finishedPods

        finishedPods=`echo "$ret" |grep ${BASE_NAME}|  grep -v "Pending"| wc -l`
        scheduled=$finishedPods

        finishedPods=`echo "$ret" | grep ${BASE_NAME}| grep -e "Running"| wc -l`
        running=$finishedPods

        readyPods=`echo "$ret" | grep ${BASE_NAME}| grep -e "1/1"| wc -l`
        readys=$readyPods
        
        finishedPods=`echo "$ret" | grep ${BASE_NAME}| grep -e "Running" -e "Completed"| wc -l`
        completed=$finishedPods


        if [[ ${running} -ne ${pre_running} ]] || [[ ${readys} -ne ${pre_readys} ]] || [[ ${scheduled} -ne ${pre_scheduled} ]] || [[ ${created} -ne ${pre_created} ]] || [[ ${completed} -ne ${pre_completed} ]]; then
            echo "at `date +%Y-%m-%d' '%H:%M:%S.%N`: $created $scheduled $running $readys $completed"
            pre_running=$running
            pre_readys=$readys
            pre_scheduled=$scheduled
            pre_created=$created
            pre_completed=$completed
        fi
    done
    echo "All pods Completed:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
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
echo $NAMESPACE
if [[ $NAMESPACE == 'A' ]]
then
    NAMESPACE="-A"
else
    NAMESPACE="-n $NAMESPACE"
fi
date +%Y-%m-%d' '%H:%M:%S > begin
echo "Test start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
echo "namespace: $NAMESPACE"
echo "      app: $BASE_NAME"
echo "at <date>: created sechuded running readys completed"
echo "---------------------------------------------"
checkPodsRunning
echo "Test finished:           `date +%Y-%m-%d' '%H:%M:%S.%N`"

