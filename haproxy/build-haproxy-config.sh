#!/bin/bash
# Check for two contexts
declare -a CONTEXTS
CONTEXTS=($(oc config get-contexts -o name))
if [ ${#CONTEXTS[@]} != 2 ]
then
    echo "Need two contexts in kubeconfig to continue"
    exit 1
fi

CONTEXT1=$(oc config get-contexts -o name | sed -n 1p)
CONTEXT2=$(oc config get-contexts -o name | sed -n 2p)
for cluster in $CONTEXT1 $CONTEXT2
  do
    oc --context=$cluster -n default create route edge wildcarddomain --service=test --port=8080 > /dev/null
  done
  WILDCARD_DOMAIN_CL1=$(oc --context=${CONTEXTS1} -n default get route wildcarddomain -o jsonpath='{.status.ingress[*].host}' | sed "s/wildcarddomain-default.\(.*\)/\1/g")
  WILDCARD_DOMAIN_CL2=$(oc --context=${CONTEXTS2} -n default get route wildcarddomain -o jsonpath='{.status.ingress[*].host}' | sed "s/wildcarddomain-default.\(.*\)/\1/g")
  for cluster in $CONTEXT1 $CONTEXT2 
  do
    oc --context=$cluster -n default delete route wildcarddomain > /dev/null
done

echo "Deploying HAProxy on ${CONTEXT1} cluster in namespace haproxy"
oc create ns haproxy --context ${CONTEXT1}
WORDPRESS_INGRESS=wordpress-ingress.${WILDCARD_DOMAIN_CL1}
oc --context=${CONTEXT1} -n haproxy create route edge haproxy-lb --service=haproxy-lb-service --port=8080 --insecure-policy=Allow --hostname=${HAPROXY_LB_ROUTE}
WORDPRESS_CLUSTER1=wordpress.${WILDCARD_DOMAIN_CL1}
WORDPRESS_CLUSTER2=wordpress.${WILDCARD_DOMAIN_CL2}
cp -pf haproxy.tmpl haproxy
sed -i "s/<wordpress_lb_hostname>/${WORDPRESS_INGRESS}/g" haproxy
sed -i "/option httpchk GET/a \ \ \ \ http-request set-header Host ${WORDPRESS_INGRESS}" haproxy
sed -i "s/<wordpress_lb_hostname>/${WORDPRESS_INGRESS}/g" haproxy
sed -i "s/<server1_name> <server1_wordpress_route>:<route_port>/cluster1 ${WORDPRESS_CLUSTER1}:80/g" haproxy
sed -i "s/<server2_name> <server2_wordpress_route>:<route_port>/cluster2 ${WORDPRESS_CLUSTER2}:80/g" haproxy
oc --context=${CONTEXT1} -n haproxy create configmap haproxy --from-file=haproxy
oc --context=${CONTEXT1} -n haproxy create -f haproxy-clusterip-service.yaml
oc --context=${CONTEXT1} -n haproxy create -f haproxy-deployment.yaml
echo "HAProxy setup completed"
echo "Replacing Route"
sed -i "s/host: wordpress.demo-sysdeseng.com/host: ${WORDPRESS_INGRESS}/g" ../application/wordpress/base/wordpress-route.yaml
