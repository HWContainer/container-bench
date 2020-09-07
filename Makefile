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
.PHONY: help clean4 waiting test_ddd

help: ## This help.
	echo $(dir $(mkfile_path))
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_0-9-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

test_ddd: 
	clean4

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
	docker build -f $(current_dir)/dockerfiles/Dockerfile.node -t $(swr)/$(nodeimage) $(current_dir)/script
	docker push $(swr)/$(nodeimage)
	docker rmi $(swr)/$(nodeimage)

moreimage: ## build image special l layer and c size
	dd if=/dev/urandom of=sample bs=1M count=$(c)
	bash $(current_dir)/script/create_image.sh $(l) $(swr)/$(baseimage) $(swr)/$(image)
	docker push $(swr)/$(image)
	docker rmi $(swr)/$(image)

server: ## create a server for ping
	bash $(current_dir)/script/benchmark-create-pod.sh --pod-num 1 --name perf-server --namespace $(namespace) --pod-template $(current_dir)/pod-template/pod.json --image $(swr)/$(serverimage)
        
metrics: ## create a grafana and process-exporter
	make monit; make process; make cadvisor; make node

monit:
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --pod-num 1 --name grafana-server --namespace $(namespace) --pod-template $(current_dir)/deploy-template/grafana-server.json --image $(swr)/$(grafanaimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name grafana-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/grafana_svc.json 
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --pod-num 1 --name prometheus-server --namespace $(namespace) --pod-template $(current_dir)/deploy-template/promethus-server.json --image $(swr)/$(prometheusimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name prometheus-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/prometheus_svc.json 

process:
	bash $(current_dir)/script/benchmark-create-ds.sh --pod-num 1 --name process-exporter --namespace $(namespace) --pod-template $(current_dir)/ds-template/process-exporter.json --image $(swr)/$(processimage)

cadvisor:
	bash $(current_dir)/script/benchmark-create-ds.sh --pod-num 1 --name cadvisor-exporter --namespace $(namespace) --pod-template $(current_dir)/ds-template/cadvisor-exporter.json --image $(swr)/$(fortioimage)

node:
	bash $(current_dir)/script/benchmark-create-ds.sh --pod-num 1 --name node-exporter --namespace $(namespace) --pod-template $(current_dir)/ds-template/node-exporter.json --image $(swr)/$(nodeimage)

fortio:
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name fortio --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio.json --image $(swr)/$(fortioimage)

asm_server: 
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_svc.json 

asm_client:
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_svc.json 

asm_server_inject_http:
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio_inject.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_svc.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-dr.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/dr.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-vs.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/vs_http.json 

asm_forword_inject_http:
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio_forword_inject.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_forword_svc.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-dr.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/svc-template/dr.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-vs.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/svc-template/vs_forword_http.json 

asm_client_inject_http:
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio_inject.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_svc.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-dr.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/dr.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-vs.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/vs_http.json 

asm_client_inject_tcp: ## client inject tcp proxy
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio_inject.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_svc_tcp.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-dr.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/dr.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-vs.sh --deploy-num 1 --pod-num 1 --name asm-client --namespace $(namespace) --pod-template $(current_dir)/svc-template/vs_tcp.json 

asm_forword_inject_tcp: ## forword inject tcp proxy
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio_forword_inject.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_forword_svc_tcp.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-dr.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/svc-template/dr.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-vs.sh --deploy-num 1 --pod-num 1 --name asm-forword --namespace $(namespace) --pod-template $(current_dir)/svc-template/vs_forword_tcp.json 

asm_server_inject_tcp: ## server inject tcp proxy
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/deploy-template/fortio_inject.json --image $(swr)/$(fortioimage)
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/fortio_svc_tcp.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-dr.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/dr.json 
	KUBECONFIG=$(control_plane) bash $(current_dir)/script/benchmark-create-vs.sh --deploy-num 1 --pod-num 1 --name asm-server --namespace $(namespace) --pod-template $(current_dir)/svc-template/vs_tcp.json 

asm_sc: clean4 waiting asm_client asm_server  ## create s->c module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-server-1:8080 2>logs/sc_http.log 1>&2
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_grpc.sh $(namespace) http://asm-server-1:8079 2>logs/sc_grpc.log 1>&2
asm_scp_http: clean4 waiting asm_client asm_server_inject_http ## create s->cp module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-server-1:8080 2>logs/http_scp_http.log 1>&2
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_grpc.sh $(namespace) http://asm-server-1:8079 2>logs/scp_grpc.log 1>&2
asm_spcp_http: clean4 waiting asm_client_inject_http asm_server_inject_http ## create sp->cp module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-server-1:8080 2>logs/http_spcp_http.log 1>&2
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_grpc.sh $(namespace) http://asm-server-1:8079 2>logs/spcp_grpc.log 1>&2
asm_spfpcp_http: clean4 waiting asm_server_inject_http asm_client_inject_http asm_forword_inject_http ## create sp->fp->cp module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-forword-1:8888 2>logs/http_spfpcp_http.log 1>&2
asm_scp_tcp: clean4 waiting asm_client asm_server_inject_tcp ## create s->cp module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-server-1:8080 2>logs/tcp_scp_http.log 1>&2
asm_spcp_tcp: clean4 waiting asm_client_inject_tcp asm_server_inject_tcp ## create tcp sp->cp module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-server-1:8080 2>logs/tcp_spcp_http.log 1>&2
asm_spfpcp_tcp: clean4 waiting asm_server_inject_tcp asm_client_inject_tcp asm_forword_inject_tcp ## create tcp sp->fp->cp module
	make waiting
	mkdir -p $(current_dir)\logs
	prometheus_url=$(prometheus_url) default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://asm-forword-1:8888 2>logs/tcp_spfpcp_http.log 1>&2

all_u_gi: 
	make asm_sc; make asm_scp_http; make asm_spcp_http; make asm_spfpcp_http; make asm_scp_tcp; make asm_spcp_tcp; make asm_spfpcp_tcp

waiting:
	sleep 120

clean4: 
	kubectl get deploy -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e 'asm' |xargs -i kubectl delete deploy -n $(namespace) --wait=true {}
	kubectl get svc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e 'asm' |xargs -i kubectl delete svc -n $(namespace) --wait=true {}
	KUBECONFIG=$(control_plane) sh -c "kubectl get dr -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e 'asm' |xargs -i kubectl delete dr -n $(namespace) --wait=true {}"
	KUBECONFIG=$(control_plane) sh -c "kubectl get vs -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e 'asm' |xargs -i kubectl delete vs -n $(namespace) --wait=true {}"

clean3: 
	kubectl get deploy -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e 'grafana' -e 'prometheus'|xargs -i kubectl delete deploy -n $(namespace) --wait=true {}
	kubectl get ds -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep -e process -e cadvisor|xargs -i kubectl delete ds -n $(namespace) --wait=true {}
	kubectl delete pods -n $(namespace) perf-server-1

clean2:
	kubectl get pods -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-hostnetwork'|xargs -i kubectl delete pod -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get svc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete svc -n $(namespace) --ignore-not-found=true --wait=true {}

clean: ## clean deploy pod and pvc
	echo "Clean start:              `date +%Y-%m-%d' '%H:%M:%S.%N`"
	kubectl get deploy -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete deploy -n $(namespace) --wait=true {}
	kubectl get pods -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pod -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get pvc -n $(namespace) -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pvc -n $(namespace) --ignore-not-found=true --wait=true {}
	kubectl get pv -o=jsonpath='{.items[*].metadata.name}'|tr ' ' '\n'|grep 'perf-test'|xargs -i kubectl delete pv --ignore-not-found=true --wait=true {}
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
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/svc-template/svc.json 

deploy20: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

deploy1000: ## create one deploy with 1000 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1000 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

deploy2: ## create Two deploy with one pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 2 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test.json --image $(swr)/$(image)

eni: ## create one deploy with 1 pod
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

eni200: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 200 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

eni400: ## create one deploy with 20 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 400 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test_eni.json --image $(swr)/$(image)

15deploy: ## create 20 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 15 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

20deploy: ## create 20 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 20 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

40deploy: ## create 40 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 40 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

50deploy: ## create 50 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 50 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

60deploy: ## create 60 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 60 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

100deploy: ## create 100 deploy with pvc
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 100 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

20deploy100: ## create 20 deploy with pvc total 100 pod
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 20 --pod-num 5 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)

alievs = evs-ssd evs-topology evs-avaliable evs-efficiency evs-essd
allevs: $(alievs) ## evs-ssd evs-topology evs-avaliable evs-efficiency evs-essd

$(alievs):clean
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$@.json 
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)
	prometheus_url=$(prometheus_url) bash $(current_dir)/script/run_fio.sh 50G  2>logs/$@.log 1>&2

