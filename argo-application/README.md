# Argo
We will assume that Argo has been installed on each cluster using either the YAML from the git repository of ArgoCD(https://github.com/argoproj/argo-cd/releases/tag/v1.6.1) or the ArgoCD operator. We will be installing ArgoCD on each cluster to have the highest uptime. Each cluster will operate independently of one another in regards to application management and placement.

# Argo Apps
Rather than creating the applications using the UI or via the Argo binary. YAML can be used to create the applications.

Export the KUBECONFIG and create the repository.
```
export KUBECONFIG=/home/user/west1/auth/kubeconfig:/home/user/west2/auth/kubeconfig
oc apply -f repo/application-repo.yaml
```

Next we will create the Application on our first cluster.
```
oc create -f west1/wordpress.yaml --context west1 -n argocd
```

Using the route defined within *application/wordpress/base/wordpress-route.yaml* and your web browser follow the procedure to install wordpress.

## Sync schedule
Follow the instructions for [enabling and scheduling snapshot mirroring](../storage-schedule.md).

# Define west2
Now you are ready to define West2. No replicas of the application are defined at that location so pods will not start.

```
oc create -f west2-subscription.yaml --context west2 -n argocd
```

# Scaling down west1
We are now ready to begin the process of switching to west2. Modify *application/wordpress/overlays/west1/wordpress-deployment.yaml* and *application/wordpress/overlays/west1/mysql-deployment.yaml* setting the replicas to 0. Push the changes to your git repository.

```
git commit -am 'site1 down'
git push origin master
```
