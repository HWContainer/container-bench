
podserver_name=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].metadata.name}'`
podserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.podIP}'`
nodeserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.hostIP}'`

podclient_name=`kubectl get pods --selector app=$client -o jsonpath='{.items[0].metadata.name}'`
nodeclient_ip=`kubectl get pods --selector app=$client -o jsonpath='{.items[0].status.hostIP}'`
sleep 60
currentTimeStamp=`date +%s.%2N`
sleep 60
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip

currentTimeStamp=`date +%s.%2N`
kubectl exec $podclient_name -- /usr/bin/fortio load -qps $qps -c $connect -t 120s  http://$server
sleep 30

python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip


