for i in 1 10 20 30 50 100 200; do
echo "deploying" $i
make deploy.perf-density.perf-test.metrics:true.1.$i -f Makefile_network
make clean -f Makefile_network
sleep 5
done
