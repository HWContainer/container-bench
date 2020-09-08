image=$1
curl -k -i -X POST -H 'Content-Type: application/json' -H "X-Auth-Token:${token}" $endpoint/apis/image.cci.io/v1alpha1/imagecaches -d '{"apiVersion":"image.cci.io/v1alpha1","kind":"ImageCache","metadata":{"name":"test5"},"spec":{"images":["'$image'"],"minimumImageTTL":10000,"policy":"dedicateNode"}}'
