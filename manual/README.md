# Manual Mirroring
The steps defined in this README will walk through the process of deploy the application and failing over to another site manually.

NOTE: Before beginning ensure that you modify *application/wordpress/base/wordpress-route.yaml* to point to your Load balancer.

## Deploying West1
We will use *kubectl* due to the application files being in Kustomize.

```
kubectl apply -k ../application/wordpress/overlays/west1 --context west1
```

## Install wordpress
Using the route defined within *application/wordpress/base/wordpress-route.yaml* and your web browser follow the procedure to install wordpress.

## Sync schedule
Follow the instructions for [enabling and scheduling snapshot mirroring](../storage-schedule.md).

## Access the App and Add Some Data
From a browser should be able to access via [http://wordpress.octo.eng.rdu2.redhat.com/](http://wordpress.octo.eng.rdu2.redhat.com/)



# Define west2
Now you are ready to define West2. No replicas of the application are defined at that location so pods will not start.

```
kubectl apply -k ../application/wordpress/overlays/west2 --context west2
```

# Scaling down west1
We are now ready to begin the process of switching to west2. Modify *application/wordpress/overlays/west1/wordpress-deployment.yaml* and *application/wordpress/overlays/west1/mysql-deployment.yaml* setting the replicas to 0.

```
kubectl apply -k ../application/wordpress/overlays/west1 --context west1
```

## Sync
We will deploy the sync job into the *west2* environment. This will launch a Kubernetes job.

```
kubectl create -f rbd-jobs/standby/ --context west2
```

## Switching primary sites
It is now time to switch the primary and standby sites. A sleep has been added to this step to ensure that the sync from the previous step has completed.
```
sleep 3m
oc create -f rbd-jobs/both/ --context west1
oc create -f rbd-jobs/both/ --context west2
```

# Bringing up west2
It is now time to bring up west2. Modify *application/wordpress/overlays/west2/wordpress-deployment.yaml* and *application/wordpress/overlays/west2/mysql-deployment.yaml* setting the replicas to 1.

```
kubectl apply -k ../application/wordpress/overlays/west2 --context west2
```

# Returning to west1
To return to west1 the process is somewhat similar. Modify *application/wordpress/overlays/west2/wordpress-deployment.yaml* and *application/wordpress/overlays/west2/mysql-deployment.yaml* setting the replicas to 0.

```
kubectl apply -k ../application/wordpress/overlays/west2 --context west2
```

## Syncing the storage
We will modify the sync job, removing it from west2 and launching it on west1.

```
kubectl delete -f rbd-jobs/standby/ --context west2
kubectl create -f rbd-jobs/standby/ --context west1
```

## Switching primary sites
To launch the switching of sites job again, we will bump the job number up by one and then launch the job on both clusters.

```
vi rbd-jobs/both/all-in-one.yaml
..redacted..
  name: total-job-17
```

```
sleep 3m
oc create -f rbd-jobs/both/ --context west1
oc create -f rbd-jobs/both/ --context west2
```

# Bringing up west1
It is now time to bring back west1. Modify *application/wordpress/overlays/west1/wordpress-deployment.yaml* and *application/wordpress/overlays/west1/mysql-deployment.yaml* setting the replicas to 1.

```
kubectl apply -k ../application/wordpress/overlays/west1 --context west1
```
This will trigger the west1 pods to launch. This will conclude the fail back to west1 and all of our data should be present.
