
podserver_name=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].metadata.name}'`
podserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.podIP}'`
nodeserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.hostIP}'`

podsclient_name=`kubectl get pods -l app=$client -ojsonpath="{range .items[*]}{..metadata.name}{' '}{end}"|tr ' ' '\n'|sort|uniq`
nodesclient_ip=`kubectl get pods -l app=$client -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"|tr ' ' '\n'|sort|uniq`

if [[ -z "${FAST}" ]]; then
sleep 60
currentTimeStamp=`date +%s.%2N`
sleep 60
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
for nodeclient_ip in $nodesclient_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
done
fi

currentTimeStamp=`date +%s.%2N`
count=256
kubectl exec $podserver_name -- bash -c 'rm -f log.*; for ((i=40000; i<'$((count+40000))';i++)); do { /home/paas/netserver -p $i >/log.$i 2>&1; }& done'
sleep 10
i=0
for podclient_name in $podsclient_name; do
port_start=$((40000+$((i*128))))
port_stop=$((40000+$(($((i+1))*128))))
{
kubectl exec $podclient_name -- bash -c 'rm -f log.*; for ((i='$port_start'; i<'$port_stop';i++)); do { /home/paas/netperf -t TCP_CRR -H '$podserver_ip' -l 20 -p $i -- -r 64 > /log.$i 2>&1; }& done; wait;'
}&
i=$((i+1))
done
wait

for podclient_name in $podsclient_name; do
kubectl exec $podclient_name -- sh -c 'cat log.*'|grep 20.0|awk '{print $6}'|awk '{sum+=$1}; END {print sum}'
done

if [[ -z "${FAST}" ]]; then
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
for nodeclient_ip in $nodesclient_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
done
fi

for podclient_name in $podsclient_name; do
kubectl exec $podclient_name -- pkill netperf
done
kubectl exec $podserver_name -- pkill netserver

