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


events = {}
for j in json_data['items']:
  if 'perf-test' in from_json('metadata.name', j):
    last_tm=time.mktime((datetime.datetime.strptime(from_json('lastTimestamp', j), "%Y-%m-%dT%H:%M:%SZ") + datetime.timedelta(hours=8)).timetuple())
    # print(datetime.datetime.fromtimestamp(begin_tm), datetime.datetime.fromtimestamp(last_tm))
    if begin_tm > last_tm:
      continue
    events.setdefault(from_json('involvedObject.name', j), []).append(
      {'delta': last_tm-begin_tm, 'lastTimestamp': from_json('lastTimestamp', j), 'reason': from_json('reason', j)})

for k, e in events.items():
  print(k)
  for x in e:
    print("  {}".format(x))
print(len(events))
# print("\n".join(events.keys()))
