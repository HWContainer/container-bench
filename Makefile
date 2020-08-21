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

clean2:
	kubectl get pods -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-hostnetwork'|xargs -i kubectl delete pod -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get svc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete svc -n $(namespace) --ignore-not-found=true --wait=true {}

clean: ## clean deploy pod and pvc
	kubectl get deploy -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete deploy -n $(namespace) --wait=true {}
	kubectl get vkjob -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete vkjob -n $(namespace) --wait=true {}
	kubectl get pvc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pvc -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get pods -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pod -n $(namespace) --ignore-not-found=true --wait=false {}
	bash script/benchmark-wait-deploy-clean.sh --name perf-test --namespace $(namespace)

count: ## count node for each pod
	kubectl get pods -n $(namespace) -owide|awk '{print $$7}'|tr -s ' ' '\n'|sort |uniq -c|sort -r |awk '{print $$2, $$1}'

vol_job: ## create one volcanojob with one task get time cost
	bash $(current_dir)/script/benchmark-create-volcano.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/volcano-template/one_task_atleast_1_resource.json --image $(swr)/$(image)

vol_job_1_in_n: ## create one volcanojob at least 1 pod resource with n task get time of scheduled to created
	bash $(current_dir)/script/benchmark-create-volcano.sh --deploy-num 1 --pod-num $(n) --name perf-test --namespace $(namespace) --pod-template $(current_dir)/volcano-template/five_task_atleast_1_resource.json --image $(swr)/$(image)

vol_job_3_in_5: ## create n volcanojob at least 3 pod resource with 5 task get time of scheduled to created
	bash $(current_dir)/script/benchmark-create-volcano.sh --deploy-num $(n) --pod-num 5 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/volcano-template/five_task_atleast_3_resource.json --image $(swr)/$(image)

vol_job_5_in_5: ## create n volcanojob at least 5 pod resource with 5 task get time of scheduled to created
	bash $(current_dir)/script/benchmark-create-volcano.sh --deploy-num $(n) --pod-num 5 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/volcano-template/five_task_atleast_5_resource.json --image $(swr)/$(image)

events: ## get events
	python envparer.py
