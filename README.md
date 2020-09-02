create config.env from config.env.tpl


docker login cmd from swr service


sudo make base_image

make server

make metrics

make deploy1

make fortio

python fortio_parser.py  # will parser fortio output from logs

python envparser.py xxx  # wiil parser pod with prefix xxx, default xxx is perf-test


url=perf-test-1 make test



fortio_inject 
  1. apply deploy_fortio_inject
  2. create vr
  3. create ds
  4. label ns kubectl label ns default istio-injection=enabled
  5. create svc for all cluster
  6. security group add svc port rules from all


pod metrics
  1. forword 4194 to 14194
  2. add node:14194 to promethus
  3. import fortio-test_rev1 to grafana

url=fortio-2:8079 make asm_latency_grpc
url=fortio-2:8080 make asm_latency_http

