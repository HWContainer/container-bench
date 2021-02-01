
podserver_name=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].metadata.name}'`
podserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.podIP}'`
nodesserver_ip=`kubectl get pods -l app=$server -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"|tr ' ' '\n'|sort|uniq`

podsclient_name=`kubectl get pods -l app=$client -ojsonpath="{range .items[*]}{..metadata.name}{' '}{end}"|tr ' ' '\n'|sort|uniq`
nodesclient_ip=`kubectl get pods -l app=$client -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"|tr ' ' '\n'|sort|uniq`

sleep 60
currentTimeStamp=`date +%s.%2N`
sleep 60
for nodeserver_ip in $nodesserver_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
done
for nodeclient_ip in $nodesclient_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
done

currentTimeStamp=`date +%s.%2N`
for nodeclient_name in $podsclient_name; do
{
kubectl exec $podclient_name -- /usr/bin/fortio load -qps $qps -c $connect -t 120s --keepalive=false http://$server > $nodeclient_name.log
} &
done
wait
for nodeclient_name in $podsclient_name; do
cat $nodeclient_name.log
done
sleep 30

for nodeserver_ip in $nodesserver_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
done
for nodeclient_ip in $nodesclient_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
done

