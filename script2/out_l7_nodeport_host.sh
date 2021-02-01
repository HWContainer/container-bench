BASEDIR=$(dirname "$0")
sleep 60
nodeserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.hostIP}'`
svc_port=`kubectl get svc $service -ojsonpath='{.spec.ports[0].nodePort}'`

svc_ip=http://$nodeserver_ip:$svc_port bash $BASEDIR/out_invoker.sh 
