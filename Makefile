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

server: ## create a server for ping
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-pod.sh --pod-num 1 --name perf-server --namespace $(namespace) --pod-template $(current_dir)/pod-template/pod.json --image $(swr)/$(serverimage)

hostnetwork: ## create a server for ping
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-pod.sh --pod-num 1 --name perf-hostnetwork --namespace $(namespace) --pod-template $(current_dir)/pod-template/pod-hostnetwork.json --image $(swr)/$(serverimage)
        
clean2:
	kubectl get pods -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-hostnetwork'|xargs -i kubectl delete pod -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get svc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete svc -n $(namespace) --ignore-not-found=true --wait=true {}

clean: ## clean deploy pod and pvc
	kubectl get deploy -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete deploy -n $(namespace) --wait=true {}
	kubectl get pvc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pvc -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get pods -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pod -n $(namespace) --ignore-not-found=true --wait=false {}
	bash script/benchmark-wait-deploy-clean.sh --name perf-test --namespace $(namespace)

count: ## count node for each pod
	kubectl get pods -n $(namespace) -owide|awk '{print $$7}'|tr -s ' ' '\n'|sort |uniq -c|sort -r |awk '{print $$2, $$1}'

deploy1: ## create one deploy with one pod
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-deploy.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

deploy20: ## create one deploy with one pod
	. $(current_dir)/script/get_token.sh;\
	bash $(current_dir)/script/benchmark-create-deploy.sh --deploy-num 1 --pod-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

deploy1000: ## create one deploy with 1000 pod
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-deploy.sh --deploy-num 1 --pod-num 1000 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

20deploy: ## create 20 deploy with pvc
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 2 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs.json --image $(swr)/$(image)

20evs: ## create 20 evs pvc
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 2 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/evs.json 

20nfs: ## create 20 nfs pvc
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/nfs.json 

events: ## create 20 nfs pvc
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-get-event.sh  --namespace $(namespace)
	python envparer.py
