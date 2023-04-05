#!/bin/sh
# Cleanup application
kubectl -n modelmesh-serving delete isvc/wisdom-primary isvc/wisdom-candidate
# Cleanup routemap
kubectl delete cm/wisdom
# Cleanup networking
kubectl delete svc/wisdom vs/wisdom
# Cleanup sleep utility
kubectl delete deploy/sleep cm/wisdom-input
