# Github Action for Kubernetes Pod Delete

This action provides `kubectl delete pod <pod-name> -n <namespace>` for Github Actions.

## Usage

`.github/workflows/main.yml`

```yaml
name: CI

on:
  push:
    branches: [ master ]

jobs:
  build:
    
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@master
    
    - name: Running ubuntu command
      run: ls -ltr

    - name: Delete pod from the kubernetes cluster
      uses: uditgaurav/k8s-actions@master
      env:
        KUBE_CONFIG_DATA: ${{ secrets.KUBE_CONFIG_DATA }}
        POD_DELETE: nginx-7db9fccd9b-7q7bm  ## POD-NAME
        NAMESPACE: litmus ## NAMESPACE OF POD
```

## Secrets

`KUBE_CONFIG_DATA` – **required**: A base64-encoded kubeconfig file with credentials for Kubernetes to access the cluster. You can get it by running the following command:

```bash
cat $HOME/.kube/config | base64
```

## Environment

`KUBECTL_VERSION` - (optional): Used to specify the kubectl version. If not specified, this defaults to kubectl 1.13

`POD_NAME` - (Mandatory): Used to get get pod name which has to be deleted

`NAMESPACE` - (Mandatory): Used to get the namespace which we have to delete
