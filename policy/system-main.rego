package system

# Imports the results of admission-policy.rego
import data.kubernetes.admission

# JSON object that gets returned to the API server
main = {
    "apiVersion": "admission.k8s.io/v1beta1",
    "kind": "AdmissionReview",
    "response": response,
}

# Response if admission.deny is false
default response = {"allowed": true}

# Response body when admission.deny is true
response = {
    "allowed": false,
    "status": {
        "reason": reason,
    },
} {
    reason = concat(", ", admission.deny)
    reason != ""
}