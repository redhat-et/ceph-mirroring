# Argo
We will assume that Argo has been installed on each cluster using either the YAML from the git repository of ArgoCD(https://github.com/argoproj/argo-cd/releases/tag/v1.6.1) or the ArgoCD operator. We will be installing ArgoCD on each cluster to have the highest uptime. Each cluster will operate independently of one another in regards to application management and placement.

# Argo Apps
Rather than creating the applications using the UI or via the Argo binary. YAML can be used to create the applications.

Export the KUBECONFIG and create the repository.
```
export KUBECONFIG=~/go/src/github.com/dimaunx/ocpup/.config/cl1/auth/kubeconfig:~/git/sleepy-admin/submariner/submariner-aws/auth/kubeconfig
oc apply -f repo/application-repo.yaml
```

Next we will create the Application on our first cluster.
```
oc create -f west1/wordpress.yaml

