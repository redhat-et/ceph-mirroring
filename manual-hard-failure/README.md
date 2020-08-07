# Manual Mirroring with Hard Site Failure - West 1 is down
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

# Hard Stop on west1
We are now ready to Bring Down West 1 - in AWS stop all instances.

## Force West 2 RBD Images to be Primary

```
sh-4.4$ rbd mirror image promote replicapool/mysql-pv-claim-wordpress8eedad3a-d8c8-11ea-9c51-0a580a810224 --force
Image promoted to primary
sh-4.4$ rbd mirror image promote replicapool/wp-pv-claim-wordpress8eed99f4-d8c8-11ea-9c51-0a580a810224 --force
Image promoted to primary
```

# Bringing up west2 application
It is now time to bring up west2. Modify *application/wordpress/overlays/west2/wordpress-deployment.yaml* and *application/wordpress/overlays/west2/mysql-deployment.yaml* setting the replicas to 1.

```
kubectl apply -k ../application/wordpress/overlays/west2 --context west2
```

# Returning to west1 (TBD)
