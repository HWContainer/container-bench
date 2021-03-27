import base64
import json

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

with open('/root/.kube/config', 'r') as f:
    conf = json.load(f)
contexts = {a["name"]:a["context"] for a in from_json('contexts', conf)}
context = contexts[conf['current-context']]
users = {a["name"]:a["user"] for a in from_json('users', conf)}
user = users[context['user']]
with open('client.key', 'w') as f:
    f.write(base64.b64decode(user['client-key-data']))
with open('client.crt', 'w') as f:
    f.write(base64.b64decode(user['client-certificate-data']))

