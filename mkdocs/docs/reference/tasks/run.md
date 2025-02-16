---
template: main.html
---

# `run`
The `run` task executes a bash script.

## Basic Example

The following (partially-specified) experiment executes the one line script `kubectl apply` using a YAML manifest at the end of the experiment.

```yaml
kind: Experiment
...
spec:
  ...
  strategy:
    ...
    actions:
      finish:
      - run: kubectl apply -f https://raw.githubusercontent.com/iter8-tools/iter8/master/samples/mysample/manifest.yaml
```

## Conditional Execution

The `run` task can be [executed conditionally](../experiment.md#taskspec), where the condition is specified using the `if` clause. Supported conditions include `WinnerFound()`, `CandidateWon()` and their negations using the `not` keyword.

```yaml
kind: Experiment
...
spec:
  ...
  strategy:
    ...
    actions:
      finish: # run the following sequence of tasks at the end of the experiment
      - if: CandidateWon()
        run: "kubectl apply -f https://raw.githubusercontent.com/iter8-tools/iter8/master/samples/knative/quickstart/candidate.yaml"
      - if: not CandidateWon()
        run: "kubectl apply -f https://raw.githubusercontent.com/iter8-tools/iter8/master/samples/knative/quickstart/baseline.yaml"
```

## Secret

The `run` task can be used with a Kubernetes secret provided to it as an input.

```yaml
kind: Experiment
...
spec:
  ...
  strategy:
    ...
    actions:
      finish: # run the following sequence of tasks at the end of the experiment
      - run: "git clone https://username:{{ .Secret 'token' }}@github.com/username/repo.git"
        with:
          # reference to a K8s secret resource in the namespace/name format. If no namespace is specified, the namespace of the secret is assumed to be that of the experiment.
          secret: myns/mysecret
```

In the above example, a `token` value is extracted from the given Kubernetes secret, and inserted into the (templated) `git clone` script. This task requires the secret resource `mysecret` to be available in the `myns` namespace, and requires the secret to contain `token` as a key in its `data` section.

## Inputs

| Field name | Field type | Description | Required |
| ----- | ---- | ----------- | -------- |
| secret | string | Reference to a K8s secret in the `namespace/name` format. If no namespace is specified, then the namespace is assumed to be that of the experiment.  | No |

## Result

The script will be executed. If this script exits with a non-zero error code, the `run` task and therefore the experiment to which it belongs will fail.
