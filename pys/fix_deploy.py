import json
import utils

p = utils.parser()
p.add_argument('--instance', type=int, default=1, help='instances')
p.add_argument('--select', default="", help='nodeSelector, k1:v1,k2:v2')

inpt = p.parse_args()
args, kargs = utils.file(inpt.template, 'r')
with open(*args, **kargs) as f:
    j = json.load(f)

fixing = {"metadata.labels.created_by":"perf-test"}
if utils.from_json_or("spec.template.metadata", j, {}):
    fixing = {"metadata.labels.created_by": "perf-test", "spec.template.metadata.labels.created_by": "perf-test"}
fixing.update({"spec.replicas":inpt.instance})

if inpt.select:
    select = {k:v for k, v in [kv.split(":") for kv in inpt.select.split(",")]}
    fixing.update({"spec.template.spec.nodeSelector": select})
j = utils.auto_fix(j, fixing)
print(json.dumps(j))

