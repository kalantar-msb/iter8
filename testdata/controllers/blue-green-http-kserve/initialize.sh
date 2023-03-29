cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: wisdom
spec:
  externalName: modelmesh-serving.modelmesh-serving.svc.cluster.local
  sessionAffinity: None
  type: ExternalName
---
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
      - gvrShort: isvc
        name: wisdom-primary
        namespace: modelmesh-serving
    - weight: 40
      resources:
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
            - mesh
            hosts:
            - wisdom
            - wisdom.default
            - wisdom.default.svc.cluster.local
            http:
            - name: blue
              match:
              - uri:
                  prefix: /infer
              {{- if gt (index .Weights 1) 0 }}
                headers:
                  branch: 
                    exact: blue
              {{- end }}
              rewrite:
                uri: /v2/models/wisdom-primary/infer
              route:
              - destination:
                  host: wisdom.default.svc.cluster.local
                headers:
                  request:
                    set:
                      Host: wisdom.default.svc.cluster.local
                    {{- if gt (index .Weights 1) 0 }}
                    remove:
                    - branch
                    {{- end }}
            {{- if gt (index .Weights 1) 0 }}
            - name: green
              match:
              - headers:
                  branch: 
                    exact: green
                uri:
                  prefix: /infer
              rewrite:
                uri: /v2/models/wisdom-candidate/infer
              route:
              - destination:
                  host: wisdom.default.svc.cluster.local
                headers:
                  request:
                    set:
                      Host: wisdom.default.svc.cluster.local
                    remove:
                    - branch
            - name: split
              match:
              - uri:
                  prefix: /infer
              route:
              - destination:
                  host: wisdom.default.svc.cluster.local
                weight: {{ index .Weights 0 }}
                headers:
                  request:
                    set:
                      branch: blue
                      Host: wisdom.default
              - destination:
                  host: wisdom.default.svc.cluster.local
                weight: {{ index .Weights 1 }}
                headers:
                  request:
                    set:
                      branch: green
                      Host: wisdom.default
            {{- end }}
immutable: true            
EOF