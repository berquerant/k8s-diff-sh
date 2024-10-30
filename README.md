# k8s-diff-sh

Diff tools for Kubernetes.

## helm.sh

``` shell
❯ ./helm.sh
helm template and diff
helm.sh CHART LEFT_VALUES RIGHT_VALUES [QUERY_LEFT] [QUERY_RIGHT]

e.g.
helm.sh datadog/datadog left_values.yml right_values.yml
helm.sh datadog/datadog default right_values.yml
HELM_OPT='--version 3.54.2' helm.sh datadog/datadog left_values.yml right_values.yml
HELM_OPT='--version 3.54.2' HELM_OPT_RIGHT='--version 3.65.0' helm.sh datadog/datadog default default
helm.sh datadog/datadog default right_values1.yml,right_values2.yml
```

## helm_branch.sh

``` shell
❯ ./helm_branch.sh
helm build and diff between branches
helm_branch.sh DIR LEFT_BRANCH RIGHT_BRANCH [QUERY_LEFT] [QUERY_RIGHT]

e.g.
helm_branch.sh path/to/chart/dir master changed
HELM_OPT='--values path/to/values.yaml' helm_branch.sh path/to/chart/dir master changed
HELM_OPT_RIGHT='--values path/to/values.yaml' helm_branch.sh path/to/chart/dir master changed
```

## kustomize.sh

``` shell
❯ ./kustomize.sh
kustomize build and diff
kustomize.sh LEFT_DIR RIGHT_DIR [QUERY_LEFT] [QUERY_RIGHT]

e.g.
kustomize.sh overlays/env1 overlays/env2 'select(.metadata.name=="xxx")'
```

## kustomize_branch.sh

``` shell
❯ ./kustomize_branch.sh
kustomize build and diff between branches
kustomize_branch.sh DIR LEFT_BRANCH RIGHT_BRANCH [QUERY_LEFT] [QUERY_RIGHT]

e.g.
kustomize_branch.sh overlays/env master new 'select(.metadata.name=="xxx")'
```

## object.sh

``` shell
❯ ./object.sh
diff by object
object.sh LEFT RIGHT

e.g.
object.sh left.yml right.yml
CONTEXT=5 object.sh left.yml right.yml # diff context lines

Exit status is 0 if inputs are the same.
```

## diff.sh

``` shell
❯ ./diff.sh
build and diff
diff.sh COMMON_COMMAND LEFT_ARGS RIGHT_ARGS

e.g.
diff.sh 'kubectl kustomize' 'overlays/left' 'overlays/right'
diff.sh 'helm template datadog/datadog --version 3.68.0' '' '--version 3.69.3 --set datadog.logLevel=debug'
```

## branch.sh

``` shell
❯ ./branch.sh
build and diff between branches
branch.sh LEFT_BRANCH RIGHT_BRANCH COMMON_COMMAND LEFT_ARGS RIGHT_ARGS

e.g.
branch.sh master new 'kubectl kustomize' 'overlays/env' 'overlays/env'
```

## id.sh

``` shell
❯ ./id.sh
extract object id
id.sh some.yml

extract object id from stdin
id.sh -

diff object ids
id.sh left.yml right.yml

CONTEXT=5 id.sh left.yml right.yml

Exit status is 0 if inputs are the same.
```
