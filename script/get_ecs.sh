#ecses=`curl -sk -H 'Content-Type:application/json' -H "X-Auth-Token: $token" -X GET $ecs/v1/${project_id}/cloudservers/detail'?expect-fields=metadata,addresses,hostId,key_name,host_status,locked,tags,root_device_name,volumes_attached,launched_at&offset=0&limit=633&enterprise_project_id=all_granted_eps&task_state=!deleting&not-tags-any=__type_baremetal%2C__type_lcs' |python -m json.tool`

ecses=`curl -sk -H 'Content-Type:application/json' -H "X-Auth-Token: $token" -X GET $ecs/v1/${project_id}/cloudservers/detail'?expect-fields=volumes_attached,launched_at&offset=0&limit=633&enterprise_project_id=all_granted_eps&task_state=!deleting&not-tags-any=__type_baremetal%2C__type_lcs' |python -m json.tool`

mkdir -p doc
echo "$ecses" |grep -v user > doc/ecs.json