nfs-perf nfs-extreme:clean
	bash $(current_dir)/script/benchmark-create-pv.sh --deploy-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$@-pv.json
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$@.json 
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)
	prometheus_url=$(prometheus_url) bash $(current_dir)/script/run_fio.sh 100M 2>logs/$@.log 1>&2

oss:clean
	bash $(current_dir)/script/benchmark-create-pv.sh --deploy-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/oss-pv.json
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/oss.json 
	bash $(current_dir)/script/benchmark-create-deploy-pvc.sh --deploy-num 1 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/deploy-template/perf-test-evs_eni.json --image $(swr)/$(image)
	prometheus_url=$(prometheus_url) bash $(current_dir)/script/run_fio.sh 100M 2>logs/$@.log 1>&2

20evs: ## create 20 evs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$(evs).json 

40evs: ## create 40 evs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 40 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$(evs).json 

60evs: ## create 40 evs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 60 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$(evs).json 

100evs: ## create 100 evs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 100 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$(evs).json 

20nfs-pv: ## create 20 nfs pvc
	bash $(current_dir)/script/benchmark-create-pv.sh --deploy-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/nfs-pv.json 

20nfs: ## create 20 nfs pvc
	bash $(current_dir)/script/benchmark-create-evs.sh --deploy-num 20 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/pvc-template/$(nfs).json 

