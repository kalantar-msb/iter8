cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: wisdom
spec:
  externalName: istio-ingressgateway.istio-system.svc.cluster.local
  sessionAffinity: None
  type: ExternalName
---
# use mesh gateway instead of this
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: wisdom-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - wisdom.modelmesh-serving
    - wisdom.modelmesh-serving.svc
    - wisdom.modelmesh-serving.svc.cluster.local
---
# Model component 1 - inferenceservice
apiVersion: "serving.kserve.io/v1beta1"
kind: "InferenceService"
metadata:
  name: wisdom-primary
  namespace: modelmesh-serving
  labels:
    app.kubernetes.io/name: wisdom
    app.kubernetes.io/version: v1
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
# Model component 2 - configmap to be used to configure weights at runtime
apiVersion: v1
kind: ConfigMap
metadata:
  name: wisdom-primary-weight
  labels:
    iter8.tools/watch: "true"
---
# Set up default routing (ie, to primary)
# The Iter8 traffic controller could do this, but don't rely on it
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: wisdom
spec:
  gateways:
  - wisdom-gateway
  hosts:
  - wisdom.modelmesh-serving
  - wisdom.modelmesh-serving.svc
  - wisdom.modelmesh-serving.svc.cluster.local
  http:
  - route:
    - destination:
        host: modelmesh-serving.modelmesh-serving.svc.cluster.local
        port:
          number: 8033
      headers:
        request:
          set:
            mm-vmodel-id: "wisdom-primary"
---
# Create routemap for blue-green use case
apiVersion: v1
kind: ConfigMap
metadata:
  name: wisdom
  labels:
    app.kubernetes.io/managed-by: iter8
    iter8.tools/kind: routemap
    iter8.tools/version: v0.14
data:
  strSpec: |
    variants: 
    - weight: 60
      resources:
      - gvrShort: cm
        name: wisdom-primary-weight
        namespace: modelmesh-serving
      - gvrShort: isvc
        name: wisdom-primary
        namespace: modelmesh-serving
    - weight: 40
      resources:
      - gvrShort: cm
        name: wisdom-candidate-weight
        namespace: modelmesh-serving
      - gvrShort: isvc
        name: wisdom-candidate
        namespace: modelmesh-serving
    # routing templates
    routingTemplates:
      blue-green-wisdom:
        gvrShort: vs
        template: |
          apiVersion: networking.istio.io/v1beta1
          kind: VirtualService
          metadata:
            name: wisdom
          spec:
            gateways:
            - wisdom-gateway
            hosts:
            - wisdom.modelmesh-serving
            - wisdom.modelmesh-serving.svc
            - wisdom.modelmesh-serving.svc.cluster.local
            http:
            - route:
              - destination:
                  host: modelmesh-serving.modelmesh-serving.svc.cluster.local
                  port:
                    number: 8033
                {{- if gt (index .Weights 1) 0 }}
                weight: {{ index .Weights 0 }}
                {{- end }}
                headers:
                  request:
                    set:
                      mm-vmodel-id: "wisdom-primary"
              {{- if gt (index .Weights 1) 0 }}
              - destination:
                  host: modelmesh-serving.modelmesh-serving.svc.cluster.local
                  port:
                    number: 8033
                weight: {{ index .Weights 1 }}
                headers:
                  request:
                    set:
                      mm-vmodel-id: "wisdom-candidate"
              {{- end }}
immutable: true   
EOF