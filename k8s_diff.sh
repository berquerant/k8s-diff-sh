#!/bin/bash

# shellcheck disable=SC2155
readonly root="$(cd "$(dirname "$0")" || exit; pwd)"
readonly target="$1"
shift

script=""
case "$target" in
    "h" | "helm")
        script="${root}/helm.sh" ;;
    "hb" | "helm_branch")
        script="${root}/helm_branch.sh" ;;
    "k" | "kustomize")
        script="${root}/kustomize.sh" ;;
    "kb" | "kustomize_branch")
        script="${root}/kustomize_branch.sh" ;;
    "o" | "object")
        script="${root}/object.sh" ;;
    "d" | "diff")
        script="${root}/diff.sh" ;;
    "b" | "branch")
        script="${root}/branch.sh" ;;
    "i" | "id")
        script="${root}/id.sh" ;;
esac

if [ -z "$script" ] ; then
    readonly name="${0##*/}"
    cat - <<EOS > /dev/stderr
${name} TARGET [ARGS...]

Available TARGET:

h, helm             : helm.sh
hb, helm_branch     : helm_branch.sh
k, kustomize        : kustomize.sh
kb, kustomize_branch: kustomize_branch.sh
o, object           : object.sh
d, diff             : diff.sh
b, branch           : branch.sh
i, id               : id.sh
EOS
    exit 1
fi

"$script" "$@"
