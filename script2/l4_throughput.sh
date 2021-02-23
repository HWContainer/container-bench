
podserver_name=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].metadata.name}'`
podserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.podIP}'`
nodeserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.hostIP}'`

podclient_name=`kubectl get pods --selector app=$client -o jsonpath='{.items[0].metadata.name}'`
nodeclient_ip=`kubectl get pods --selector app=$client -o jsonpath='{.items[0].status.hostIP}'`

if [[ -z "${FAST}" ]]; then
sleep 60
currentTimeStamp=`date +%s.%2N`
sleep 60
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
fi

currentTimeStamp=`date +%s.%2N`
count=10
kubectl exec $podserver_name -- bash -c 'rm log.*; for ((i=6000; i<'$((count+6000))';i++)); do { /home/paas/netserver -p $i >/log.$i 2>&1; }& done'
sleep 10
kubectl exec $podclient_name -- bash -c 'rm log.*; for ((i=6000; i<'$((count+6000))';i++)); do { /home/paas/netperf -t TCP_STREAM -H '$podserver_ip' -l 180 -p $i -- -r 1024 > /log.$i 2>&1; }& done; wait;'

if [[ -z "${FAST}" ]]; then
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
fi
kubectl exec $podserver_name -- sh -c 'pkill iperf;'
kubectl exec $podclient_name -- sh -c 'cat log.*'|grep 180.0|awk '{print $5}'|awk '{sum+=$1}; END {print sum}'


