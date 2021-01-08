node1=`kubectl get pods -l app=node-exporter-1 -ojsonpath="{range .items[*]}{..hostIP}{':32256,'}{..hostIP}{':32101,'}{end}"`

pod_name=`kubectl get pods --selector app=prometheus-server-1 -o jsonpath='{.items[0].metadata.name}'`
kubectl exec -ti $pod_name -- sed -i 's/targets: \[.*/targets: ['$node1']/g' /etc/prometheus/prometheus.yml
kubectl exec -ti $pod_name -- kill -HUP 1
