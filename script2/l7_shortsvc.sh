ns=${namespace:-default}
svc=${service:-server-perf-1}
svc_ip=`kubectl get svc -n $ns $svc -o jsonpath='{..clusterIP}'`
nodesserver_ip=`kubectl get pods -n $ns -l app=$server -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"|tr ' ' '\n'|sort|uniq`

podsclient_name=`kubectl get pods -n $ns -l app=$client -ojsonpath="{range .items[*]}{..metadata.name}{' '}{end}"|tr ' ' '\n'|sort|uniq`
nodesclient_ip=`kubectl get pods -n $ns -l app=$client -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"|tr ' ' '\n'|sort|uniq`

if [[ -z "${FAST}" ]]; then
sleep 60
currentTimeStamp=`date +%s.%2N`
sleep 60
for nodeserver_ip in $nodesserver_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
done
for nodeclient_ip in $nodesclient_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
done
fi
currentTimeStamp=`date +%s.%2N`
for podclient_name in $podsclient_name; do
{
kubectl exec $podclient_name -n $ns -- /usr/bin/fortio load -qps $qps -c $connect -t 120s --keepalive=false http://$svc_ip > $podclient_name.log 2>&1
} &
done
wait
for podclient_name in $podsclient_name; do
cat $podclient_name.log
done
if [[ -z "${FAST}" ]]; then
sleep 30

for nodeserver_ip in $nodesserver_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
done
for nodeclient_ip in $nodesclient_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
done
fi
