import json
import utils

p = utils.parser()
p.add_argument('--select', default="", help='podSelector, k1:v1,k2:v2')

inpt = p.parse_args()
args, kargs = utils.file(inpt.template, 'r')
with open(*args, **kargs) as f:
    j = json.load(f)

fixing = {"metadata.labels.created_by":"perf-test"}

if inpt.select and ":" in inpt.select:
    select = {k:v for k, v in [kv.split(":") for kv in inpt.select.split(",")]}
    fixing.update({"spec.podSelector.matchLabels": select})
j = utils.auto_fix(j, fixing)
print(json.dumps(j))

