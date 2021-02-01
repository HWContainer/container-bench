
mkdir -p logs
#make CONNECT=256 PODS=1 servers=perf outtest -f Makefile_network
#make clean -f Makefile_network

make CONNECT=256 PODS=1 servers=perf clients=perf l7test -f Makefile_network
make clean -f Makefile_network

mv logs logs_container

mkdir -p logs
make CONNECT=256 PODS=1 servers=perf outtest_host -f Makefile_network
make clean -f Makefile_network

make CONNECT=256 PODS=1 servers=perf clients=perf l7hosttest -f Makefile_network
make clean -f Makefile_network

mv logs logs_host

mkdir -p logs
make CONNECT=256 PODS=21 servers=perf outtest -f Makefile_network
make clean -f Makefile_network

make CONNECT=256 PODS=21 servers=perf l7test -f Makefile_network
make clean -f Makefile_network

mv logs logs_container_21
