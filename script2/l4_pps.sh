
podserver_name=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].metadata.name}'`
podserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.podIP}'`
nodeserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.hostIP}'`

podclient_name=`kubectl get pods --selector app=$client -o jsonpath='{.items[0].metadata.name}'`
nodeclient_ip=`kubectl get pods --selector app=$client -o jsonpath='{.items[0].status.hostIP}'`

kubectl exec $podserver_name -- sh -c 'pkill bash; pkill iperf'
kubectl exec $podclient_name -- pkill iperf
currentTimeStamp=`date +%s.%2N`
sleep 60
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip


currentTimeStamp=`date +%s.%2N`
kubectl exec $podserver_name -- sh -c 'cd /home/paas; bash ./pps_server_iperf.sh 1>/logs.iperf 2>&1; bash ./get_pps.sh eth0 1>pps.log 2>&1 &'
kubectl exec $podclient_name -- sh -c 'cd /home/paas; bash ./pps_client_iperf.sh '$podserver_ip' 1>/logs.iperf 2>&1'
sleep 120

python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip


kubectl exec $podserver_name -- sh -c 'pkill bash; pkill iperf'
kubectl exec $podclient_name -- pkill iperf
kubectl exec $podserver_name -- sh -c 'cd /home/paas; cat pps.log'


