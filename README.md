# Before starting
Fork this repository. Ensure two clusters have already been deployed. The kubeconfigs must be modified to allow them to be identified with unique contexts. By default, clusters are deployed with the context name of admin. We will modify that to have the example name of *west1* and *west2*. Once that has been done we will export the configuration and validate we have two contexts.

```
sed -i 's/admin/west1/g' west1/auth/kubeconfig
sed -i 's/admin/west2/g' west2/auth/kubeconfig
export KUBECONFIG=/home/user/west1/auth/kubeconfig:/home/user/west2/auth/kubeconfig
oc config get-contexts
CURRENT   NAME    CLUSTER   AUTHINFO   NAMESPACE
*         west1   west1     west1      
          west2   west2     west2      
```

# Application Endpoint
Because two clusters are required for this demonstration a Load Balancer has to be used to route traffic to the cluster running our sample applciation. This Load Balancer could be either be an internal offering such as a F5 or a global load balancing solution such as Cloudflare.

Perform the steps that relate to your Load Balancing solution.

## Global Load Balancer
Define the URL that will be used for the application. For example, a route could be wordpress.example.com. This route would be defined within the Global Load Balacing service. A health check should be established to check the health of the sites. 

NOTE: A TCP check will give you a false positive healthy cluster so it is suggested to use a HTTP check.


```
sed -i 's/wordpress.demo-sysdeseng.com/wordpress.example.com/g' application/wordpress/base/wordpress-route.yaml
```

Commit the new route to your git repository.
```
git commit -am 'changing route'
git push origin master
```


## HAProxy
This should be used only if you have no other load balancer available. An HAProxy instance will run on one of your clusters. It will route traffic as needed between the two clusters depending on where the application is placed.  This solution is not production capable! If the cluster in which HAproxy goes down then the application will not be routable because there is no HAProxy running on the second cluster.

```
cd haproxy
sh build-haproxy-config.sh
```

Commit the new route to your git repository.
```
git commit -am 'changing route'
git push origin master
```

# ceph-mirroring
The goal of this repository is to allow for users to create workflows using available tooling to migrate an application from one cluster to another cluster. This demonstration requires that two clusters have been created and connectivity exists between the two host neworks.

## Ceph mirroring setup
Ensure the following ports are opened between both sites.
* 4500
* 6789
* 3300
* 6800-7300

## Establishing mirroring
The following files must be deployed on both clusters to deploy the ceph mirroring objects. A disk is requested using the storageclass. If the *storageclass* is not gp2 modify the file *ceph-deployment/cluster-1.3.6-pvc.yaml* replacing *gp2* with your *storageclass*. This may differ between clusters as well especially in a Hybrid cloud. One site may have a *storageclass* named *standard* while another may have a storage class named *thin*. Verify the name of the *storageclass* for your cluster before deploying.

```
oc get sc --context west1
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   true                   4h35m

oc get sc --context west2
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   true                   4h35m
```

(Optional) If required make the following change.

```
vi ceph-deployment/cluster-1.3.6-pvc.yaml

    volumeClaimTemplate:
      spec:
        storageClassName: gp2
```

### Creating the ceph objects
Deploy the following yamls on both clusters.
```
oc create -f ceph-deployment/common.yaml --context west1
oc create -f ceph-deployment/common.yaml --context west2
```

```
oc create -f ceph-deployment/cluster-1.3.6-pvc.yaml --context west1
oc create -f ceph-deployment/cluster-1.3.6-pvc.yaml --context west2
```

```
oc create -f ceph-deployment/operator-openshift.yaml --context west1
oc create -f ceph-deployment/operator-openshift.yaml --context west2
```

It will take a few minutes for all of the components to deploy and for the disks to be formatted.


### Launch the toolbox
The toolbox pod is required to interact and configure storage. To deploy the toolbox run the following.

```
oc create -f ceph-deployment/post-deploy/toolbox.yaml --context west1 -n rook-ceph
oc create -f ceph-deployment/post-deploy/toolbox.yaml --context west2 -n rook-ceph
```

Create the replica pool.
```
oc create -f ceph-deployment/post-deploy/pool.yaml --context west1 -n rook-ceph
oc create -f ceph-deployment/post-deploy/pool.yaml --context west2 -n rook-ceph
```


### Enable the replica pool
On west1 run the following in the toolbox:
```
oc rsh -n rook-ceph --context west1 `oc get pods -n rook-ceph --context west1 | grep rook-ceph-tools | awk '{print $1}'`
rbd mirror pool enable replicapool image
rbd pool init replicapool
```

On west2 run the following in the toolbox:
```
oc rsh -n rook-ceph --context west2 `oc get pods -n rook-ceph --context west2 | grep rook-ceph-tools | awk '{print $1}'`
rbd mirror pool enable replicapool image
rbd pool init replicapool
```

### Bootstrap the cluster peers
A token will be generated on west1 which needs to be applied to west2.

```
oc rsh -n rook-ceph --context west1 `oc get pods -n rook-ceph --context west1 | grep rook-ceph-tools | awk '{print $1}'`
rbd mirror pool peer bootstrap create --site-name west1 replicapool
eyJmc2lkIjoiNmYyZTMxNmYtMzgxZi00MTI4LTkwODEtMWY4NzdhNzZjNmYzIiwiY2xpZW50X2lkIjoicmJkLW1pcnJvci1wZWVyIiwia2V5IjoiQVFDQURSZGZzRkx3RnhBQW9Ha2VpdkRBdWpaTktvOHBWUm5CQXc9PSIsIm1vbl9ob3N0IjoiMTAuMC4yMzcuMjQ4OjY3ODksMTAuMC4xNjIuMTAyOjY3ODksMTAuMC4xMzIuNDU6Njc4OSJ9
```

Using the value of the generated token place the output into the file */tmp/token* on west2 and then import the file.
```
oc rsh -n rook-ceph --context west2 `oc get pods -n rook-ceph --context west2 | grep rook-ceph-tools | awk '{print $1}'`
vi /tmp/token
eyJmc2lkIjoiNmYyZTMxNmYtMzgxZi00MTI4LTkwODEtMWY4NzdhNzZjNmYzIiwiY2xpZW50X2lkIjoicmJkLW1pcnJvci1wZWVyIiwia2V5IjoiQVFDQURSZGZzRkx3RnhBQW9Ha2VpdkRBdWpaTktvOHBWUm5CQXc9PSIsIm1vbl9ob3N0IjoiMTAuMC4yMzcuMjQ4OjY3ODksMTAuMC4xNjIuMTAyOjY3ODksMTAuMC4xMzIuNDU6Njc4OSJ9

rbd mirror pool peer bootstrap import --site-name west2 replicapool /tmp/token
```

### Validate the pool status

```
oc rsh -n rook-ceph --context west1 `oc get pods -n rook-ceph --context west1 | grep rook-ceph-tools | awk '{print $1}'`
sh-4.4$ rbd mirror pool info replicapool --all
Mode: image
Site Name: west1

Peer Sites: 

UUID: 911e08fa-5d50-45db-b35b-7737781029b7
Name: west2
Mirror UUID: 6d64ccb7-27f2-466c-8a86-d7926cfe906b
Direction: rx-tx
Client: client.rbd-mirror-peer
Mon Host: 10.2.160.152:6789,10.2.151.100:6789,10.2.208.221:6789
Key: AQCjDhdflMlIDhAA+qI9dEzthQAz9q+RKuh6Cw==
```

```
oc rsh -n rook-ceph --context west2 `oc get pods -n rook-ceph --context west2 | grep rook-ceph-tools | awk '{print $1}'`
sh-4.4$ rbd mirror pool info replicapool --all
Mode: image
Site Name: west2

Peer Sites: 

UUID: e45f5bfd-8e01-4f43-a16b-2ee29ff0ed47
Name: west1
Mirror UUID: b86d777b-30f9-43f2-9d46-b2d922c10870
Direction: rx-tx
Client: client.rbd-mirror-peer
Mon Host: 10.0.237.248:6789,10.0.162.102:6789,10.0.132.45:6789
Key: AQCADRdfsFLwFxAAoGkeivDAujZNKo8pVRnBAw==
```

### Modifying the provisioner
An extra flag is required to ensure that all of the metadata is provided when creating PVC objects to be mirrored. Add *- --extra-create-metadata=true* to the args section of the deploy. 
```
oc edit deploy csi-rbdplugin-provisioner -n rook-ceph --context west1
..redacted..
      - args:
        - --csi-address=$(ADDRESS)
        - --v=0
        - --timeout=150s
        - --retry-interval-start=500ms
        - --enable-leader-election=true
        - --leader-election-type=leases
        - --leader-election-namespace=rook-ceph
        - --extra-create-metadata=true
```

```
oc edit deploy csi-rbdplugin-provisioner -n rook-ceph --context west2
..redacted..
      - args:
        - --csi-address=$(ADDRESS)
        - --v=0
        - --timeout=150s
        - --retry-interval-start=500ms
        - --enable-leader-election=true
        - --leader-election-type=leases
        - --leader-election-namespace=rook-ceph
        - --extra-create-metadata=true
```

### Creating the StorageClass
Now that the pools have been established the storage class must be created to be used by applications.

```
oc create -f ceph-deployment/post-deploy/storageclass.yaml --context west1
oc create -f ceph-deployment/post-deploy/storageclass.yaml --context west2
```

# Application deployment and management
Depending on what tooling is available in your clusters the option exists to use the following tools. Follow the directions in the different subdirectories to deploy the required compontents to be used for applciation management.

[Advanced Cluster Management For Kubernetes Steps](./acm-application-configuration)

[ArgoCD](./argo-applications)

[Tekton](./tekton)

[Manual](./application)

