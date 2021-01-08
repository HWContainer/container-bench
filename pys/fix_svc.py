mport json
import utils

p = utils.parser()

inpt = p.parse_args()
args, kargs = utils.file(inpt.template, 'r')
with open(*args, **kargs) as f:
    j = json.load(f)

fixing = {"metadata.labels.created_by":"perf-test"}

j = utils.auto_fix(j, fixing)
print(json.dumps(j))

