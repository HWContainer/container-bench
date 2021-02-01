import os
import re
import sys
from collections import OrderedDict
def dump(keys, items, file_name=None):
    data = [keys]
    data = data + items
    longest_cols = [
        (max([len(str(row[i])) for row in data]) + 3)
        for i in range(len(data[0]))
    ]
    row_format = "".join(["{:<" + str(longest_col) + "}" for longest_col in longest_cols])
    if file_name is None:
        for row in data:
            print(row_format.format(*row))
    else:
        with open(file_name, 'w') as f:
            for row in data:
                f.write(row_format.format(*row))
                f.write("\n")

def parser_fortio_logs(file):
    print(file)
    case_list = []
    # errors, metrics, (url, connect), latency
    case = [{}, {}, ("-","-")]
    case_list.append(case)
    start_print = False
    target_stop = False
    quickout=0
    if sys.version_info >= (3, 0):
        args=(file, 'r')
        kwargs={'encoding':'utf-8', 'errors':'ignore'}
    else:
        args=(file, 'r')
        kwargs={}
    with open(*args, **kwargs) as f:
        for i in f.readlines():
            if 'EOF at first read' in i:
                continue
            if '<=' in i:
                continue
            if 'periodic.go' in i:
                continue
            if 'range, mid' in i:
                continue
            if 'max qps' in i:
                continue
            if 'Response' in i:
                continue
            if 'Jitter' in i:
                continue
            if 'Fortio 1.4.0' in i:
                continue
            if 'Sockets used' in i:
                used = re.findall(r'Sockets used:\s*(\d+)', i)
                case.extend(used)
                continue
            if 'All done' in i:
                continue
            if 'Starting http test for' in i:
                url = re.findall(r'([^\s]+) with ([\d\*]+)', i)
                case = [{}, {}]
                case.extend(url)
                case_list.append(case)
                # start_print = True
                continue

            if 'Starting GRPC Ping test' in i:
                url = re.findall(r'([^\s]+) with ([\d\*]+)', i)
                case = [{}, {}]
                case.extend(url)
                case_list.append(case)
                # start_print = True
                continue
    
            if 'Starting 1 process' in i:
                case = [{}, {}]
                case.extend([('-', '-')])
                case_list.append(case)
                # start_print = True
                continue

            if 'python query_csv.py' in i:
                case = [{}, {}]
                case.extend([('-', '-')])
                case_list.append(case)
                # start_print = True
                continue

            if 'name,timestamp' in i and 'node cpu' in i:
                case = [{}, {}]
                case.extend([('-', '-')])
                case_list.append(case)
                # start_print = True
                continue
            if 'latency' in i or '_lat:' in i or 'msg_rate' in i or '[SUM]' in i or 'pps  RX:' in i or \
                ('io=' in i and ('read' in i or 'write' in i)) or ('lat' in i and 'min' in i and 'clat' not in i and 'slat' not in i):
                print(i.strip())
                continue
            if quickout == 1:
                print(i.strip())
                quickout=0
                continue
            if 'con_collect.sh' in i:
                print(i.strip())
                quickout=1
                continue
            if 'Ended after' in i:
                qps = re.findall(r'qps=([^\s]+)', i)
                case.extend(qps)
                continue
            if 'Aggregated Sleep Time' in i:
                target_stop = True
            if 'Aggregated Function Time' in i:
                avg = re.findall(r'avg ([^\s]+)', i)
                # case.extend(avg)
                case.extend([format(float(x)*1000, '.2f') for x in avg])
                target_stop = False
                continue
            if 'target' in i and not target_stop:
                p = re.findall(r'(\d+\.\d*)$', i)
                # print([float(x)*1000 for x in p])
                # case.extend(p)
                case.extend([format(float(x)*1000, '.2f') for x in p])
                continue
            if 'connection timed out' in i:
                case[0]["connection timed"] = 1 + case[0].setdefault("connection timed", 0)
                continue
            if 'connection reset by peer' in i:
                case[0]["connection reset by peer"] = 1 + case[0].setdefault("connection reset by peer", 0)
                continue
            if 'timeout' in i:
                case[0]["timeout"] = 1 + case[0].setdefault("timeout", 0)
                continue
            if 'mem max' in i:
                p = re.findall(r'asm-(\w+)-1(.*) (\w+ mem) max ([\d\.]+)', i)
                if p:
                    p = p[0]
                    case[1].setdefault(p[0]+p[2], p[3])
                    case[1][p[0]+p[2]] = max(p[3], case[1][p[0]+p[2]])
                    continue
                p = re.findall(r'(\S+) (\d+\.\d+\.\d+\.\d+)topprocess mem max ([\d\.]+)', i)
                if p:
                    p = p[0]
                    case[1].setdefault(p[1], {})
                    node=case[1][p[1]]
                    node[p[0]+'mem']=p[2]
                    continue
                p = re.findall(r'(total) (\d+\.\d+\.\d+\.\d+)(\w+) mem max ([\d\.]+)', i)
                if p:
                    p = p[0]
                    case[1].setdefault(p[1], {})
                    node=case[1][p[1]]
                    node[p[2]+'mem']=p[3]
                    continue
                continue
            if 'cpu max' in i:
                p = re.findall(r'asm-(\w+)-1(.*) (\w+ cpu) max ([\d\.]+)', i)
                if p:
                    p = p[0]
                    case[1].setdefault(p[0]+p[2], p[3])
                    case[1][p[0]+p[2]] = max(p[3], case[1][p[0]+p[2]])
                    continue
                p = re.findall(r'(\S+) (\d+\.\d+\.\d+\.\d+)nodetop cpu max ([\d\.]+)', i)
                if p:
                    p = p[0]
                    case[1].setdefault(p[1], {})
                    node=case[1][p[1]]
                    node['node '+p[0]]=p[2]
                    continue
                p = re.findall(r'(\S+) (\d+\.\d+\.\d+\.\d+)topprocess cpu max ([\d\.]+)', i)
                if p:
                    p = p[0]
                    case[1].setdefault(p[1], {})
                    node=case[1][p[1]]
                    node[p[0]]=p[2]
                    continue
                p = re.findall(r'total (\d+\.\d+\.\d+\.\d+)(\w+) cpu max ([\d\.]+)', i)
                if p:
                    p = p[0]
                    case[1].setdefault(p[0], {})
                    node=case[1][p[0]]
                    node[p[1]]=p[2]

                continue
            if 'Code' in i:
                codes = re.findall(r'Code\s+(.+)\s+:\s+(\d+)', i)
                case[0].setdefault("code", [])
                case[0]["code"].append(codes)
                continue
            if re.match(r'^[^,]+,[^,]+,[^,]+$', i):
                continue
            if 'write: io=' in i:
                iops=re.findall(r'\w+: io.*, bw=(.*), iops=(\d+)', i)
                case.extend(iops)
                continue
            if 'read : io=' in i:
                iops=re.findall(r'\w+\s*: io.*, bw=(.*), iops=(\d+)', i)
                case.extend(iops)
                continue
            if 'lat (' in i:
                lat=re.findall(r'\s+lat\s*\((\w+)\)\s*:\s*(min=\d+.*)', i)
                if lat:
                    case.extend(lat)
                continue
            if start_print:
                print(i)
    
    print('commands', 'errors')
    for c in case_list:
        if c[0]:
            print(c[2], c[0], c[1]) 

    dump(['keep', 'rps', 'avg', 'p50', 'p75', 'p90', 'p99', 'p99.9', 'connections', 'url'], [[c[2][1]]+c[3:]+[''] * (8 - len(c[3:]))+[c[2][0]] for c in case_list if c[3:]])

    asms = []
    for c in case_list:
        if 'serverfortio mem' in c[1].keys():
           asms.append([format(float(x), '.3f') for x in [c[1].get('clientfortio cpu', 0), c[1].get('forwordfortio cpu', 0),c[1].get('serverfortio cpu', 0),c[1].get('clientproxy cpu', 0), c[1].get('forwordproxy cpu', 0),c[1].get('serverproxy cpu', 0)]] + [format(float(x)/1024/1024, '.2f') for x in [c[1].get('clientfortio mem', 0),c[1].get('forwordfortio mem', 0),c[1].get('serverfortio mem', 0),c[1].get('clientproxy mem', 0),c[1].get('forwordproxy mem', 0),c[1].get('serverproxy mem', 0)]])
    if asms:
        dump(['client', 'forward', 'server', 'client', 'forward', 'server', 'client', 'forward', 'server', 'client', 'forward', 'server'], asms)
    keys = []
    for c in case_list:
        if 'serverfortio mem' in c[1].keys():
            continue
        for node, v in c[1].items():
            keys += [k for k in v.keys() if 'node' in k ]
    keys=sorted(list(set(keys)))
    dump(["node cpu"]+[k.replace('node ', '') for k in keys], sorted([[node]+ [format(float(kv.get(k,'0')), ".2f") for k in keys] 
                                       for c in case_list 
                                           if 'serverfortio mem' not in c[1].keys() 
                                               for node, kv in c[1].items()
                                   ], key=lambda x: x[0]))

    keys = []
    #keys = ["dockerd", "kubelet", "envoy", "pilot-discovery", "pilot-agent", "kube-proxy", "process"]
    keys = ["nginx", "fortio"]
    if not keys:
        for c in case_list:
            if 'serverfortio mem' in c[1].keys():
                continue
            for node, v in c[1].items():
                keys += [k for k in v.keys() if 'node' not in k and 'mem' not in k ]
        keys.append("process")
        keys=sorted(list(set(keys)))
    dict_values = {}
    for k in keys:
        values = [format(float(kv.get(k,'0')), ".2f") for c in case_list if 'serverfortio mem' not in c[1].keys() for node, kv in c[1].items()]
        dict_values[k] = values
    #for k, v in dict_values.items():
    #    if all([x=='0.00' for x in v]):
    #        keys.remove(k)
    keys.insert(0, 'node')
    dump(["process cpu"]+keys, sorted([[node]+ [format(float(kv.get(k,'0')), ".2f") for k in keys] 
                                       for c in case_list 
                                           if 'serverfortio mem' not in c[1].keys() 
                                               for node, kv in c[1].items()
                                   ], key=lambda x: x[0]))

    keys = []
    #keys = ["nodemem", "envoymem", "pilot-discoverymem", "pilot-agentmem", "dockerdmem", "containerd-shimmem", "kubeletmem", "processmem"]
    keys = ["nodemem", "nginxmem", "fortiomem"]
    if not keys:
        for c in case_list:
            if 'serverfortio mem' in c[1].keys():
                continue
            for node, v in c[1].items():
                keys += [k for k in v.keys() if 'mem' in k ]
        keys=sorted(list(set(keys)))
    #print(keys)
    dump(["process mem"]+[k.replace('mem', '') for k in keys], sorted([[node]+ [format(float(kv.get(k,'0'))/1024/1024, ".2f") for k in keys] 
                                       for c in case_list 
                                           if 'serverfortio mem' not in c[1].keys() 
                                               for node, kv in c[1].items()
                                   ], key=lambda x: x[0]))
    
base_name='perf-test'
if len(sys.argv) > 1:
    base_name=sys.argv[1]
    if os.path.isfile(base_name):
        parser_fortio_logs(base_name)
    else:
        parser_fortio_logs(os.path.join("logs", base_name))
else:
    for f in os.listdir('logs'):
        print(f)
        parser_fortio_logs(os.path.join("logs", f))

