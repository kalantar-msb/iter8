---
template: main.html
---

# Your First Experiment

!!! tip "Scenario: Safely rollout a Kubernetes deployment with SLO validation"
    Deploy a K8s application (service and deployment), and [validate that the application satisfies latency and error-based objectives (SLOs)](../concepts/buildingblocks.md#slo-validation).
    
??? warning "Setup K8s cluster and local environment"
    1. Get [Helm 3.4+](https://helm.sh/docs/intro/install/).
    2. Setup [K8s cluster](setup-for-tutorials.md#local-kubernetes-cluster)
    3. [Install Iter8 in K8s cluster](install.md)
    4. Get [`iter8ctl`](install.md#get-iter8ctl)
    5. Fork the [Iter8 GitHub repo](https://github.com/iter8-tools/iter8). Clone your fork, and set the ITER8 environment variable as follows.
    ```shell
    export USERNAME=<your GitHub username>
    ```
    ```shell
    git clone git@github.com:$USERNAME/iter8.git
    cd iter8
    export ITER8=$(pwd)
    ```

## 1. Create application
The `hello world` app consists of a K8s deployment and service. Deploy them as follows.

```shell
kubectl apply -f $ITER8/samples/deployments/app/deploy.yaml
kubectl apply -f $ITER8/samples/deployments/app/service.yaml
```

??? note "Verify app is running"
    ```shell
    # do this in a separate terminal
    kubectl port-forward svc/hello 8080:8080
    ```

    ```shell
    curl localhost:8080
    ```

    ```
    # output will be similar to the following (notice 1.0.0 version tag)
    # hostname will be different in your environment
    Hello, world!
    Version: 1.0.0
    Hostname: hello-bc95d9b56-xp9kv
    ```

## 2. Create Iter8 experiment
Deploy the Iter8 experiment for SLO validation of the app as follows.
```shell
helm upgrade my-exp $ITER8/samples/first-exp \
  --set URL='http://hello.default.svc.cluster.local:8080' \
  --set limitMeanLatency=50.0 \
  --set limitErrorRate=0.0 \
  --set limit95thPercentileLatency=100.0 \
  --install  
```

The above command creates [an Iter8 experiment](../concepts/whatisiter8.md#what-is-an-iter8-experiment) that generates requests, collects latency and error rate metrics for the app, and verifies that the app satisfies the mean latency (50 msec), error rate (0.0), 95th percentile tail latency SLO (100 msec) SLOs.

??? note "View Iter8 experiment deployed by Helm"
    Use the command below to view the Iter8 experiment deployed by the Helm command.
    ```shell
    helm get manifest my-exp
    ```

## 3. Observe experiment
Assert that the experiment completed and found a winning version. Wait 20 seconds before trying the following command. If the assertions are not satisfied, try again after a few seconds.

```shell
iter8ctl assert -c completed -c winnerFound
```

Describe the results of the Iter8 experiment. 
```shell
iter8ctl describe
```

??? info "Experiment results will look similar to this ... "
    ```shell
    ****** Overview ******
    Experiment name: my-experiment
    Experiment namespace: default
    Target: my-app
    Testing pattern: Conformance
    Deployment pattern: Progressive

    ****** Progress Summary ******
    Experiment stage: Completed
    Number of completed iterations: 1

    ****** Winner Assessment ******
    > If the version being validated; i.e., the baseline version, satisfies the experiment objectives, it is the winner.
    > Otherwise, there is no winner.
    Winning version: my-app

    ****** Objective Assessment ******
    > Identifies whether or not the experiment objectives are satisfied by the most recently observed metrics values for each version.
    +--------------------------------------+--------+
    |              OBJECTIVE               | MY-APP |
    +--------------------------------------+--------+
    | iter8-system/mean-latency <=         | true   |
    |                               50.000 |        |
    +--------------------------------------+--------+
    | iter8-system/error-rate <=           | true   |
    |                                0.000 |        |
    +--------------------------------------+--------+
    | iter8-system/latency-95th-percentile | true   |
    | <= 100.000                           |        |
    +--------------------------------------+--------+

    ****** Metrics Assessment ******
    > Most recently read values of experiment metrics for each version.
    +--------------------------------------+--------+
    |                METRIC                | MY-APP |
    +--------------------------------------+--------+
    | iter8-system/mean-latency            |  1.233 |
    +--------------------------------------+--------+
    | iter8-system/error-rate              |  0.000 |
    +--------------------------------------+--------+
    | iter8-system/latency-95th-percentile |  2.311 |
    +--------------------------------------+--------+
    | iter8-system/request-count           | 40.000 |
    +--------------------------------------+--------+
    | iter8-system/error-count             |  0.000 |
    +--------------------------------------+--------+
    ``` 

## 4. Cleanup
```shell
# remove experiment
helm uninstall my-exp
# remove application
kubectl delete -f $ITER8/samples/deployments/app/service.yaml
kubectl delete -f $ITER8/samples/deployments/app/deploy.yaml
```
***

**Next Steps**

!!! tip "Use with your application"
    1. Run the above experiment with your application by setting the `URL` value in the Helm command to the URL of your application. 
    
    2. You can also customize the mean latency, error rate, and tail latency limits.

    3. This experiment can be run in any K8s environment such as a dev, test, staging, or production cluster.