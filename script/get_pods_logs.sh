namespace=$1
echo "" >/tmp/curl-get-realstart.log
kubectl get pods -n $namespace -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl logs {} -n $namespace >> /tmp/curl-get-realstart.log
