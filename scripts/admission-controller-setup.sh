#!/bin/bash

# Certs
CA_CERT=certs/ca.crt
CA_BUNDLE=$(cat $(CA_CERT) | base64 | tr -d '\n')
WEBHOOK_CONFIG=k8s/webhook-configuration.yaml

kubectl create namespace opa
kubectl -n opa create secret tls opa-server --cert=certs/server.crt --key=certs/server.key

kubectl create -f k8s/admission-controller.yaml
kubectl -n opa create configmap opa-default-system-main --from-file=policy/system-main.rego

cat > ${WEBHOOK_CONFIG} <<EOF
kind: ValidatingWebhookConfiguration
apiVersion: admissionregistration.k8s.io/v1beta1
metadata:
  name: opa-validating-webhook
webhooks:
  - name: validating-webhook.openpolicyagent.org
    namespaceSelector:
      matchExpressions:
      - key: openpolicyagent.org/webhook
        operator: NotIn
        values:
        - ignore
    rules:
      - operations: ["CREATE", "UPDATE"]
        apiGroups: ["*"]
        apiVersions: ["*"]
        resources: ["*"]
    clientConfig:
      caBundle: ${CA_BUNDLE}
      service:
        namespace: opa
        name: opa
EOF

kubectl create -f ${WEBHOOK_CONFIG}