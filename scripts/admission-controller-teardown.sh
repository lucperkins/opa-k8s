#!/bin/bash

kubectl -n opa delete secret tls opa-server
kubectl delete -f k8s/admission-controller.yaml
kubectl -n opa delete configmap opa-default-system-main
kubectl delete -f k8s/webhook-configuration.yaml
kubectl delete namespace opa
