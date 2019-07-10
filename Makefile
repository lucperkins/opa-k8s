check-policy:
	opa check policy/admission-policy.rego

test: reset test-deployment

test-deployment:
	kubectl run \
		--generator=run-pod/v1 nginx \
		--image-pull-policy IfNotPresent \
		--image=nginx
	
	kubectl delete pods nginx

admission-controller-setup:
	scripts/admission-controller-setup.sh
	kubectl create namespace super-duper-secure

admission-controller-teardown:
	scripts/admission-controller-teardown.sh
	kubectl delete namespace super-duper-secure

apply-policy:
	kubectl -n opa create configmap k8s-admission-policy \
		--from-file policy/admission-policy.rego

unapply-policy:
	kubectl -n opa delete configmap k8s-admission-policy

reset: check-policy unapply-policy apply-policy

forbidden-namespace:
		kubectl run nginx \
		--namespace super-duper-secure \
		--generator=run-pod/v1 \
		--image=nginx:latest

bad-namespace:
	kubectl create namespace new-one

latest-image:
	kubectl run nginx \
		--generator=run-pod/v1 \
		--image=nginx:latest

opa-namespace-resource:
	kubectl -n opa create configmap new-cm \
		--from-file policy/system-main.rego

bad-registry:
	kubectl run evil-container \
		--generator=run-pod/v1 \
		--image=evilcorp.io/bitcoin-miner

good-registry:
	kubectl run good-container \
		--generator=run-pod/v1 \
		--image=gcr.io/google-samples/hello-app:2.0

pull-always:
	kubectl run always-pull \
		--generator=run-pod/v1 \
		--image=gcr.io/google-samples/hello-app:2.0 \
		--image-pull-policy Always

pull-ifnotpresent:
	kubectl run pull-if-not-present \
		--generator=run-pod/v1 \
		--image=gcr.io/google-samples/hello-app:2.0 \
		--image-pull-policy IfNotPresent

privilege-escalation:
	kubectl apply -f k8s/privilege-escalated-pod.yaml

no-privilege-escalation:
	kubectl apply -f k8s/no-privilege-escalation-pod.yaml

privileged-pods:
	kubectl apply -f k8s/privileged-pods.yaml

non-privileged-pods:
	kubectl apply -f k8s/non-privileged-pods.yaml