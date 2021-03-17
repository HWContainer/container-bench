#!/bin/bash

DEPLOY_NUM=1
POD_NUM=1
BASE_NAME=
NAMESPACE=
TEMPLATE_FILE=
SG_LIST=
DEFAULT_SG=
SELECT=""
PIPE_COUNT=20
PASSWORD=`head /dev/urandom |cksum |md5sum |cut -c 1-30`
echo PASSWORD=$PASSWORD

function create_sg(){
    id=$1
    kubectl apply -f sg-$PASSWROD$id/ --recursive
    rm -rf sg-$PASSWROD${id}
}

function gen_sg(){
    p_id=$1
    f_id=$2
    sg_idx=$3
    sgName="${BASE_NAME}-${p_id}"
    f_sg=${sg//\$\{name\}/${sgName}}
    f_sg=${f_sg//\$\{security_group_id\}/${SG_LIST[$sg_idx]}}
    mkdir -p sg-$PASSWROD$f_id
    echo $f_sg > sg-$PASSWROD$f_id/${p_id}.json
}

function genPods(){
    j=1
    k=0
    num=${#SG_LIST[@]}
    for i in $(seq 1 ${DEPLOY_NUM});do
        gen_sg $i $j $k
        j=$(($j+1))
        k=$(($k+1))
        if [ $j -gt $PIPE_COUNT ] ; then
            j=1
        fi
        if [ $k -ge $num ]; then
            k=0
        fi
    done
}
function createPods(){
    if [[ $DEPLOY_NUM -gt $PIPE_COUNT ]]; then
        for i in $(seq 1 $PIPE_COUNT);do
            create_sg ${i} &
        done
    else
        for i in $(seq 1 $DEPLOY_NUM);do
            create_sg ${i} &
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
        if [[ -f debug ]]; then
            echo ${finishedPods} ${TOTAL_POD_NUM}
        fi
        first=${outarray[0]}
        final=${finalarray[0]}
        ret=`kubectl -n ${NAMESPACE} get sg | grep ${BASE_NAME}- | grep -v "NAME"`
        
        finishedPods=`echo "$ret" |grep ${BASE_NAME} | wc -l`
        if [[ ${finishedPods} -eq ${TOTAL_POD_NUM} ]]; then
            echo "All sg created:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
        fi
    done
    echo "All sg Completed:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

function get_default_sg() {
    DEFAULT_SG=`kubectl get pni -ojsonpath='{.items[0].spec.securityGroup.defaultSecurityGroupIDs}' -nkube-system`
}

SCRIPT=$(basename $0)
while test $# -gt 0; do
    case $1 in
        -h | --help)
            echo "${SCRIPT} - for create sg benchmark"
            echo " "
            echo "     options:"
            echo "     -h, --help            show brief help"
            echo "     --sg-num              set sg number to create. Default: 1"
            echo "     --name                set sg base name, will use this name and id to generate sg name. Default: sina-test"
            echo "     --namespace           set namespace to create sg, this namespace should already created. Default: sina-test"
            echo "     --template            the file path of sg template in json format"
            echo "     --sg-list             the file path of vpc sg guid list"
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
        --sg-num)
            DEPLOY_NUM=${2}
            shift 2
            ;;
        --sg-list)
            SG_LIST=(`cat ${2}`)
            shift 2
            ;;
        *)
            echo "unknown option: $1 $2"
            exit 1
            ;;
        esac
done

num=${#SG_LIST[@]}
get_default_sg
if [[ -z $num ]] || [[ -z $DEFAULT_SG ]]; then
   echo "--sg-list --default-sg is empty"
   exit 1
fi
POD_TEMPLATE=`python pys/fix_svc.py --template ${TEMPLATE_FILE}`
sg=${POD_TEMPLATE//\$\{namespace\}/${NAMESPACE}}
sg=${sg//\$\{default_security_group_id\}/${DEFAULT_SG}}
genPods
date +%Y-%m-%d' '%H:%M:%S > begin
sleep 1
echo "Test start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
createPods
TOTAL_POD_NUM=$(( DEPLOY_NUM * POD_NUM ))
checkPodsRunning
echo "Test finished:           `date +%Y-%m-%d' '%H:%M:%S.%N`"
