#!/usr/bin/env bash

sudo snap install microk8s --classic --channel=1.21/stable

sudo usermod -a -G microk8s adminuser
sudo chown -f -R adminuser ~/.kube

sudo microk8s status --wait-ready
sudo microk8s enable dns storage ingress
# uncomment if gpu support is needed
#sudo microk8s enable gpu
sudo microk8s enable metallb:10.64.140.43-10.64.140.49,192.168.0.105-192.168.0.111

sudo snap install juju --classic

juju bootstrap microk8s micro --agent-version=2.9.22
juju add-model kubeflow
# copy the bundle from repo
juju deploy ./bundle.yaml

# TODO add to bundle
juju config dex-auth static-username=admin
juju config dex-auth static-password=admin123
juju config dex-auth public-url=http://10.64.140.43.nip.io/
juju config oidc-gatekeeper public-url=http://10.64.140.43.nip.io/
juju config minio secret-key=minio123

sudo microk8s kubectl patch role -n kubeflow istio-ingressgateway-operator -p '{"apiVersion":"rbac.authorization.k8s.io/v1","kind":"Role","metadata":{"name":"istio-ingressgateway-operator"},"rules":[{"apiGroups":["*"],"resources":["*"],"verbs":["*"]}]}'
