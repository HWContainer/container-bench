url=$1
nodec_ip=$2
node=$3

node_ip=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].status.hostIP}'`
currentTimeStamp=`date +%s.%2N`
sshpass -p Huawei@123 ssh -oStrictHostKeyChecking=no root@$nodec_ip<<END
./fortio load -qps 0 -c 16 -t 30s --keepalive=false $url
END
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
python query_csv.py $prometheus_url $currentTimeStamp $node
currentTimeStamp=`date +%s.%2N`
sshpass -p Huawei@123 ssh -oStrictHostKeyChecking=no root@$nodec_ip<<END
./fortio load -qps 0 -c 64 -t 30s --keepalive=false $url
sleep 30
END
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
python query_csv.py $prometheus_url $currentTimeStamp $node
currentTimeStamp=`date +%s.%2N`
sshpass -p Huawei@123 ssh -oStrictHostKeyChecking=no root@$nodec_ip<<END
./fortio load -qps 0 -c 16 -t 30s $url
END
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
python query_csv.py $prometheus_url $currentTimeStamp $node
currentTimeStamp=`date +%s.%2N`
sshpass -p Huawei@123 ssh -oStrictHostKeyChecking=no root@$nodec_ip<<END
./fortio load -qps 0 -c 64 -t 30s $url
END
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
python query_csv.py $prometheus_url $currentTimeStamp $node

