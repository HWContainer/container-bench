import time
import os
import re
import sys
from collections import OrderedDict
from datetime import datetime


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


def parser_watch_log(file):
    if sys.version_info >= (3, 0):
        args = (file, 'r')
        kwargs = {'encoding': 'utf-8', 'errors': 'ignore'}
    else:
        args = (file, 'r')
        kwargs = {}
    next_changes = []
    new_change = {}
    cur = None
    with open(*args, **kwargs) as f:
        for l in f:
            a = re.match('at\s\S+\s(\S+\.\S+)\S{8}:\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)', l)
            if a:
                if cur != a.group(5):
                    cur = a.group(5)
                    new_change.setdefault('start', datetime.strptime(a.group(1), "%H:%M:%S.%f"))
                    new_change['created'] = datetime.strptime(a.group(1), "%H:%M:%S.%f")
                    new_change['cur'] = cur
                    new_change.pop('scheduled', None)

                if a.group(5) == a.group(6):
                    new_change.setdefault('scheduled', datetime.strptime(a.group(1), "%H:%M:%S.%f"))

                if a.group(5) == a.group(6) == a.group(7) == cur:
                    new_change.setdefault('running', datetime.strptime(a.group(1), "%H:%M:%S.%f"))
                    new_change = {}
                    next_changes.append(new_change)
                    cur = a.group(5)
            a = re.match('at\s\S+\s(\S+\.\S+)\S{8}:\s(\d+)\s(\d+)\s\s(\d+)\s(\d+)\s(\d+)', l)
            if a:
                if cur != a.group(4):
                    cur = a.group(4)
                    new_change.setdefault('start', datetime.strptime(a.group(1), "%H:%M:%S.%f"))
                    new_change['created'] = datetime.strptime(a.group(1), "%H:%M:%S.%f")
                    new_change['cur'] = cur
                    new_change.pop('scheduled', None)

                if a.group(4) == a.group(5):
                    new_change.setdefault('scheduled', datetime.strptime(a.group(1), "%H:%M:%S.%f"))

                if a.group(5) == a.group(6) == a.group(4) and "cur" in new_change:
                    new_change.setdefault('running', datetime.strptime(a.group(1), "%H:%M:%S.%f"))
                    new_change = {}
                    next_changes.append(new_change)
                    cur = a.group(4)

    arr = []
    for x in next_changes:
        print(x)
        if x:
            print("cur:{},created:{},scheduled:{},running:{}".format(x['cur'],
                                                                     (x['created'] - x['start']).total_seconds(),
                                                                     (x['scheduled'] - x['start']).total_seconds(),
                                                                     (x['running'] - x['start']).total_seconds()))
    for x in next_changes:
        if x:
            arr.append(
                [x['cur'], (x['created'] - x['start']).total_seconds(), (x['scheduled'] - x['start']).total_seconds(),
                 (x['running'] - x['start']).total_seconds()])
    dump(['cur', 'created', 'scheduled', 'running'], arr)


base_name = 'watch'
if len(sys.argv) > 1:
    base_name = sys.argv[1]
    if os.path.isfile(base_name):
        parser_watch_log(base_name)
    else:
        parser_watch_log(os.path.join("logs", base_name))
else:
    for f in os.listdir('logs'):
        print(f)
        parser_watch_log(os.path.join("logs", f))

