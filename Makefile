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
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

image:
	docker build -f $(current_dir)/Dockerfile.image -t $(swr)/$(image) $(current_dir)/script 

server: 
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-pod.sh --pod-num 1 --name perf-server --namespace $(namespace) --pod-template $(current_dir)/pod-template/pod.json
        
clean:
	kubectl get deploy -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete deploy -n $(namespace) --wait=true {}
	kubectl get pods -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pod -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get pvc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pvc -n $(namespace) --ignore-not-found=true --wait=true {}

count:
	kubectl get pods -n $(namespace) -owide|awk '{print $$7}'|tr -s ' ' '\n'|sort |uniq -c|sort -r |awk '{print $$2, $$1}'

1: 
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-pod.sh --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pod-template/pod-network.json

1000:
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-pod.sh --pod-num 1000 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pod-template/pod-network.json

deploy1:
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-deploy.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

deploy20:
	. $(current_dir)/script/get_token.sh;\
	bash $(current_dir)/script/benchmark-create-deploy.sh --deploy-num 1 --pod-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

deploy1000:
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-deploy.sh --deploy-num 1 --pod-num 1000 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

20deploy:
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 20 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs.json --image $(swr)/$(image)

20evs:
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/evs.json 

20nfs:
	. $(current_dir)/script/get_token.sh; \
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/nfs.json 
