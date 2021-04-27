pods=`kubectl get pods -owide |grep '/'|sed 's#/# #g'|awk '{if($3 != $2) print $0 }'`
if ! [ -z "$pods" ]; then
  echo "$pods"
else
  echo "goon"
fi
