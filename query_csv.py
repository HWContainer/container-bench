import csv
import requests
import sys
import urllib
import json
import time
from urlparse import urlparse

"""
A simple program to print the result of a Prometheus query as CSV.
"""
if len(sys.argv) != 3:
    print('Usage: {0} http://prometheus:9090 timstamp'.format(sys.argv[0]))
    sys.exit(1)

#params={k:v for k, v in (kv.split("=") for kv in 'start=1598951550&end=1598955450&step=10'.split("&"))}
ts = time.time()
params={"start": sys.argv[2], "end": ts, "step": 10}

fortio_cpu={'query': 'sum (rate (container_cpu_usage_seconds_total{id!="/", image=~".*fortio@.*"}[1m])) by (pod_name)'}
fortio_mem={'query': 'sum (container_memory_working_set_bytes{image=~".*fortio@.*",name=~"^k8s_.*"}) by (pod_name)'}
proxy_cpu={'query': 'sum (rate (container_cpu_usage_seconds_total{id!="/", image=~".*proxyv2.*"}[1m])) by (pod_name)'}
proxy_mem={'query': 'sum (container_memory_working_set_bytes{image=~".*proxyv2.*",name=~"^k8s_.*"}) by (pod_name)'}

def get_metrics(t, params):
    #response = requests.get('{0}/api/v1/query_range'.format(sys.argv[1]), params=params)
    response = requests.get('{0}/api/v1/query_range'.format('http://100.95.146.152:30030'), params=params)
    results = response.json()['data']['result']
    
    # Build a list of all labelnames used.
    writer = csv.writer(sys.stdout)
    writer.writerow(["name", "timestamp", t])
    
    for result in results:
        podname=result['metric']['pod_name']
        for l in result['values']:
        	writer.writerow([podname]+l)
        print("{} {} max {}".format(podname, t, max([l[1] for l in result['values']])))
        #print("".format(max([l[1] for l in result['values']])))

fortio_cpu.update(params)
get_metrics('fortio cpu', fortio_cpu)
fortio_mem.update(params)
get_metrics('fortio mem', fortio_mem)
proxy_cpu.update(params)
get_metrics('proxy cpu', proxy_cpu)
proxy_mem.update(params)
get_metrics('proxy mem', proxy_mem)
