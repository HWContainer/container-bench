sleep 60
nodes=`kubectl get pods -l app=$server -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"|tr ' ' '\n'|sort|uniq`
nodeserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.hostIP}'`

svc_port=`kubectl get svc $service -ojsonpath='{.spec.ports[0].nodePort}'`

currentTimeStamp=`date +%s.%2N`
sleep 60
for node in $nodes; do
python query_csv.py $prometheus_url $currentTimeStamp $node
done

currentTimeStamp=`date +%s.%2N`
if [[ "$nodec_ip" == "127.0.0.1" ]]; then
fortio load -qps $qps -c $connect -t 120s --keepalive=false http://$nodeserver_ip:$svc_port
else
sshpass -p Huawei@123 ssh -oStrictHostKeyChecking=no root@$nodec_ip<<END
fortio load -qps $qps -c $connect -t 120s --keepalive=false http://$nodeserver_ip:$svc_port
END
fi

for node in $nodes; do
python query_csv.py $prometheus_url $currentTimeStamp $node
done
sleep 60

currentTimeStamp=`date +%s.%2N`
if [[ $nodec_ip == "127.0.0.1" ]]; then
fortio load -qps $qps -c $connect -t 120s http://$nodeserver_ip:$svc_port
else
sshpass -p Huawei@123 ssh -oStrictHostKeyChecking=no root@$nodec_ip<<END
fortio load -qps $qps -c $connect -t 120s http://$nodeserver_ip:$svc_port
END
fi

for node in $nodes; do
python query_csv.py $prometheus_url $currentTimeStamp $node
done
