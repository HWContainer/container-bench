#!/bin/bash

DEPLOY_NUM=1
POD_NUM=500
BASE_NAME=sina-test
NAMESPACE=sina-test

function checkPodsRunning(){
    pre_nodes=0
    pre_ready=0
    pre_taint=0
    pre_created=0
    pre_scheduled=0
    pre_running=0
    pre_completed=0
    pre_target=0
    pre_readys=0
    pre_binds=0
    pre_attaches=0
    target=0
    pre_eni=0
    pre_eni_prebound=0
    pre_eni_bound=0
    pre_subeni=0
    while [[ ! -f finish ]];do
        if [[ -f start ]]; then 
            echo "at `date +%Y-%m-%d' '%H:%M:%S.%N`: receive presure start"
            rm -f start
        fi
        if [[ -f stop ]]; then 
            echo "at `date +%Y-%m-%d' '%H:%M:%S.%N`: receive presure stop"
            rm -f stop
        fi
        allnode=`kubectl get nodes -ojsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\t"}{..taints}{"\n"}{end}'`
        nodes=`echo "$allnode" | grep -v "NAME" | wc -l`
        ready=`echo "$allnode" | grep -v "NAME" |grep -w True| wc -l`
        taint=`echo "$allnode" | grep -v "NAME" |grep -w True| grep -v map| wc -l`
        #target=`kubectl get hpa ${NAMESPACE} |grep ${BASE_NAME}|grep -oP '\d+%/'|grep -oP '\d+'` 
        alleni=`kubectl get pni -ojsonpath='{range .items[*]}{.metadata.name}{"\t"}{..labels}{"\t"}{.spec.securityGroup.defaultSecurityGroupIDs}{"\t"}{.status.securityGroupIDs}{"\t"}{.spec.securityGroup.securityGroupNames}{"\n"}{end}' -nkube-system`
        eni=`echo "$alleni" | grep -v master-eni| wc -l`
        eni_prebound=`echo "$alleni" | grep -v master-eni| grep -w PreBound|wc -l`
        eni_bound=`echo "$alleni" | grep -v master-eni| grep -w Bound|wc -l`
        subeni=`echo "$alleni" | grep master-eni| wc -l`

        binds=`echo "$alleni" |grep fron|wc -l`
        attaches=`echo "$alleni" |grep fron|awk '{if($3!=$4)print $1}' | wc -l`


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


        if [[ ${nodes} -ne ${pre_nodes} ]] || [[ ${ready} -ne ${pre_ready} ]] || [[ ${taint} -ne ${pre_taint} ]] || [[ ${running} -ne ${pre_running} ]] || [[ ${readys} -ne ${pre_readys} ]] || [[ ${pre_attaches} -ne ${attaches} ]] || [[ ${scheduled} -ne ${pre_scheduled} ]] || [[ ${created} -ne ${pre_created} ]] || [[ ${target} -ne ${pre_target} ]] || [[ ${completed} -ne ${pre_completed} ]] || [[ ${eni} -ne ${pre_eni} ]] || [[ ${subeni} -ne ${pre_subeni} ]] || [[ ${eni_prebound} -ne ${pre_eni_prebound} ]] || [[ ${eni_bound} -ne ${pre_eni_bound} ]] ; then
            echo "at `date +%Y-%m-%d' '%H:%M:%S.%N`: $nodes $ready $taint $eni $eni_prebound $eni_bound, $subeni $binds $attaches, $created $scheduled $running $readys $completed"
            pre_nodes=$nodes
            pre_ready=$ready
            pre_taint=$taint
            pre_running=$running
            pre_readys=$readys
            pre_binds=$binds
            pre_attaches=$attaches
            pre_scheduled=$scheduled
            pre_created=$created
            pre_completed=$completed
            pre_target=$target
            pre_eni=$eni
            pre_eni_prebound=$eni_prebound
            pre_eni_bound=$eni_bound
            pre_subeni=$subeni
        fi
    done
    echo "All pods Completed:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}
function getCostEach(){
    kubectl get events -ojson ${NAMESPACE} > curl-get-event.log
    kubectl get pods -ojson ${NAMESPACE} > curl-get-pods.log
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
echo "at <date>: nodes ready readytaint eni prebound bound, subeni bind attach, created sechuded running readys completed"
echo "---------------------------------------------"
checkPodsRunning
echo "Test finished:           `date +%Y-%m-%d' '%H:%M:%S.%N`"
sleep 5
getCostEach

