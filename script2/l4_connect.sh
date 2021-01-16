
podserver_name=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].metadata.name}'`
podserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.podIP}'`
nodeserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.hostIP}'`

podclient_name=`kubectl get pods --selector app=$client -o jsonpath='{.items[0].metadata.name}'`
nodeclient_ip=`kubectl get pods --selector app=$client -o jsonpath='{.items[0].status.hostIP}'`

currentTimeStamp=`date +%s.%2N`
sleep 60
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip

currentTimeStamp=`date +%s.%2N`
kubectl exec $podserver_name -- sh -c 'cd /home/paas; bash ./con_netserver.sh 1>/log.netserver 2>&1'
kubectl exec $podclient_name -- sh -c 'cd /home/paas; rm -f tcp_crr.log; sed -i "s/20/100/g" con_netperf.sh; bash ./con_netperf.sh '$podserver_ip 1>/log.netperf 2>&1
sleep 120
kubectl exec $podclient_name -- sh -c 'cd /home/paas; sed -i "s/20.00/100.00/g" con_collect.sh; bash ./con_collect.sh'

python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip

kubectl exec $podclient_name -- pkill netperf
kubectl exec $podserver_name -- pkill netserver


