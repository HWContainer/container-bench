import oss2
auth = oss2.Auth('your-access-key-id', 'your-access-key-secret')
service = oss2.Service(auth, 'oss-cn-hangzhou.aliyuncs.com')
service.list_buckets()
bucket = oss2.Bucket(auth, 'http://oss-cn-hangzhou.aliyuncs.com', 'your-bucket')
bucket.put_object('readme.txt', 'content of readme.txt')
with open(u'local_file.txt', 'rb') as f:
  bucket.put_object('remote_file.txt', f)

bucket.enable_crc = False
bucket.put_object('testfolder/', None)


result = bucket.get_object('readme.txt')
print(result.read())

##http://gosspublic.alicdn.com/sdks/python/apidocs/latest/zh-cn/api.html#input-output-and-exception-description
