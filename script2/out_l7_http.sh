sleep 60
nodes=`kubectl get pods -l app=$server -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"|tr ' ' '\n'|sort|uniq`

svc_ip=`kubectl get ingress $service -ojsonpath='{.status.loadBalancer.ingress[0].ip}'`
currentTimeStamp=`date +%s.%2N`
sleep 60
for node in $nodes; do
python query_csv.py $prometheus_url $currentTimeStamp $node
done

currentTimeStamp=`date +%s.%2N`
if [[ "$nodec_ip" == "127.0.0.1" ]]; then
fortio load -qps $qps -c $connect -t 120s --keepalive=false $svc_ip
else
sshpass -p Huawei@123 ssh -oStrictHostKeyChecking=no root@$nodec_ip<<END
fortio load -qps $qps -c $connect -t 120s --keepalive=false $svc_ip
END
fi

for node in $nodes; do
python query_csv.py $prometheus_url $currentTimeStamp $node
done
sleep 60

currentTimeStamp=`date +%s.%2N`
if [[ "$nodec_ip" == "127.0.0.1" ]]; then
fortio load -qps $qps -c $connect -t 120s $svc_ip
else
sshpass -p Huawei@123 ssh -oStrictHostKeyChecking=no root@$nodec_ip<<END
fortio load -qps $qps -c $connect -t 120s $svc_ip
END
fi

for node in $nodes; do
python query_csv.py $prometheus_url $currentTimeStamp $node
done
