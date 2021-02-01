BASEDIR=$(dirname "$0")
sleep 60
svc_ip=`kubectl get svc $service -ojsonpath='{.status.loadBalancer.ingress[0].ip}'`
svc_port=`kubectl get svc $service -ojsonpath='{.spec.ports[0].port}'`

svc_ip=http://$svc_ip:$svc_port bash $BASEDIR/out_invoker.sh

