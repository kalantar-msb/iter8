cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: wisdom
  namespace: modelmesh-serving
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
  namespace: modelmesh-serving
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
# Create primary model
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
# Set up default routing
# The Iter8 traffic controller could do this, but don't rely on it
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: wisdom
  namespace: modelmesh-serving
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
# Create a routemap for canary use case
apiVersion: v1
kind: ConfigMap
metadata:
  name: wisdom
  namespace: modelmesh-serving
  labels:
    app.kubernetes.io/managed-by: iter8
    iter8.tools/kind: routemap
    iter8.tools/version: v0.14
data:
  strSpec: |
    variants: 
    - resources:
      - gvrShort: isvc
        name: wisdom-primary
    - weight: 100
      resources:
      - gvrShort: isvc
        name: wisdom-candidate
    # routing templates
    routingTemplates:
      wisdom-mirror:
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
                headers:
                  request:
                    set:
                      mm-vmodel-id: "wisdom-primary"
              mirror:
                host: modelmesh-serving.modelmesh-serving.svc.cluster.local
                  port:
                    number: 8033
              headers:
                  request:
                    set:
                      mm-vmodel-id: "wisdom-primary"
              mirrorPercentage:
                value: {{ index .Weights 1 }}
immutable: true            
EOF