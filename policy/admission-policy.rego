# make apply-policy
package kubernetes.admission

# Convenience variables (collapses JSON input)
request = input.request
kind = request.kind.kind
image = request.object.spec.containers[_].image
operation = request.operation
namespace = request.namespace
spec = request.object.spec
security_context = spec.securityContext
containers = spec.containers
resources = containers[_].resources

# Disallow API version
deny[msg] {
    request.options.apiVersion == "v0/deprecated"
    msg := sprintf("API version %s is deprecated", [request.options.apiVersion])
}

# Local development environment only
is_local_env(username) {
    username == "minikube-user"
}

deny[msg] {
    not is_local_env(request.userInfo.username)

    msg := "This operation is allowed only on Minikube"
}

# No forbidden namespaces
deny[msg] {
    namespace == "super-duper-secure"
    msg := "Cannot perform *any* operations re: the super-duper-secure namespace"
}
# make forbidden-namespace

# No new namespaces
is_namespace(kind) {
    kind == "Namespace"
}

is_create_operation(op) {
    op == "CREATE"
}

deny[msg] {
    is_namespace(kind)
    is_create_operation(operation)
    msg := "New namespaces are not allowed"
}
# make new-namespace

# No "latest" images
deny[msg] {
    endswith(image, "latest")
    msg := "No 'latest' images allowed"
}
# make latest-image

# No new resources in OPA's namespace
in_opa_namespace(ns) {
    ns == "opa"
}

deny[msg] {
    is_create_operation(operation)
    in_opa_namespace(namespace)

    msg := "No new resources in the 'opa' namespace"
}
# make opa-namespace-resource

# No containers from evilcorp.io registry; must come from gcr.io
deny[msg] {
    startswith(image, "evilcorp.io")
    not startswith(image, "gcr.io")

    msg := "Images from evilcorp.io cannot be used; must come from GCR"
}
# make bad-registry
# make good-registry

# No Always pull policy
deny[msg] {
    containers[_].imagePullPolicy == "Always"
    msg := "Image pull policy can't be Always"
}
# make pull-always
# make pull-ifnotpresent

# Disallow privilege escalation
deny[msg] {
    containers[_].securityContext.allowPrivilegeEscalation == true

    msg := "Privilege escalation is not allowed on any Pod"
}
# make privilege-escalation
# make no-privilege-escalation

# Disallow privileged containers
is_pod_security_policy(kind) {
    kind == "PodSecurityPolicy"
}

deny[msg] {
    is_pod_security_policy(kind)
    spec.privileged == true

    msg := "Privileged Pods not allowed"
}
# make privileged-pods
# make non-privileged-pods

# COMMENTS