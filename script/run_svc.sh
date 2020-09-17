currentTimeStamp=`date +%s.%2N`
sleep 120
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
currentTimeStamp=`date +%s.%2N`
make 2000svc
sleep 300
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
currentTimeStamp=`date +%s.%2N`
sleep 120
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
currentTimeStamp=`date +%s.%2N`
kubectl get svc -n $namespace -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete svc -n $namespace --ignore-not-found=true --wait=true {}
sleep 60
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
