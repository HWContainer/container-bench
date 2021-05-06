cd /root/scaler_test
make cert.test-cce
rm /root/.kube/config -f
cp doc/clustercert.json /root/.kube/config

cd /root/container-bench
make regist -f Makefile_network
make clean -f Makefile_network

bash examples/singlepod/shortrun.sh
mkdir -p /root/vpc-ipvs-server-20000
mv /root/container-bench/logs/short*  /root/vpc-ipvs-server-20000/

HALF=true bash examples/singlepod/shortrun.sh
mkdir -p /root/vpc-ipvs-client-20000
mv /root/container-bench/logs/short*  /root/vpc-ipvs-client-20000/


cd /root/scaler_test
make cert.test-cce-iptables
rm /root/.kube/config -f
cp doc/clustercert.json /root/.kube/config

cd /root/container-bench
make regist -f Makefile_network
make clean -f Makefile_network

bash examples/singlepod/shortrun.sh
mkdir -p /root/vpc-iptables-server-20000
mv /root/container-bench/logs/short*  /root/vpc-iptables-server-20000/

HALF=true bash examples/singlepod/shortrun.sh
mkdir -p /root/vpc-iptables-client-20000
mv /root/container-bench/logs/short*  /root/vpc-iptables-client-20000/

cd /root/scaler_test
make cert.test-x00388810
rm /root/.kube/config -f
cp doc/clustercert.json /root/.kube/config

cd /root/container-bench
make regist -f Makefile_network
make clean -f Makefile_network

bash examples/singlepod/shortrun.sh
mkdir -p /root/turbo-iptables-server-20000
mv /root/container-bench/logs/short*  /root/turbo-iptables-server-20000/

HALF=true bash examples/singlepod/shortrun.sh
mkdir -p /root/turbo-iptables-client-20000
mv /root/container-bench/logs/short*  /root/turbo-iptables-client-20000/

cd /root/scaler_test
make cert.test-turbo
rm /root/.kube/config -f
cp doc/clustercert.json /root/.kube/config

cd /root/container-bench
make regist -f Makefile_network
make clean -f Makefile_network

bash examples/singlepod/shortrun.sh
mkdir -p /root/turbo-ipvs-server-20000
mv /root/container-bench/logs/short*  /root/turbo-ipvs-server-20000/

HALF=true bash examples/singlepod/shortrun.sh
mkdir -p /root/turbo-ipvs-client-20000
mv /root/container-bench/logs/short*  /root/turbo-ipvs-client-20000/

