svc_ip=`kubectl get svc -l app=coredns -n kube-system  -o=jsonpath='{range .items[*]}{..spec.clusterIP}{end}'`
pod_name=`kubectl get pod -l app=dns-test-1 -o=jsonpath='{range .items[*]}{..metadata.name}{end}'`
kubectl exec -ti $pod_name  --  dnsperf -Q 40000 -c 40000 -l 120 -d testfile -s $svc_ip > dnsperf.log 2>&1
