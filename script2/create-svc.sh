#!/bin/bash

SVC_NUM=1
APP_NUM=1
BASE_NAME=sina-test
APP_NAME=x
NAMESPACE=sina-test
TEMPLATE_FILE=pod.json
PIPE_COUNT=20
PASSWORD=`head /dev/urandom |cksum |md5sum |cut -c 1-30`
echo PASSWORD=$PASSWORD

function createDeploy(){
    id=$1
    kubectl apply -f svc-$PASSWORD$id/ --recursive
    rm -rf svc-$PASSWORD${id}
}
function gen_svc(){
    p_id=$1
    f_id=$2
    d_idx=$3
    svcName="${BASE_NAME}-${p_id}"
    if [[ $APP_NAME == 'x' ]]; then
        APP_NAME=$BASE_NAME
    fi
    deployName="${APP_NAME}-${d_idx}"
    f_pod=${pod//POD_NAME/${deployName}}
    f_pod=${f_pod//SVC_NAME/${svcName}}
    mkdir -p svc-$PASSWORD$f_id
    echo $f_pod > svc-$PASSWORD$f_id/${p_id}.json
}

function createSvcs(){
    j=1
    d=1
    for i in $(seq 1 ${SVC_NUM});do
        gen_svc $i $j $d
        j=$(($j+1))
        d=$(($d+1))
        if [ $j -gt $PIPE_COUNT ] ; then
            j=1
        fi
        if [ $j -gt $APP_NUM ] ; then
            d=1
        fi
    done
    if [[ $SVC_NUM -gt $PIPE_COUNT ]]; then
        for i in $(seq 1 $PIPE_COUNT);do
            createDeploy ${i} &
        done
    else
        for i in $(seq 1 $SVC_NUM);do
            createDeploy ${i} &
        done
    fi
}

SCRIPT=$(basename $0)
while test $# -gt 0; do
    case $1 in
        -h | --help)
            echo "${SCRIPT} - for create pod benchmark"
            echo " "
            echo "     options:"
            echo "     -h, --help            show brief help"
            echo "     --svc-num             set service number to create. Default: 1"
            echo "     --app-num             set apps number to select. Default: 1"
            echo "     --name                set svc base name, will use this name and id to generate pod name. Default: sina-test"
            echo "     --app                 set app base name, will use this name and id to generate pod name. Default: sina-test"
            echo "     --az                  set az name, will use this name and id to lb instance az. Default: sina-test"
            echo "     --namespace           set namespace to create pod, this namespace should already created. Default: sina-test"
            echo "     --template            the file path of pod template in json format"
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
        --svc-num)
            SVC_NUM=${2}
            shift 2
            ;;
        --app)
            APP_NAME=${2}
            shift 2
            ;;
        --az)
            AZ_NAME=${2}
            shift 2
            ;;
        --app-num)
            APP_NUM=${2}
            shift 2
            ;;
        *)
            echo "unknown option: $1 $2"
            exit 1
            ;;
        esac
done

POD_TEMPLATE=`cat ${TEMPLATE_FILE} | sed "s/^[ \t]*//g"| sed ":a;N;s/\n//g;ta"`
POD_TEMPLATE=`python pys/fix_svc.py --template ${TEMPLATE_FILE}`
pod=${POD_TEMPLATE//NAMESPACE/${NAMESPACE}}
pod=${pod//AZ_NAME/${AZ_NAME}}
echo "Test start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
createSvcs
sleep 1
echo "Test finished:           `date +%Y-%m-%d' '%H:%M:%S.%N`"

