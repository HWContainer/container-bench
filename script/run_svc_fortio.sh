namespace=$1
url=$2

pod_name=`kubectl get pods --selector app=fortio-1 -o jsonpath='{.items[0].metadata.name}'`
nodec_ip=`kubectl get pods --selector app=fortio-1 -o jsonpath='{.items[0].status.hostIP}'`
node_ip=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].status.hostIP}'`
currentTimeStamp=`date +%s.%2N`
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodec_ip
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /usr/bin/fortio load -qps 0 -c 16 -t 30s --keepalive=false $url
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodec_ip
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /usr/bin/fortio load -qps 0 -c 64 -t 30s --keepalive=false $url
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodec_ip
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /usr/bin/fortio load -qps 0 -c 16 -t 30s $url
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodec_ip
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /usr/bin/fortio load -qps 0 -c 64 -t 30s $url
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodec_ip
