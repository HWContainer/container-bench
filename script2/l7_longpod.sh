
podserver_name=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].metadata.name}'`
podserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.podIP}'`
nodeserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.hostIP}'`

podsclient_name=`kubectl get pods -l app=$client -ojsonpath="{range .items[*]}{..metadata.name}{' '}{end}"|tr ' ' '\n'|sort|uniq`
nodesclient_ip=`kubectl get pods -l app=$client -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"|tr ' ' '\n'|sort|uniq`

sleep 60
currentTimeStamp=`date +%s.%2N`
sleep 60
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip

for nodeclient_ip in $nodesclient_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
done

currentTimeStamp=`date +%s.%2N`

for podclient_name in $podsclient_name; do
{
kubectl exec $podclient_name -- /usr/bin/fortio load -qps $qps -c $connect -t 120s  http://$podserver_ip > $podclient_name.log
} &
done
wait

for podclient_name in $podsclient_name; do
cat $podclient_name.log
done

sleep 30

python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip

for nodeclient_ip in $nodesclient_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
done
