namespace=$1
echo "" >curl-get-realstart.log
kubectl get pods -n $namespace -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl logs {} -n $namespace >> curl-get-realstart.log
