
kubectl logs -n blackduck \
 $(kubectl get pods --selector=job-name=$(kubectl get jobs -n blackduck | tail -n 1 | awk '{print $1}') --output=jsonpath={.items[*].metadata.name} -n blackduck)
