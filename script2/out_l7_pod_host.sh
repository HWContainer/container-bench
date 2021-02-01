BASEDIR=$(dirname "$0")
sleep 60
nodeserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.podIP}'`

svc_ip=http://$nodeserver_ip bash $BASEDIR/out_invoker.sh
