url=$1

./fortio load -qps 0 -c 16 -t 30s --keepalive=false $url
sleep 30
#./fortio load -qps 0 -c 32 -t 30s --keepalive=false $url
#sleep 30
./fortio load -qps 0 -c 64 -t 30s --keepalive=false $url
sleep 30
./fortio load -qps 0 -c 16 -t 30s $url
sleep 30
#./fortio load -qps 0 -c 32 -t 30s $url
#sleep 30
./fortio load -qps 0 -c 64 -t 30s $url
sleep 30

