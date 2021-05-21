#!/bin/bash -x

to_delete=$1
to_check=$2
namespace=$3
prefix=$4

if kubectl get $to_delete -l created_by=perf-test  -l prefix=$prefix -o custom-columns=NAME:.metadata.name -n $namespace|grep -v NAME > /dev/null; then
        kubectl get $to_delete --no-headers=true -l created_by=perf-test  -l prefix=$prefix -o custom-columns=NAME:.metadata.name -n $namespace|xargs -t kubectl delete $to_delete -n $namespace --wait=false 2>/dev/null 1>&2
fi

while kubectl get $to_check -l created_by=perf-test -l prefix=$prefix -n $namespace |grep -v NAME > /dev/null; do
        sleep 0.1
done
