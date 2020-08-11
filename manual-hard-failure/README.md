# Manual Mirroring with Hard Site Failure - West 1 is down, How to Recover?
The steps defined in this README will walk through the process of deploy the application and failing over to another site manually.

**NOTE:** Before beginning ensure that you modify *application/wordpress/base/wordpress-route.yaml* to point to your Load balancer.

**NOTE:** Using a GitOps tool like Argo CD or Tekton can help to manage the flow of the applications and data in this scenario, for example, when the primary site goes down and when it comes back up, having a tool watching your configuration repo will give more control on when an application is run.


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

# Hard Stop on west1 and Recovery
We are now ready to Bring Down West 1 - in AWS stop all instances.

**NOTE** *IMPORTANT*
Once the primary site goes down (non-gracefully), we have a few issues to sort out.
- Any data NOT SYNC'd during the failure will most likely be lost
- Once detected, we have a split brain scenario where a decision has to be made as to which data set (west1 or west2) will become our "best" data
- Since the application is still running on west1 and RBD still thinks it is the primary data set, once we bring back up we need to immediately stop the application so we can resolve the split brain as best as we can
- Having a GitOps type of tool in this scenario could help with controlling the application from running automatically

Below steps will describe the best path to recovery in this situation

## West 1 is Down, Force West 2 RBD Images to be Primary

```
sh-4.4$ rbd mirror pool promote --force replicapool
2 Images promoted to primary
```

## Bringing up west2 application
It is now time to bring up west2. Modify *application/wordpress/overlays/west2/wordpress-deployment.yaml* and *application/wordpress/overlays/west2/mysql-deployment.yaml* setting the replicas to 1.

```
kubectl apply -k ../application/wordpress/overlays/west2 --context west2
```
The load balancer will now be directing any new traffic and inputs to West 2

# Returning to West 1 and Recovering to the Primary
As mentioned above, when West 1 starts to come back (assuming there is not a major rebuild of the cluster), it will still think the application should be running
as well as it is the Primary data source.

## Stop the Application on West 1 once it comes back on-line
Simply scale down the application by setting the replicas to 0 and then apply the Kustomize template overlays

```
kubectl apply -k ../application/wordpress/overlays/west1 --context west1
```

## Force the demotion of the RBD Images on West 1
```
sh-4.4$ rbd mirror pool demote replicapool
2 Images demoted to non-primary
```

## Resync the Images From West2 to West1
Flagging the images for *resync* will get all the data that was now flowing into West 2 during the failure outage.

**NOTE:** This can take some time as the images are basically deleted and recreated on EACH resync issued command.
         If it is a large data set and the outage was long, it might make sense to do a full maintenance window to restore the new images
         also bringing down all applications so NO NEW DATA can flow to the Primary.

```
sh-4.4$ rbd mirror pool resync replicapool
2 Images Flagged for Resync From Primary
```
Wait until the images come back clean and you can get a status on them on West 1

```
$ rbd mirror image status replicapool/mysql-pv-claim-wordpress74c9bc4e-db23-11ea-ad27-0a580a800214
[should give a clean status]

OR

$ rbd ls replicapool
[should show your images]
```

## Stop the Application on West 2 and Demote the Pool Images
Simply scale down the application by setting the replicas to 0 and then apply the Kustomize template overlays

```
kubectl apply -k ../application/wordpress/overlays/west2 --context west2
```

**NOTE:** At this point, no applications are running

Demote the Images

```
sh-4.4$ rbd mirror pool demote replicapool
2 Images demoted to non-primary
```

## Promote the Images on West 1 and Scale the Application Back Up

```
sh-4.4$ rbd mirror pool promote replicapool
2 Images promoted to primary
```

Scale up the application by setting the replicas to 1 and then apply the Kustomize template overlays

```
kubectl apply -k ../application/wordpress/overlays/west1 --context west1
```
