# Argo
We will assume that Argo has been installed on each cluster using either the YAML from the git repository of ArgoCD(https://github.com/argoproj/argo-cd/releases/tag/v1.6.1) or the ArgoCD operator. We will be installing ArgoCD on each cluster to have the highest uptime. Each cluster will operate independently of one another in regards to application management and placement. 

NOTE: Before beginning fork this repository and modify the following files as they relate to your repository.

```
./repo/application-repo.yaml
./site-change/both.yaml 
./site-sync/sync.yaml 
./west1/wordpress.yaml 
./west2/wordpress.yaml
```

# Argo Apps
Rather than creating the applications using the UI or via the Argo binary. YAML can be used to create the applications. Some extra permissions have been given to the Argo CD service account because we would like it to have full management control of our cluster.

Export the KUBECONFIG and create the repository.
```
export KUBECONFIG=/home/user/west1/auth/kubeconfig:/home/user/west2/auth/kubeconfig
oc apply -f repo/application-repo.yaml --context west1 -n argocd
oc apply -f repo/application-repo.yaml --context west2 -n argocd
oc apply -f argocd-extra-permissions --context west1 -n argocd
oc apply -f argocd-extra-permissions --context west2 -n argocd
```

NOTE: Before beginning ensure that you modify *application/wordpress/base/wordpress-route.yaml* to point to your Load balancer and push to your git repository.

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
oc create -f west2/wordpress.yaml --context west2 -n argocd
```

# Scaling down west1
We are now ready to begin the process of switching to west2. Modify *application/wordpress/overlays/west1/wordpress-deployment.yaml* and *application/wordpress/overlays/west1/mysql-deployment.yaml* setting the replicas to 0. Push the changes to your git repository.

```
git commit -am 'site1 down'
git push origin master
```

## Sync
Define the sync within *west2* cluster of ArgoCD. This will cause the storage to sync from the primary to the standby cluster.
```
oc create -f site-sync/sync.yaml --context west2 -n argocd
```

## Switching primary sites
It is now time to define the ArgoCD application which will launch a job to switch the primary and standby sites. A sleep has been added to this step to ensure that the sync from the previous step has completed.
```
sleep 3m
oc create -f site-change/both.yaml --context west1 -n argocd
oc create -f site-change/both.yaml --context west2 -n argocd
```

# Bringing up west2
It is now time to bring up west2. Modify *application/wordpress/overlays/west2/wordpress-deployment.yaml* and *application/wordpress/overlays/west2/mysql-deployment.yaml* setting the replicas to 1. Push the changes to your git repository.

```
git commit -am 'site2 up'
git push origin master
```

ArgoCD will automatically deploy the application. Once the application pods have started you can use the route defined in *application/wordpress/base/wordpress-route.yaml* to validate that the application is indeed running on west2.

# Returning to west1
To return to west1 the process is somewhat similar. Modify *application/wordpress/overlays/west2/wordpress-deployment.yaml* and *application/wordpress/overlays/west2/mysql-deployment.yaml* setting the replicas to 0. Push the changes to your git repository

```
git commit -am 'site2 down'
git push origin master
```

## Syncing the storage
We will delete the sync application from *west2* and move it to *west1*.

```
oc delete -f site-sync/sync.yaml --context west2 -n argocd
oc create -f site-sync/sync.yaml --context west1 -n argocd
```

This will cause the sync job to be launched on west1.


## Switching primary sites
The application is already defined in ArgoCD which will trigger the standby to become primary but we need to modify the job number and commit the code. This will cause a new job to be launched on the west sites. We will increase the number at the end of the job name by 1.

```
sleep 3m
vi rbd-jobs/both/all-in-one.yaml
..redacted..
  name: total-job-16
```

Commit the code which will force the job to create.
```
git commit -am 'launch of job to promote
git push origin master
```

# Bringing up west1
It is now time to bring back west1. Modify *application/wordpress/overlays/west1/wordpress-deployment.yaml* and *application/wordpress/overlays/west1/mysql-deployment.yaml* setting the replicas to 1. Push the changes to your git repository.

```
git commit -am 'site1 up'
git push origin master
```

This will trigger the west1 pods to launch. This will conclude the fail back to west1 and all of our data should be present.
