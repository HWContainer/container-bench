
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
kubectl exec $podserver_name -- sh -c 'cd /home/paas; sed -i "s/40032/40128/g" con_netserver.sh; bash ./con_netserver.sh 1>/log.netserver 2>&1'

i=0
for podclient_name in $podsclient_name; do
port_range="$((40000+$((i*64)))) $((39999+$(($((i+1))*64))))"
{ 
kubectl exec $podclient_name -- sh -c 'cd /home/paas; rm -f tcp_crr.log; sed -i "s/20/30/g" con_netperf.sh; sed -i "s/40000 40031/'"${port_range}"'/g" con_netperf.sh; bash ./con_netperf.sh '$podserver_ip 1>/log.netperf 2>&1 
} &
i=$((i+1))
done
wait

sleep 60

for podclient_name in $podsclient_name; do
kubectl exec $podclient_name -- sh -c 'cd /home/paas; sed -i "s/20.00/30.00/g" con_collect.sh; bash ./con_collect.sh'
done

python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
for nodeclient_ip in $nodesclient_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip
done

for podclient_name in $podsclient_name; do
kubectl exec $podclient_name -- pkill netperf
done
kubectl exec $podserver_name -- pkill netserver

