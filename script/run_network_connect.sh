
podserver_name=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].metadata.name}'`
podserver_ip=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].status.podIP}'`
nodeserver_ip=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].status.hostIP}'`

podclient_name=`kubectl get pods --selector app=perf-test-2 -o jsonpath='{.items[0].metadata.name}'`
nodeclient_ip=`kubectl get pods --selector app=perf-test-2 -o jsonpath='{.items[0].status.hostIP}'`

kubectl exec $podserver_name -- pkill netserver
kubectl exec $podclient_name -- pkill netperf
sleep 30
currentTimeStamp=`date +%s.%2N`
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
sleep 30


currentTimeStamp=`date +%s.%2N`
kubectl exec $podserver_name -- sh -c 'cd /home/paas; bash ./con_netserver.sh'
kubectl exec $podclient_name -- sh -c 'cd /home/paas; rm -f tcp_crr.log; sed -i "s/20/100/g" con_netperf.sh; bash ./con_netperf.sh '$podserver_ip
sleep 120
kubectl exec $podclient_name -- sh -c 'cd /home/paas; sed -i "s/20.00/100.00/g" con_collect.sh; bash ./con_collect.sh'

python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip

kubectl exec $podclient_name -- pkill netperf
kubectl exec $podserver_name -- pkill netserver

