# k8s-diff-sh

Diff tools for Kubernetes.

## helm.sh

```
❯ ./helm.sh
helm template and diff
helm.sh CHART LEFT_VALUES RIGHT_VALUES [QUERY_LEFT] [QUERY_RIGHT]

e.g.
helm.sh datadog/datadog left_values.yml right_values.yml
helm.sh datadog/datadog default right_values.yml
HELM_OPT='--version 3.54.2' helm.sh datadog/datadog left_values.yml right_values.yml
HELM_OPT='--version 3.54.2' HELM_OPT_RIGHT='--version 3.65.0' helm.sh datadog/datadog default default

Common environment variables:
  SED
    sed command.
    default: sed

  GIT
    git command.
    default: git

  DIFF
    diff command.
    default: diff -u

  YQ
    yq command.
    https://github.com/mikefarah/yq
    default: yq

  HELM
    helm command.
    default: helm

  KUBECTL
    kubectl command.
    default: kubectl

  KUSTOMIZE_OPT
    Options for kubectl kustomize.
    default:
```

## helm_branch.sh

```
❯ ./helm_branch.sh
helm build and diff between branches
helm_branch.sh DIR LEFT_BRANCH RIGHT_BRANCH [QUERY_LEFT] [QUERY_RIGHT]

e.g.
helm_branch.sh path/to/chart/dir master changed
HELM_OPT='--values path/to/values.yaml' helm_branch.sh path/to/chart/dir master changed
HELM_OPT_RIGHT='--values path/to/values.yaml' helm_branch.sh path/to/chart/dir master changed

Common environment variables:
  SED
    sed command.
    default: sed

  GIT
    git command.
    default: git

  DIFF
    diff command.
    default: diff -u

  YQ
    yq command.
    https://github.com/mikefarah/yq
    default: yq

  HELM
    helm command.
    default: helm

  KUBECTL
    kubectl command.
    default: kubectl

  KUSTOMIZE_OPT
    Options for kubectl kustomize.
    default:
```

## kustomize.sh

```
❯ ./kustomize.sh
kustomize build and diff
kustomize.sh LEFT_DIR RIGHT_DIR [QUERY_LEFT] [QUERY_RIGHT]

e.g.
kustomize.sh overlays/env1 overlays/env2 'select(.metadata.name==\"xxx\")'

Common environment variables:
  SED
    sed command.
    default: sed

  GIT
    git command.
    default: git

  DIFF
    diff command.
    default: diff -u

  YQ
    yq command.
    https://github.com/mikefarah/yq
    default: yq

  HELM
    helm command.
    default: helm

  KUBECTL
    kubectl command.
    default: kubectl

  KUSTOMIZE_OPT
    Options for kubectl kustomize.
    default:
```

## kustomize_branch.sh

```
❯ ./kustomize_branch.sh
kustomize build and diff between branches
kustomize_branch.sh DIR LEFT_BRANCH RIGHT_BRANCH [QUERY_LEFT] [QUERY_RIGHT]

e.g.
kustomize_branch.sh overlays/env master new 'select(.metadata.name==\"\xxx)'

Common environment variables:
  SED
    sed command.
    default: sed

  GIT
    git command.
    default: git

  DIFF
    diff command.
    default: diff -u

  YQ
    yq command.
    https://github.com/mikefarah/yq
    default: yq

  HELM
    helm command.
    default: helm

  KUBECTL
    kubectl command.
    default: kubectl

  KUSTOMIZE_OPT
    Options for kubectl kustomize.
    default:
```

## object.sh

```
❯ ./object.sh
diff by object
object.sh LEFT RIGHT

e.g.
object.sh left.yml right.yml
DIFF_ID=1 object.sh left.yml right.yml # object id diff only
DIFF_ID=1 object.sh default right.yml # dump object ids of right.yml
CONTEXT=5 object.sh left.yml right.yml # diff context lines

Requires:
- Python 3.12.2
- https://github.com/yaml/pyyaml 6.0.1
```
