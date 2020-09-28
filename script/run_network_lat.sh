
podserver_name=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].metadata.name}'`
podserver_ip=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].status.podIP}'`
nodeserver_ip=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].status.hostIP}'`

podclient_name=`kubectl get pods --selector app=perf-test-2 -o jsonpath='{.items[0].metadata.name}'`
nodeclient_ip=`kubectl get pods --selector app=perf-test-2 -o jsonpath='{.items[0].status.hostIP}'`

kubectl exec $podserver_name -- pkill qperf
kubectl exec $podclient_name -- pkill qperf
sleep 60
currentTimeStamp=`date +%s.%2N`
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip


currentTimeStamp=`date +%s.%2N`
kubectl exec $podserver_name -- sh -c 'cd /home/paas; ./qperf >/log.qperf 2>&1 &'
kubectl exec $podclient_name -- sh -c 'cd /home/paas; bash ./lat_qperf.sh '$podserver_ip
sleep 120

kubectl exec $podserver_name -- pkill qperf
kubectl exec $podclient_name -- pkill qperf
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip


