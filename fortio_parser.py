import os
import re
import sys
def parser_fortio_logs(file):
    case_list = []
    case = []
    start_print = False
    with open(file, 'r') as f:
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
                url = re.findall(r'(http://[^\s]+) with (\d+)', i)
                case = [{}]
                case.extend(url)
                case_list.append(case)
                start_print = True
                continue
    
            if 'Ended after' in i:
                qps = re.findall(r'qps=([^\s]+)', i)
                case.extend(qps)
                continue
            if 'Aggregated Function Time' in i:
                avg = re.findall(r'avg ([^\s]+)', i)
                # case.extend(avg)
                case.extend([format(float(x)*1000, '.2f') for x in avg])
                continue
            if 'target' in i:
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
            if 'Code' in i:
                codes = re.findall(r'Code\s+(.+)\s+:\s+(\d+)', i)
                case[0].setdefault("code", [])
                case[0]["code"].append(codes)
                continue
            if start_print:
                print(i)
    
    for c in case_list:
        print(c[0], c[1:])
    
base_name='perf-test'
if len(sys.argv) > 1:
    base_name=sys.argv[1]
    parser_fortio_logs(os.path.join("logs", base_name))
else:
    for f in os.listdir('logs'):
        print(f)
        parser_fortio_logs(os.path.join("logs", f))
