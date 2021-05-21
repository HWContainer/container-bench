import json
import utils

p = utils.parser()
p.add_argument('--prefix', default="", help='prefix ')

inpt = p.parse_args()
args, kargs = utils.file(inpt.template, 'r')
with open(*args, **kargs) as f:
    j = json.load(f)

prefix = inpt.prefix.rstrip("-")
fixing = {"metadata.labels.created_by":"perf-test", "metadata.labels.prefix":prefix}

j = utils.auto_fix(j, fixing)
print(json.dumps(j))
