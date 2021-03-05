for i in 1 2 4 6 8 10 12 14 16 18 21; do
mkdir -p logs
make clean -f Makefile_network
make PODS=$i clients=perf servers=perf CONNECT=256 l7_lb.lbv3.container.perf -f Makefile_network
mv logs iptables-logs/lbv3-pod2vm-3v$i
done
