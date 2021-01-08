
podserver_name=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].metadata.name}'`
podserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.podIP}'`
nodeserver_ip=`kubectl get pods --selector app=$server -o jsonpath='{.items[0].status.hostIP}'`

svc_ip=`kubectl get svc $service -ojsonpath='{.status.loadBalancer.ingress[0].ip}'`
svc_port=`kubectl get svc $service -ojsonpath='{.spec.ports[0].port}'`

currentTimeStamp=`date +%s.%2N`
python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip

currentTimeStamp=`date +%s.%2N`
sshpass -p Huawei@123 ssh -oStrictHostKeyChecking=no root@$nodec_ip<<END
./fortio load -qps $qps -c $connect -t 120s --keepalive=false http://$svc_ip:$svc_port
END

sleep 30

python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip

currentTimeStamp=`date +%s.%2N`
sshpass -p Huawei@123 ssh -oStrictHostKeyChecking=no root@$nodec_ip<<END
./fortio load -qps $qps -c $connect -t 120s http://$svc_ip:$svc_port
END

sleep 30

python query_csv.py $prometheus_url $currentTimeStamp $nodeserver_ip
python query_csv.py $prometheus_url $currentTimeStamp $nodeclient_ip


