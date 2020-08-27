mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))
# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= config.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	echo $(dir $(mkfile_path))
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_0-9-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

image: ## build image
	docker build -f $(current_dir)/Dockerfile.image -t $(swr)/$(image) $(current_dir)/script
	docker push $(swr)/$(image)
	docker rmi $(swr)/$(image)

base_image: ## build image
	docker build -f $(current_dir)/dockerfiles/Dockerfile.fortio -t $(swr)/$(fortioimage) $(current_dir)/script
	docker push $(swr)/$(fortioimage)
	docker rmi $(swr)/$(fortioimage)
	docker build -f $(current_dir)/dockerfiles/Dockerfile.perf-nginx -t $(swr)/$(baseimage) $(current_dir)/script
	docker push $(swr)/$(baseimage)
	docker rmi $(swr)/$(baseimage)
	docker build -f $(current_dir)/dockerfiles/Dockerfile.prometheus -t $(swr)/$(prometheusimage) $(current_dir)/script
	docker push $(swr)/$(prometheusimage)
	docker rmi $(swr)/$(prometheusimage)
	docker build -f $(current_dir)/dockerfiles/Dockerfile.grafana -t $(swr)/$(grafanaimage) $(current_dir)/script
	docker push $(swr)/$(grafanaimage)
	docker rmi $(swr)/$(grafanaimage)
	docker build -f $(current_dir)/dockerfiles/Dockerfile.process -t $(swr)/$(processimage) $(current_dir)/script
	docker push $(swr)/$(processimage)
	docker rmi $(swr)/$(processimage)

moreimage: ## build image special l layer and c size
	dd if=/dev/urandom of=sample bs=1M count=$(c)
	bash $(current_dir)/script/create_image.sh $(l) $(swr)/$(baseimage) $(swr)/$(image)
	docker push $(swr)/$(image)
	docker rmi $(swr)/$(image)

server: ## create a server for ping
	bash $(current_dir)/script/benchmark-create-pod.sh --pod-num 1 --name perf-server --namespace $(namespace) --pod-template $(current_dir)/pod-template/pod.json --image $(swr)/$(serverimage)
        
metrics: ## create a grafana and process-exporter
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --pod-num 1 --name grafana-server --namespace $(namespace) --pod-template $(current_dir)/deploy-template/grafana-server.json --image $(swr)/$(grafanaimage)
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --pod-num 1 --name prometheus-server --namespace $(namespace) --pod-template $(current_dir)/deploy-template/promethus-server.json --image $(swr)/$(prometheusimage)
	bash $(current_dir)/script/benchmark-create-ds.sh --pod-num 1 --name process-exporter --namespace $(namespace) --pod-template $(current_dir)/ds-template/process-exporter.json --image $(swr)/$(processimage)

fortio: ## create fortio as client
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name fortio --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio.json --image $(swr)/$(fortioimage)

clean2:
	kubectl get pods -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-hostnetwork'|xargs -i kubectl delete pod -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get svc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete svc -n $(namespace) --ignore-not-found=true --wait=true {}

clean: ## clean deploy pod and pvc
	echo "Clean start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
	kubectl get deploy -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete deploy -n $(namespace) --wait=true {}
	kubectl get pods -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pod -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get pvc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pvc -n $(namespace) --ignore-not-found=true --wait=true {}
	echo "Clean end:                `date +%Y-%m-%d' '%H:%M:%S.%N`"

count: ## count node for each pod
	kubectl get pods -n $(namespace) -owide|awk '{print $$7}'|tr -s ' ' '\n'|sort |uniq -c|sort -r |awk '{print $$2, $$1}'

1: ## create one pod
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-pod.sh --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pod-template/pod-network.json --image $(swr)/$(image)

1000: ## create 1000 pod
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-pod.sh --pod-num 1000 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pod-template/pod-network.json --image $(swr)/$(image)

deploy1: ## create one deploy with one pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

deploy20: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

deploy1000: ## create one deploy with 1000 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1000 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

deploy2: ## create Two deploy with one pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 2 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

eni: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni20: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni30: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 30 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni40: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 40 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni50: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 50 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni60: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 60 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni80: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 80 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni100: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 100 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)


20deploy: ## create 20 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 20 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

100deploy: ## create 100 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 100 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

20deploy100: ## create 20 deploy with pvc total 100 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 20 --pod-num 5 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

20evs: ## create 20 evs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/evs-cce.json 

100evs: ## create 100 evs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 100 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/evs-cce.json 

20nfs: ## create 20 nfs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/nfs-cce.json 

20svc: ## create 20 svc
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 20 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/svc-template/svc.json 

2000svc: ## create 2000 svc
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 2000 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/svc-template/svc.json 

event: ## get events and pods
	kubectl get events -ojson -n $(namespace) > /tmp/curl-get-event.log
test: ## test svc
	bash $(current_dir)/script/run_svc_fortio.sh $(namespace) http://$(url) 2>logs/$(url).log
