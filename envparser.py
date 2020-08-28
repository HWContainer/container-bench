import json
import time
import datetime
import re
import sys
base_name='perf-test'
if len(sys.argv) > 1:
  base_name=sys.argv[1]
def from_json_a(k, j):
  keys = k.split('.')
  j_arr = []
  for i, k in enumerate(keys):
    try:
      if isinstance(j, list):
        # get all value in the list
        if k == "*":
          for sj in j:
            j_arr.extend(from_json_a(".".join(keys[i+1:]), sj))
          return j_arr
        j = j[int(k)]
        continue
    except Exception as e:
      raise Exception(k,j, e)
    try:
      if k == "*":
        # if the key may different, skip it
        for jk in j.keys():
          try:
            # print(keys[i+1:], j[jk])
            j = from_json_a(".".join(keys[i+1:]), j[jk])
            return j
          except Exception as e:
            continue
        return []  # if can't find return empty list
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

logs={}
with open('/tmp/curl-get-realstart.log', 'r') as f:
  for l in f:
    runtothrough=re.findall("^[^\s]+\s+[^\s]+\s+([^\s]+\s+[^\s]+)\s+Check ([^\s]+).*success take: (\d+\.\d+)", l)
    if runtothrough:
      last_tm=time.mktime((datetime.datetime.strptime(runtothrough[0][0], "%Y-%m-%d %H:%M:%S")+datetime.timedelta(hours=8)).timetuple())
      logs[runtothrough[0][1]] = [{'delta': last_tm-begin_tm, 'reason': "ping"}]

def mean(numbers):
    return float(sum(numbers)) / max(len(numbers), 1)

events = {}
for j in json_data['items']:
  if base_name in from_json('metadata.name', j) and from_json('involvedObject.kind', j) not in ['ReplicaSet', 'PodGroup', 'Deployment', 'Ingress']: # and 'perf-test-10-mork-1' in from_json('metadata.name', j):
    #scheduled not record print(from_json('lastTimestamp', j))
    last_tm=time.mktime((datetime.datetime.strptime(from_json('lastTimestamp', j), "%Y-%m-%dT%H:%M:%SZ") + datetime.timedelta(hours=8)).timetuple())
    #last_tm=time.mktime((datetime.datetime.strptime(from_json('metadata.creationTimestamp', j), "%Y-%m-%dT%H:%M:%SZ") + datetime.timedelta(hours=8)).timetuple())
    #print(datetime.datetime.fromtimestamp(begin_tm), datetime.datetime.fromtimestamp(last_tm))
    if begin_tm > last_tm:
      continue
    #print(from_json('reason', j).decode('utf-8').encode('utf-8'), from_json('lastTimestamp', j))
    events.setdefault(from_json('involvedObject.name', j), []).append(
      {'delta': last_tm-begin_tm, 'lastTimestamp': from_json('lastTimestamp', j), 'reason': from_json('reason', j).decode('utf-8').encode('utf-8')})

pods = {}
for j in pod_data['items']:
  if base_name in from_json('metadata.name', j): # and 'perf-test-10-mork-1' in from_json('metadata.name', j):
    #print(from_json('metadata.creationTimestamp', j))
    #print(from_json('status.conditions.*.lastTransitionTime', j))
    create_tm=time.mktime((datetime.datetime.strptime(from_json('metadata.creationTimestamp', j), "%Y-%m-%dT%H:%M:%SZ") + datetime.timedelta(hours=8)).timetuple())
    #pods.setdefault(from_json('metadata.name', j), [{'delta': create_tm - begin_tm, 'reason': 'Created'}]).extend(
    #  [{'delta': time.mktime((datetime.datetime.strptime(v, "%Y-%m-%dT%H:%M:%SZ") + datetime.timedelta(hours=8)).timetuple()) - begin_tm, 'reason':k.decode('utf-8').encode('utf-8')} for k, v in zip(from_json('status.conditions.*.type', j), from_json('status.conditions.*.lastTransitionTime', j))])
    startedAt=min([time.mktime((datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ") + datetime.timedelta(hours=8)).timetuple()) - begin_tm for s in from_json_a('status.containerStatuses.*.state.*.startedAt', j)])
    try:
      finishedAt=min([time.mktime((datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ") + datetime.timedelta(hours=8)).timetuple()) - begin_tm for s in from_json_a('status.containerStatuses.*.state.*.finishedAt', j)])
    except ValueError:
      finishedAt=88888
    pods.setdefault(from_json('metadata.name', j), [{'delta': create_tm - begin_tm, 'reason': 'Created'}]).extend(
      [{'delta': startedAt, 'reason': 'startedAt'}, {'delta': finishedAt, 'reason': 'finishedAt'}])

arr = []
for k, e in events.items():
#  print(k)
#  print('|'.join(["{}|{}".format(x['reason'], x['delta']) for x in sorted(e+pods[k], key=lambda x: x['delta'])]))
  arr.append({x['reason']:x['delta'] for x in e+pods[k]+logs.get(k, [])})
arr = [a for a in arr if 'Scheduled' in a ]
print("total pods = {}".format(len(arr)))
print("created \tmin={},\t max={},\t avg={}".format(min([x['Created'] for x in arr]), max([x['Created'] for x in arr]), mean([x['Created'] for x in arr])))
print("scheduled \tmin={},\t max={},\t avg={}".format(min([x['Scheduled'] for x in arr]), max([x['Scheduled'] for x in arr]), mean([x['Scheduled'] for x in arr])))
print("pulling \tmin={},\t max={},\t avg={}".format(min([x['Pulling'] for x in arr]), max([x['Pulling'] for x in arr]), mean([x['Pulling'] for x in arr])))
print("pulled  \tmin={},\t max={},\t avg={}".format(min([x['Pulled'] for x in arr]), max([x['Pulled'] for x in arr]), mean([x['Pulled'] for x in arr])))
print("pull takes \tmin={},\t max={},\t avg={}".format(min([x['Pulled'] - x['Pulling'] for x in arr]), max([x['Pulled'] - x['Pulling'] for x in arr]), mean([x['Pulled'] - x['Pulling'] for x in arr])))
print("mount takes \tmin={},\t max={},\t avg={}".format(min([x['SuccessfulMountVolume'] - x['Scheduled'] for x in arr]), max([x['SuccessfulMountVolume'] - x['Scheduled'] for x in arr]), mean([x['SuccessfulMountVolume'] - x['Scheduled'] for x in arr])))
print("start takes \tmin={},\t max={},\t avg={}".format(min([x['startedAt']-x['Scheduled'] for x in arr]), max([x['startedAt'] - x['Scheduled']for x in arr]), mean([x['startedAt']-x['Scheduled'] for x in arr])))
print("startedAt \tmin={},\t max={},\t avg={}".format(min([x['startedAt'] for x in arr]), max([x['startedAt'] for x in arr]), mean([x['startedAt'] for x in arr])))
if 'ping' in arr[0].keys():
  print("pingsuccess \tmin={},\t max={},\t avg={}".format(min([x['ping'] for x in arr]), max([x['ping'] for x in arr]), mean([x['ping'] for x in arr])))
print("running \tmin={},\t max={},\t avg={}".format(min([x['Started'] for x in arr]), max([x['Started'] for x in arr]), mean([x['Started'] for x in arr])))
print("finishedAt \tmin={},\t max={},\t avg={}".format(min([x['finishedAt'] for x in arr]), max([x['finishedAt'] for x in arr]), mean([x['finishedAt'] for x in arr])))
# print("excuted=", ([x['finishedAt'] - x['startedAt'] for x in arr]))
# print("\n".join(events.keys()))
