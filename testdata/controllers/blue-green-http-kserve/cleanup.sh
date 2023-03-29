#!/bin/sh
kubectl -n modelmesh-serving delete isvc wisdom-primary wisdom-candidate
kubectl delete deploy sleep
kubectl delete svc wisdom
kubectl delete virtualservice wisdom
kubectl delete cm wisdom wisdom-input
