#!/bin/sh
# replace primary with new version
cat <<EOF | kubectl replace -f -
apiVersion: "serving.kserve.io/v1beta1"
kind: "InferenceService"
metadata:
  name: wisdom-primary
  namespace: modelmesh-serving
  labels:
    app.kubernetes.io/name: wisdom
    app.kubernetes.io/version: v2
    iter8.tools/watch: "true"
  annotations:
    serving.kserve.io/deploymentMode: ModelMesh
    serving.kserve.io/secretKey: localMinIO
spec:
  predictor:
    model:
      modelFormat:
        name: sklearn
      storageUri: s3://modelmesh-example-models/sklearn/mnist-svm.joblib
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: wisdom-primary-weight
  labels:
    iter8.tools/watch: "true"
EOF
# delete candidate
kubectl delete isvc/wisdom-candidate cm/wisdom-candidate-weight
