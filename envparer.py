import json
import time
import datetime

def from_json_a(k, j):
  keys = k.split('.')
  j_arr = []
  for i, k in enumerate(keys):
    try:
      if isinstance(j, list):
        if k == "*":
          for sj in j:
            j_arr.extend(from_json_a(",".join(keys[i+1:]), sj))
          return j_arr
        j = j[int(k)]
        continue
    except Exception as e:
      raise Exception(k,j, e)
    try:
      j = j[k]
    except Exception as e:
      raise Exception(j, k, e)
  j_arr.append(j)
  return j_arr

def from_json(k, j):
  j_a = from_json_a(k, j)
  if len(j_a) == 1:
    return j_a[0]
  return j_a

with open('/tmp/begin', 'r') as f:
  begin=f.read().strip()
  begin_tm=time.mktime(datetime.datetime.strptime(begin, "%Y-%m-%d %H:%M:%S").timetuple())

with open('/tmp/curl-get-event.log', 'r') as f:
  string=f.read()
  strJson = "".join([ string.strip().rsplit("}" , 1)[0] ,  "}"] )  
  json_data=json.loads(strJson)

with open('/tmp/curl-get-pods.log', 'r') as f:
  string=f.read()
  strJson = "".join([ string.strip().rsplit("}" , 1)[0] ,  "}"] )  
  pod_data=json.loads(strJson)

def mean(numbers):
    return float(sum(numbers)) / max(len(numbers), 1)

events = {}
for j in json_data['items']:
  if 'perf-test' in from_json('metadata.name', j) and 'PodGroup' not in from_json('involvedObject.kind', j): # and 'perf-test-10-mork-1' in from_json('metadata.name', j):
    last_tm=time.mktime((datetime.datetime.strptime(from_json('lastTimestamp', j), "%Y-%m-%dT%H:%M:%SZ") + datetime.timedelta(hours=8)).timetuple())
    # print(datetime.datetime.fromtimestamp(begin_tm), datetime.datetime.fromtimestamp(last_tm))
    if begin_tm > last_tm:
      continue
    #print(from_json('reason', j).decode('utf-8').encode('utf-8'), from_json('lastTimestamp', j))
    events.setdefault(from_json('involvedObject.name', j), []).append(
      {'delta': last_tm-begin_tm, 'lastTimestamp': from_json('lastTimestamp', j), 'reason': from_json('reason', j).decode('utf-8').encode('utf-8')})

pods = {}
for j in pod_data['items']:
  if 'perf-test' in from_json('metadata.name', j): # and 'perf-test-10-mork-1' in from_json('metadata.name', j):
    #print(from_json('metadata.creationTimestamp', j))
    #print(from_json('status.conditions.*.lastTransitionTime', j))
    create_tm=time.mktime((datetime.datetime.strptime(from_json('metadata.creationTimestamp', j), "%Y-%m-%dT%H:%M:%SZ") + datetime.timedelta(hours=8)).timetuple())
    pods.setdefault(from_json('metadata.name', j), [{'delta': create_tm - begin_tm, 'reason': 'Created'}]).extend(
      [{'delta': time.mktime((datetime.datetime.strptime(v, "%Y-%m-%dT%H:%M:%SZ") + datetime.timedelta(hours=8)).timetuple()) - begin_tm, 'reason':k.decode('utf-8').encode('utf-8')} for k, v in zip(from_json('status.conditions.*.type', j), from_json('status.conditions.*.lastTransitionTime', j))])

arr = []
for k, e in events.items():
  print(k)
  print('|'.join(["{}|{}".format(x['reason'], x['delta']) for x in sorted(e+pods[k], key=lambda x: x['delta'])]))
  arr.append({x['reason']:x['delta'] for x in e+pods[k]})
arr = [a for a in arr if 'Scheduled' in a ]
print(len(arr))
print("all scheduled=max([scheduled - begin])\nall running=max([Started - begin])\navg evs mount=avg[SuccessfulMountVolume-Scheduled]\n")
print("all scheduled=", max([x['Scheduled'] for x in arr]))
print("all waiting=", max([x['Started'] for x in arr]))
print("avg evsmount=", mean([x['SuccessfulMountVolume'] - x['Scheduled'] for x in arr]))
print("avg excuted=", ([x['Ready'] - x['Started'] for x in arr]))
# print("\n".join(events.keys()))

