# Argo Apps
Rather than creating the applications using the UI or via the Argo binary. YAML can be used to create the applications.

Export the KUBECONFIG of the environment or specify the context to use and then launch the application.
```
oc config use-context site1
oc create -f site1/wordpress.yaml -n argocd
oc config use-context site2
oc create -f site2/wordpress.yaml -n argocd
```
