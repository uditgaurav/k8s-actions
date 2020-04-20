FROM ubuntu:16.04

LABEL version="1.0.0"
LABEL name="Pod Delete"
LABEL repository="http://github.com/uditgaurav/k8s-actions"
LABEL homepage="http://github.com/uditgaurav/k8s-actions"

LABEL maintainer="Udit Gaurav <uditgaurav@gmail.com>"
LABEL com.github.actions.name="Kubernetes Pod Delete"
LABEL com.github.actions.description="Runs kubectl delete pod on a given namespace and name of pod. The config can be provided with the secret KUBE_CONFIG_DATA."
LABEL com.github.actions.icon="terminal"
LABEL com.github.actions.color="blue"

RUN apt-get update                                          \
  && apt-get -y --force-yes install --no-install-recommends     \
    wget                                                    \
    curl
ARG KUBECTL_VERSION=1.17.0
ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

COPY LICENSE README.md /
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["help"]