2svc2: ## create 2 svc for 2 deploy
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 2 --pod-num 2 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/svc-template/svc.json 

20svc: ## create 20 svc
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 20 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/svc-template/svc.json 

2000svc: ## create 2000 svc
	bash $(current_dir)/script/benchmark-create-svc.sh --deploy-num 2000 --pod-num 1 --name perf-test --namespace $(namespace) --pod-template $(current_dir)/svc-template/svc.json 

event: ## get events and pods
	bash $(current_dir)/script/get_pods_logs.sh $(namespace)
	kubectl get events -ojson -n $(namespace) > /tmp/curl-get-event.log

test: ## test svc
	prometheus_url=$(prometheus_url) bash $(current_dir)/script/run_svc_fortio.sh $(namespace) http://$(url) 2>logs/$(url).log 1>&2

prepare_vm: ## prepare vm
	cat $(current_dir)/script/prepare_vm.sh | sshpass -p Huawei@123 ssh -oStrictHostKeyChecking=no root@$(nodec) bash -s $(swr)/$(fortioimage) $(swr)/$(nodeimage) $(swr)/$(processimage) $(node)

vm: ## test svc
	prometheus_url=$(prometheus_url) bash $(current_dir)/script/run_fortio_in_vm.sh http://$(url) $(nodec) $(node) 2>logs/$(url).log 1>&2

node_metric200: clean ## node_metric
	prometheus_url=$(prometheus_url) node_ip=$(nodem) bash $(current_dir)/script/get_node_metric.sh 2>logs/$@.log 1>&2
	make eni200
	sleep 60
	prometheus_url=$(prometheus_url) node_ip=$(nodem) bash $(current_dir)/script/get_node_metric.sh 2>>logs/$@.log 1>&2
	
node_metric400: clean ## node_metric
	prometheus_url=$(prometheus_url) node_ip=$(nodem) bash $(current_dir)/script/get_node_metric.sh 2>logs/$@.log 1>&2
	make eni400
	sleep 60
	prometheus_url=$(prometheus_url) node_ip=$(nodem) bash $(current_dir)/script/get_node_metric.sh 2>>logs/$@.log 1>&2
	
node_metric: clean ## node_metric
	prometheus_url=$(prometheus_url) node_ip=$(nodem) bash $(current_dir)/script/get_node_metric.sh 2>logs/$@.log 1>&2
	make eni100
	sleep 60
	prometheus_url=$(prometheus_url) node_ip=$(nodem) bash $(current_dir)/script/get_node_metric.sh 2>>logs/$@.log 1>&2
	
throughput_metric: deploy2 ##  throughput_metric
	prometheus_url=$(prometheus_url) bash -x $(current_dir)/script/run_network_throughput.sh 2>logs/$@.log 1>&2

pps_metric: deploy2 ##  pps_metric
	prometheus_url=$(prometheus_url) bash -x $(current_dir)/script/run_network_pps.sh 2>logs/$@.log 1>&2

connect_metric: deploy2 ##  connect_metric
	prometheus_url=$(prometheus_url) bash -x $(current_dir)/script/run_network_connect.sh 2>logs/$@.log 1>&2

service_metric: deploy1 fortio ##  service_metric
	prometheus_url=$(prometheus_url) bash -x $(current_dir)/script/run_network_service_short.sh 2>logs/$@.log 1>&2

asm_latency_tests: asm_latency_http asm_latency_grpc

asm_latency_http:
	default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_http.sh $(namespace) http://$(url) 2>logs/$(url)_http.log 1>&2

asm_latency_grpc:
	default_cluster=$(default_cluster) bash -x $(current_dir)/script/asm_latency_grpc.sh $(namespace) http://$(url) 2>logs/$(url)_grpc.log 1>&2
