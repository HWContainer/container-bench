cd /root/container-bench
a=`KUBECONFIG=/root/.kube/config.115 bash examples/autoscaler/judge.sh`
if [ "$a" == "goon" ]; then
KUBECONFIG=/root/.kube/config.115 make deploy.perf-density.perf-test.data:true.1.0 -f Makefile_network >> down_115.log &
else
echo "`date +%Y-%m-%d' '%H:%M:%S.%N` $a" >> error_115.log
fi

a=`KUBECONFIG=/root/.kube/config.117 bash examples/autoscaler/judge.sh`
if [ "$a" == "goon" ]; then
KUBECONFIG=/root/.kube/config.117 make deploy.perf-density.perf-test.data:true.1.0 -f Makefile_network >> down_117.log &
else
echo "`date +%Y-%m-%d' '%H:%M:%S.%N` $a" >> error_117.log
fi

a=`KUBECONFIG=/root/.kube/config.119 bash examples/autoscaler/judge.sh`
if [ "$a" == "goon" ]; then
KUBECONFIG=/root/.kube/config.119 make deploy.perf-density.perf-test.data:true.1.0 -f Makefile_network >> down_119.log &
else
echo "`date +%Y-%m-%d' '%H:%M:%S.%N` $a" >> error_119.log
fi
