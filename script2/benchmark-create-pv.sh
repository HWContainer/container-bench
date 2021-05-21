#!/bin/bash

DEPLOY_NUM=1
POD_NUM=500
BASE_NAME=sina-test
NAMESPACE=sina-test
STORAGE=10Gi
CLASS=sas
REGION=
AZ=
VOLUMELIST=
TEMPLATE_FILE=pod.json
PIPE_COUNT=20
PASSWORD=`head /dev/urandom |cksum |md5sum |cut -c 1-30`
echo PASSWORD=$PASSWORD

function create_per_t(){
   id=$1
   kubectl apply -f pv-$PASSWORD$id/ --recursive
   rm -rf pv-$PASSWORD${id}
}

function gen_tpl(){
    p_id=$1
    f_id=$2
    volume_idx=$3
    pvName="${BASE_NAME}-${p_id}"
    f_pod=${pod//EVS_PVC_NAME/${pvName}}
    f_pod=${f_pod//EVS_PV_NAME/${pvName}}
    f_pod=${f_pod//VOLUMEID/${VOLUMELIST[$volume_idx]}}
    mkdir -p pv-$PASSWORD$f_id
    echo $f_pod > pv-$PASSWORD$f_id/${p_id}.json
}

function genPvs(){
    j=1
    k=0
    for i in $(seq 1 ${DEPLOY_NUM});do
        gen_tpl $i $j $k
        j=$(($j+1))
        k=$(($k+1))
        if [ $j -gt $PIPE_COUNT ] ; then
            j=1
        fi
    done
}
function createPvs(){
    if [[ $DEPLOY_NUM -gt $PIPE_COUNT ]]; then
        for i in $(seq 1 $PIPE_COUNT);do
            create_per_t ${i} &
        done
    else
        for i in $(seq 1 $DEPLOY_NUM);do
            create_per_t ${i} &
        done
    fi
}

function checkCreate(){
    finishedPods=0
    while [[ ${finishedPods} -ne ${TOTAL_NUM} ]];do
        finishedPods=`kubectl -n ${NAMESPACE} get pv | grep ${BASE_NAME}| grep -v "NAME"| wc -l`
    done
    echo "All pv created:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

function checkDone(){
    finishedPods=0
    while [[ ${finishedPods} -ne ${TOTAL_NUM} ]];do
        finishedPods=`kubectl -n ${NAMESPACE} get pv | grep ${BASE_NAME}| grep -v "NAME" | grep  "Available" | wc -l`
    done
    echo "All pv Available:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

SCRIPT=$(basename $0)
while test $# -gt 0; do
    case $1 in
        -h | --help)
            echo "${SCRIPT} - for create pod benchmark"
            echo " "
            echo "     options:"
            echo "     -h, --help            show brief help"
            echo "     --pv-num             set pv number to create. Default: 1"
            echo "     --name                set pod base name, will use this name and id to generate pod name. Default: sina-test"
            echo "     --namespace           set namespace to create pod, this namespace should already created. Default: sina-test"
            echo "     --template            the file path of pod template in json format"
            echo "     --pv-size            the pv or nfs storage size to create. Default: 10Gi"
            echo "     --volumes             the volume list. Default: "
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
        --region)
            REGION=${2}
            shift 2
            ;;
        --az)
            AZ=${2}
            shift 2
            ;;
        --pv-size)
            STORAGE=${2}
            shift 2
            ;;
        --pv-num)
            DEPLOY_NUM=${2}
            shift 2
            ;;
        --volumes)
            VOLUMELIST=(`cat ${2}`)
            shift 2
            ;;
        *)
            echo "unknown option: $1 $2"
            exit 1
            ;;
        esac
done

if cat ${TEMPLATE_FILE}|grep VOLUMEID>/dev/null; then
  if (! [[ -z VOLUMELIST ]]) && [[ ${#VOLUMELIST[@]} -lt $DEPLOY_NUM ]]; then
    echo "not enough volume"
    exit 1
  fi
fi

#POD_TEMPLATE=`cat ${TEMPLATE_FILE} | sed "s/^[ \t]*//g"| sed ":a;N;s/\n//g;ta"`
POD_TEMPLATE=`python pys/fix_pv.py --template ${TEMPLATE_FILE}  --prefix=${BASE_NAME}`
pod=${POD_TEMPLATE//NAMESPACE/${NAMESPACE}}
pod=${pod//STORAGE/${STORAGE}}
pod=${pod//CLASS/${CLASS}}
pod=${pod//REGION/${REGION}}
pod=${pod//AZ/${AZ}}
genPvs
echo "Test start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
createPvs
TOTAL_NUM=$(( DEPLOY_NUM * 1 ))
checkCreate
checkDone
echo "Test finished:           `date +%Y-%m-%d' '%H:%M:%S.%N`"

