function checkPodsCleaned(){
    finishedPods=1
    while [[ ${finishedPods} -ne 0 ]];do
        if [[ -f /tmp/debug ]]; then
            echo ${finishedPods} ${TOTAL_POD_NUM}
        fi
        ret=`kubectl -n ${NAMESPACE} get pod |grep ${BASE_NAME}| grep -v "NAME"`
        finishedPods=`echo "$ret" |grep ${BASE_NAME}| wc -l`
    done
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
checkPodsCleaned
