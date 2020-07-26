# Advanced Cluster Management for Kubernetes
We will create various ACM applications which will be used to manage all of our storage and application objects.

## Deploying to West1
First we need to deploy the application to our first location.

```
export KUBECONFIG=/tmp/acm
oc create -f namespace.yaml
oc project wordpress
oc create -f channel.yaml
oc create -f application.yaml
oc create -f west1-subscription.yaml
oc create -f blog-west1.yaml
```

##
