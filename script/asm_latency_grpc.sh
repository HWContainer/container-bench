namespace=$1
url=$2

export KUBECONFIG=$default_cluster
pod_name=`kubectl get pods --selector app=asm-client-1 -o jsonpath='{.items[0].metadata.name}'`
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /usr/bin/fortio load -qps 1000 -c 8 -t 30s -grpc -ping $url
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /usr/bin/fortio load -qps 1000 -c 16 -t 30s -grpc -ping $url
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /usr/bin/fortio load -qps 1000 -c 32 -t 30s -grpc -ping $url
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /usr/bin/fortio load -qps 1000 -c 64 -t 30s -grpc -ping $url
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /usr/bin/fortio load -qps 500 -c 16 -t 30s -grpc -ping $url
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /usr/bin/fortio load -qps 2000 -c 16 -t 30s -grpc -ping $url
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /usr/bin/fortio load -qps 4000 -c 16 -t 30s -grpc -ping $url
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp

