# Enabling Snapshot Mirroring for Images
Once your application is deployed and the images appear in the CephBlockPool you will need to enable the images for mirroring.
This only *NEEDS* to be enabled on the current Primary Cluster (On initial installation that is the cluster that was create bootstrapped.

### Identify the Images in the CephBlockPool
```
$ oc rsh -n rook-ceph --context west1 `oc get pods -n rook-ceph --context west1 | grep rook-ceph-tools | awk '{print $1}'`
$ rbd ls replicapool
mysql-pv-claim-wordpress3ad289a1-cece-11ea-8e1a-0a580a81021a
wp-pv-claim-wordpress3ad28968-cece-11ea-8e1a-0a580a81021a
```

### Enable Snapshot Mirroring of the Images on Primary Cluster Only (i.e. west1)
```
$ rbd mirror image enable replicapool/mysql-pv-claim-wordpress3ad289a1-cece-11ea-8e1a-0a580a81021a snapshot
Mirroring enabled
```

```
$ rbd mirror image enable replicapool/wp-pv-claim-wordpress3ad28968-cece-11ea-8e1a-0a580a81021a snapshot
Mirroring enabled
```

NOTE: The image name will vary when deployed on your environment.
NOTE: This step only happens on the Primary Mirrored Cluster.



# Add a Snapshot Schedule for Both Clusters Images
By default no schedule is set on the mirrored storage. The following steps must be performed.


### Add a Snapshot Schedule for Primary Cluster (i.e. west1)

```
$ rbd mirror snapshot schedule add --pool replicapool --image mysql-pv-claim-wordpress3ad289a1-cece-11ea-8e1a-0a580a81021a 1m
$ rbd mirror snapshot schedule add --pool replicapool --image  wp-pv-claim-wordpress3ad28968-cece-11ea-8e1a-0a580a81021a1m 1m
```

### Also Add a Snapshot Schedule for Secondary Clsuter Images (i.e. west2)
 
```
$ oc rsh -n rook-ceph --context west1 `oc get pods -n rook-ceph --context west1 | grep rook-ceph-tools | awk '{print $1}'`
$ rbd mirror snapshot schedule add --pool replicapool --image mysql-pv-claim-wordpress3ad289a1-cece-11ea-8e1a-0a580a81021a 1m
$ rbd mirror snapshot schedule add --pool replicapool --image  wp-pv-claim-wordpress3ad28968-cece-11ea-8e1a-0a580a81021a1m 1m
```


# Validating the Schedule
```
$ oc rsh -n rook-ceph --context west1 `oc get pods -n rook-ceph --context west1 | grep rook-ceph-tools | awk '{print $1}'`
$ rbd mirror snapshot schedule ls --pool replicapool --recursive
```

