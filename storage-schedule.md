# Mirroring schedule
By default no schedule is set on the mirrored storage. The following steps must be performed. 

NOTE: The image name will vary when deployed on your environment.

```
$ oc rsh -n rook-ceph --context west1 `oc get pods -n rook-ceph --context west1 | grep rook-ceph-tools | awk '{print $1}'`
$ rbd ls replicapool
mysql-pv-claim-wordpress3ad289a1-cece-11ea-8e1a-0a580a81021a
wp-pv-claim-wordpress3ad28968-cece-11ea-8e1a-0a580a81021a

$ rbd mirror image enable replicapool/mysql-pv-claim-wordpress3ad289a1-cece-11ea-8e1a-0a580a81021a snapshot
Mirroring enabled

$ rbd mirror image enable replicapool/wp-pv-claim-wordpress3ad28968-cece-11ea-8e1a-0a580a81021a snapshot
Mirroring enabled

$ rbd mirror snapshot schedule add --pool replicapool --image mysql-pv-claim-wordpress3ad289a1-cece-11ea-8e1a-0a580a81021a 1m
$ rbd mirror snapshot schedule add --pool replicapool --image  wp-pv-claim-wordpress3ad28968-cece-11ea-8e1a-0a580a81021a1m 1m
```

```
$ oc rsh -n rook-ceph --context west1 `oc get pods -n rook-ceph --context west1 | grep rook-ceph-tools | awk '{print $1}'`
$ rbd mirror snapshot schedule add --pool replicapool --image mysql-pv-claim-wordpress3ad289a1-cece-11ea-8e1a-0a580a81021a 1m
$ rbd mirror snapshot schedule add --pool replicapool --image  wp-pv-claim-wordpress3ad28968-cece-11ea-8e1a-0a580a81021a1m 1m
```

### Validating the schedule
```
$ oc rsh -n rook-ceph --context west1 `oc get pods -n rook-ceph --context west1 | grep rook-ceph-tools | awk '{print $1}'`
$ rbd mirror snapshot schedule ls --pool replicapool --recursive
```

