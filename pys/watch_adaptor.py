import copy
import datetime as dt
from datetime import datetime
import re
import sys


def adapt_static(ori_list):
    start = ori_list[0][0]
    last_c = ori_list[0][1]
    new_list = []
    for at, count in ori_list:
        # print(at.strftime("%H:%M:%S"))
        while (at - start).total_seconds() >= 1:
            # print("---", start.strftime("%H:%M:%S"))
            new_list.append([start, copy.deepcopy(last_c)])
            start = start + dt.timedelta(0, 1)
        last_c = count
    return new_list


def parser_watch_log(file):
    ori_list = []
    if sys.version_info >= (3, 0):
        args = (file, 'r')
        kwargs = {'encoding': 'utf-8', 'errors': 'ignore'}
    else:
        args = (file, 'r')
        kwargs = {}
    with open(*args, **kwargs) as f:
        for l in f:
            a = re.match(r"at\s\S+\s(\S+\.\S+)\S{8}:\s(.*)", l)
            if a:
                ori_list.append([datetime.strptime(a.group(1), "%H:%M:%S.%f"),
                                 a.group(2)])
    return ori_list


new_list = adapt_static(parser_watch_log("result.txt"))
for item in new_list:
    mt = item[1]
    print("{} {}".format(item[0].strftime("%H:%M:%S"), mt))


