# Before starting
Fork this repository. Once the repository has been forked run the following sed to replace the DNS values as it relates to your domain name. This is because we need to set a value to be used by our GLB or Haproxy.

```
sed -i 's/demo-sysdeseng.com/yourdomain.com/g
```


# ceph-mirroring
The goal of this repository is to allow for users to create workflows using available tooling to migrate an application from one cluster to another cluster. This demonstration requires that two clusters have been created and connectivity exists between the two host neworks.

## Ceph mirroring setup
Ensure the following ports are opened between both sites.
* 4500
* 6789
* 3300
* 6800-7300

On both sites create the following objects.
```
oc create -f rook-ceph-mirroring/common.yaml
oc create -f rook-ceph-mirroring/operator-openshift.yaml
oc create -f rook-ceph-mirroring/cluster-1.3.6-pvc.yaml
```

## Establishing mirrroring
TBD


# Application deployment and management
Depending on what tooling is available in your clusters the option exists to use the following tools. Follow the directions in the different subdirectories to deploy the required compontents to be used for applciation management.

[Advanced Cluster Management For Kubernetes Steps](./acm-application-configuration)
[ArgoCD](./argo-applications)
[Tekton](./tekton)

## 
