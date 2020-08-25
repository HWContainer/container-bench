namespace=$1
url=$2

pod_name=`kubectl get pods --selector app=fortio-1 -o jsonpath='{.items[0].metadata.name}'`
kubectl exec $pod_name -- /usr/bin/fortio load -qps 0 -c 16 -t 30s --keepalive=false $url
sleep 30
kubectl exec $pod_name -- /usr/bin/fortio load -qps 0 -c 32 -t 30s --keepalive=false $url
sleep 30
kubectl exec $pod_name -- /usr/bin/fortio load -qps 0 -c 64 -t 30s --keepalive=false $url
sleep 30
kubectl exec $pod_name -- /usr/bin/fortio load -qps 0 -c 16 -t 30s $url
sleep 30
kubectl exec $pod_name -- /usr/bin/fortio load -qps 0 -c 32 -t 30s $url
sleep 30
kubectl exec $pod_name -- /usr/bin/fortio load -qps 0 -c 64 -t 30s $url
sleep 30

