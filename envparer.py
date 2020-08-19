import json
import time
import datetime

def from_json(k, j):
  keys = k.split('.')
  for k in keys:
    try:
      if isinstance(j, list):
        j = j[int(k)]
        continue
    except Exception as e:
      raise Exception("ddd")
    try:
      j = j[k]
    except Exception as e:
      raise Exception(j, k, e)
  return j

with open('/tmp/begin', 'r') as f:
  begin=f.read().strip()
  begin_tm=time.mktime(datetime.datetime.strptime(begin, "%Y-%m-%d %H:%M:%S").timetuple())

with open('/tmp/curl-get-event.log', 'r') as f:
  string=f.read()
  strJson = "".join([ string.strip().rsplit("}" , 1)[0] ,  "}"] )  
  # print(strJson)
  # json_data=eval(strJson)
  json_data=json.loads(strJson)

def mean(numbers):
    return float(sum(numbers)) / max(len(numbers), 1)

events = {}
for j in json_data['items']:
  if 'perf-test' in from_json('metadata.name', j):
    last_tm=time.mktime((datetime.datetime.strptime(from_json('lastTimestamp', j), "%Y-%m-%dT%H:%M:%SZ") + datetime.timedelta(hours=8)).timetuple())
    # print(datetime.datetime.fromtimestamp(begin_tm), datetime.datetime.fromtimestamp(last_tm))
    if begin_tm > last_tm:
      continue
    events.setdefault(from_json('involvedObject.name', j), []).append(
      {'delta': last_tm-begin_tm, 'lastTimestamp': from_json('lastTimestamp', j), 'reason': from_json('reason', j).decode('utf-8').encode('utf-8')})

arr = []
for k, e in events.items():
  # print(k)
  # print('|'.join(["{}|{}".format(x['reason'], x['delta']) for x in e]))
  arr.append({x['reason']:x['delta'] for x in e})
arr = [a for a in arr if 'Scheduled' in a ]
print(len(arr))
print("all scheduled=max([scheduled - begin])\nall running=max([Started - begin])\navg evs mount=avg[SuccessfulMountVolume-Scheduled]\n")
print("all scheduled=", max([x['Scheduled'] for x in arr]))
print("all running=", max([x['Started'] for x in arr]))
print("avg evsmount=", mean([x['SuccessfulMountVolume'] - x['Scheduled'] for x in arr]))
# print("\n".join(events.keys()))
