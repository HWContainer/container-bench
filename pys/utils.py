import copy
import sys
import argparse


def file(file, option='r'):
    if sys.version_info >= (3, 0):
        args = (file, option)
        kwargs = {'encoding': 'utf-8', 'errors': 'ignore'}
    else:
        args = (file, option)
        kwargs = {}
    return args, kwargs


def parser():
    p = argparse.ArgumentParser(description='Process some integers.')
    p.add_argument('--template', help='template')
    return p


def from_json_a(k, j):
    keys = k.split('.')
    j_arr = []
    for i, k in enumerate(keys):
        try:
            if isinstance(j, list):
                # get all value in the list
                if k == "*":
                    for sj in j:
                        j_arr.extend(from_json_a(".".join(keys[i + 1:]), sj))
                    return j_arr
                j = j[int(k)]
                continue
        except Exception as e:
            raise Exception(k, j, e)
        try:
            if k == "*":
                # if the key may different, skip it
                for jk in j.keys():
                    try:
                        # print(keys[i+1:], j[jk])
                        j = from_json_a(".".join(keys[i + 1:]), j[jk])
                        return j
                    except Exception as e:
                        continue
                return []  # if can't find return empty list
            j = j[k]
        except Exception as e:
            raise Exception(j, k, e)
    j_arr.append(j)
    return j_arr


def from_json_or(k, j, ov):
    keys = k.split('.')
    for k in keys:
        try:
            if isinstance(j, list):
                j = j[int(k)]
                continue
        except Exception as e:
            raise Exception(k, j, e)
        try:
            j = j.setdefault(k, ov)
        except Exception as e:
            raise Exception(k, j, e)
    return j


def from_json_or_empty(k, j):
    keys = k.split('.')
    for k in keys:
        try:
            if isinstance(j, list):
                j = j[int(k)]
                continue
        except Exception as e:
            raise Exception(k, j, e)
        try:
            j = j.get(k, "")
        except Exception as e:
            raise Exception(k, j, e)
    j = j if isinstance(j, str) else json.dumps(j)
    return j


def from_json(k, j):
    j_a = from_json_a(k, j)
    if len(j_a) == 1:
        return j_a[0]
    return j_a


def auto_fix(j, fix=None, **kwargs):
    body = copy.deepcopy(j)
    fix = {} if not isinstance(fix, dict) else fix
    fix.update(**kwargs)
    for k, v in fix.items():
        if '.' in k:
            keys = k.split('.')
            j = body
            for nk in keys[: -1]:
                j = j.setdefault(nk, {})
            j[keys[-1]] = v

        else:
            body[k] = v
    return body

