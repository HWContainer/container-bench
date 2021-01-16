import csv
#import requests
import sys
try:
    import httplib
    from urlparse import urlparse
    from urllib import urlencode
except ModuleNotFoundError as e:
    import http.client as httplib
    from urllib.parse import urlparse
    from urllib.parse import urlencode
import json
import time

"""
A simple program to print the result of a Prometheus query as CSV.
"""
if len(sys.argv) != 3 and len(sys.argv) != 4:
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
    #results = response.json()['data']['result']
    ip,port=urlparse(sys.argv[1]).netloc.split(":")
    conn=httplib.HTTPConnection(ip,port)
    query=urlencode(params)
    # conn.set_debuglevel(1)
    conn.request("GET", '/api/v1/query_range?'+query)
    resp=conn.getresponse()
    data=resp.read()
    if resp.status > 299:
        print(data) 
    results = json.loads(data)['data']['result']
    
    # Build a list of all labelnames used.
    writer = csv.writer(sys.stdout)
    writer.writerow(["name", "timestamp", t])
    
    for result in results:
        podname=result['metric'].get('pod_name', result['metric'].get('groupname', result['metric'].get('mode', 'total')))
        for l in result['values']:
        	writer.writerow([podname]+l)
        print("{} {} max {}".format(podname, t, max([float(l[1]) for l in result['values']])))
        #print("".format(max([float(l[1]) for l in result['values']])))

if len(sys.argv) == 3:
    fortio_cpu.update(params)
    get_metrics('fortio cpu', fortio_cpu)
    fortio_mem.update(params)
    get_metrics('fortio mem', fortio_mem)
    proxy_cpu.update(params)
    get_metrics('proxy cpu', proxy_cpu)
    proxy_mem.update(params)
    get_metrics('proxy mem', proxy_mem)

if len(sys.argv) == 4:
    host=sys.argv[3]
    instance="{}:.*".format(host)
    node_cpu={'query': 'sum (rate(node_cpu_seconds_total{instance=~"'+"{}:.*".format(host)+'", mode!="idle"}[1m]))'}
    top_node_cpu={'query': 'sum (rate(node_cpu_seconds_total{instance=~"'+"{}:.*".format(host)+'", mode!="idle"}[1m])) by (mode)'}
    node_mem={'query': 'node_memory_MemTotal_bytes{instance=~"'+instance+'"} - node_memory_MemFree_bytes{instance=~"'+instance+'"} - node_memory_Cached_bytes{instance=~"'+instance+'"} - node_memory_Buffers_bytes{instance=~"'+instance+'"}'}

    process_cpu={'query': 'sum(rate(namedprocess_namegroup_cpu_user_seconds_total{instance=~"'+"{}:.*".format(host)+'"}[1m])+rate(namedprocess_namegroup_cpu_system_seconds_total{instance=~"'+"{}:.*".format(host)+'"}[1m]))'}
    top_process_cpu={'query': 'topk(5,(sum(rate(namedprocess_namegroup_cpu_user_seconds_total{instance=~"'+"{}:.*".format(host)+'"}[1m])+rate(namedprocess_namegroup_cpu_system_seconds_total{instance=~"'+"{}:.*".format(host)+'"}[1m])) by (groupname)))'}
    
    process_mem={'query': 'sum(avg_over_time(namedprocess_namegroup_memory_bytes{memtype="swapped",instance=~"'+"{}:.*".format(host)+'"}[1m])+ ignoring (memtype) avg_over_time(namedprocess_namegroup_memory_bytes{memtype="resident",instance=~"'+"{}:.*".format(host)+'"}[1m]))'}
    q = 'topk(5,(sum(avg_over_time(namedprocess_namegroup_memory_bytes{memtype="swapped",instance=~"' + \
        "{}:.*".format(host) + \
        '"}[1m]) + ignoring (memtype) avg_over_time(namedprocess_namegroup_memory_bytes{memtype="resident",instance=~"'\
        + "{}:.*".format(host) \
        + '"}[1m])) by(groupname)))'
    top_process_mem={'query': q}

    node_cpu.update(params)
    get_metrics(host+'node cpu', node_cpu)
    top_node_cpu.update(params)
    get_metrics(host+'nodetop cpu', top_node_cpu)
    node_mem.update(params)
    get_metrics(host+'node mem', node_mem)
    process_cpu.update(params)
    get_metrics(host+'process cpu', process_cpu)
    top_process_cpu.update(params)
    get_metrics(host+'topprocess cpu', top_process_cpu)
    process_mem.update(params)
    get_metrics(host+'process mem', process_mem)
    top_process_mem.update(params)
    get_metrics(host+'topprocess mem', top_process_mem)

