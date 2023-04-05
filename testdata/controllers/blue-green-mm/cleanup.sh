#!/bin/sh
# Cleanup application
kubectl -n modelmesh-serving delete isvc/wisdom-primary cm/wisdom-primary-weight
kubectl -n modelmesh-serving delete isvc/wisdom-candidate cm/wisdom-candidate-weight
# Cleanup routemap(s)
kubectl delete cm/wisdom
# Cleanup networking
kubectl delete svc/wisdom gateway/wisdom-gateway virtualservice/wisdom
# Cleanup sleep utility
kubectl delete deploy/sleep cm/wisdom-input
