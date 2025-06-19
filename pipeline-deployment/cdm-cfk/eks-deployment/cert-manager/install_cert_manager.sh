#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

function install_cert_mgr(){
        kubectl create namespace cdm-cert-manager

        echo "Installing cdm-cert-manager ... "
        echo "Notice : This can take some time to create keys depending on how much entropy the system has."
        helm install cert-manager jetstack/cert-manager \
                --namespace cdm-cert-manager \
                --create-namespace \
                --version v1.17.2 \
                --set crds.enabled=true  \
                --set extraArgs="{--feature-gates=AdditionalCertificateOutputFormats=true}"  \
                --set webhook.extraArgs="{--feature-gates=AdditionalCertificateOutputFormats=true}" \
                --set prometheus.enabled=false \
                --set webhook.timeoutSeconds=1
}

function apply_cert_mgr(){
        kubectl apply -f ./config/conf_cert-manager_pki.yaml
}

function uninstall_cert_mgr(){
        helm uninstall cert-manager -n cdm-cert-manager
        kubectl delete namespace cdm-cert-manager
}

install_cert_mgr
apply_cert_mgr

