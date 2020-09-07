
podserver_name=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].metadata.name}'`
podserver_ip=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].status.podIP}'`
nodeserver_ip=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].status.hostIP}'`

podclient_name=`kubectl get pods --selector app=fortio-1 -o jsonpath='{.items[0].metadata.name}'`
nodeclient_ip=`kubectl get pods --selector app=fortio-1 -o jsonpath='{.items[0].status.hostIP}'`

sleep 30
currentTimeStamp=`date +%s.%2N`
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
sleep 30

currentTimeStamp=`date +%s.%2N`
kubectl exec $podclient_name -- /usr/bin/fortio load -qps 0 -c 64 -t 120s --keepalive=false http://$podserver_ip

python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip

