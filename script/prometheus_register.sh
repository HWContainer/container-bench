ns=${namespace:-default}
node1=`kubectl get pods -n $ns -l app=node-exporter-1 -ojsonpath="{range .items[*]}{..hostIP}{':32256,'}{..hostIP}{':32101,'}{end}"`
node2=`echo $nodec_ip|tr ' ' '\n'|xargs -i echo -n {}:32256,{}:32101,`

pod_name=`kubectl get pods -n $ns --selector app=prometheus-server-1 -o jsonpath='{.items[0].metadata.name}'`
kubectl exec -ti $pod_name -n $ns -- sed -i 's/targets: \[.*/targets: ['$node1$node2']/g' /etc/prometheus/prometheus.yml
kubectl exec -ti $pod_name -n $ns -- kill -HUP 1
