import json
import utils

p = utils.parser()
p.add_argument('--instance', type=int, default=1, help='instances')
p.add_argument('--select', default="", help='nodeSelector, k1:v1,k2:v2')
p.add_argument('--cpu', default="250m", help='cpu, 250m')
p.add_argument('--mem', default="", help='')
p.add_argument('--prefix', default="", help='prefix ')

inpt = p.parse_args()
args, kargs = utils.file(inpt.template, 'r')
with open(*args, **kargs) as f:
    j = json.load(f)

prefix = inpt.prefix.rstrip("-")
fixing = {"metadata.labels.created_by":"perf-test", "metadata.labels.prefix":prefix}

if utils.from_json_or("spec.template.metadata", j, {}):
    fixing = {"metadata.labels.created_by": "perf-test", "spec.template.metadata.labels.created_by": "perf-test", "metadata.labels.prefix": prefix, "spec.template.metadata.labels.prefix": prefix}

if inpt.select and ":" in inpt.select:
    select = {k:v for k, v in [kv.split(":") for kv in inpt.select.split(",")]}
    fixing.update({"spec.template.spec.nodeSelector": select})
    fixing.update({"metadata.labels."+k: v for k, v in select.items()})
    fixing.update({"spec.template.metadata.labels."+k: v for k, v in select.items()})

if inpt.mem != "":
    resource={
        "limits": {
            "cpu": inpt.cpu,
            "memory": inpt.mem
        },
        "requests": {
            "cpu": inpt.cpu,
            "memory": inpt.mem
        }
    }
    new_containers = []
    for c in utils.from_json_or("spec.template.spec.containers", j, {}):
        new_containers.append(utils.auto_fix(c, {"resources": resource}))
    fixing.update({"spec.template.spec.containers": new_containers})
j = utils.auto_fix(j, fixing)
print(json.dumps(j))

