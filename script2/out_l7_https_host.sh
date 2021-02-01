BASEDIR=$(dirname "$0")

sleep 60
svc_ip=https://`kubectl get ingress $service -ojsonpath='{.status.loadBalancer.ingress[0].ip}'` \
bash $BASEDIR/out_invoker.sh

