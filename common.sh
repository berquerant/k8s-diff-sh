#!/bin/bash

thisd="$(cd $(dirname $0); pwd)"
default_tmpd="$(mktemp -d)"

__default() {
    case "$1" in
        SED) echo "sed" ;;
        GIT) echo "git" ;;
        DIFF) echo "${thisd}/object.sh" ;;
        YQ) echo "yq" ;;
        HELM) echo "helm" ;;
        KUBECTL) echo "kubectl" ;;
        KUSTOMIZE_OPT) echo "" ;;
        WORKD) echo "$default_tmpd" ;;
        *) echo "UNKNWON__DEFAULT" ;;
    esac
}

__usage() {
    cat - <<EOS > /dev/stderr
Common environment variables:
  SED
    sed command.
    default: $(__default SED)

  GIT
    git command.
    default: $(__default GIT)

  DIFF
    diff command.
    default: $(__default DIFF)

  YQ
    yq command.
    https://github.com/mikefarah/yq
    default: $(__default YQ)

  HELM
    helm command.
    default: $(__default HELM)

  KUBECTL
    kubectl command.
    default: $(__default KUBECTL)

  KUSTOMIZE_OPT
    Options for kubectl kustomize.
    default: $(__default KUSTOMIZE_OPT)

  WORKD
    Temporary directory for temporary files.
    default: $(__default WORKD)
EOS
}

short_selfname() {
    echo "${0##*/}"
}

sed_cmd() {
    ${SED:-$(__default SED)} "$@"
}

git_cmd() {
    ${GIT:-$(__default GIT)} "$@"
}

diff_cmd() {
    ${DIFF:-$(__default DIFF)} "$@"
}

yq_cmd() {
    ${YQ:-$(__default YQ)} "$@"
}

helm_path() {
    echo "${HELM:-$(__default HELM)}"
}

helm_cmd() {
    $(helm_path) "$@"
}

kubectl_cmd() {
    ${KUBECTL:-$(__default KUBECTL)} "$@"
}

sort_yaml() {
    yq_cmd --prettyPrint 'sort_keys(..)'
}

helm_sorted() {
    helm_cmd template "$@" | sort_yaml
}

kustomize_opt() {
    echo "${KUSTOMIZE_OPT:-$(__default KUSTOMIZE_OPT)}"
}

kustomize_sorted() {
    kubectl_cmd kustomize $(kustomize_opt) "$@" | sort_yaml
}

helm_build_prepare() {
    target="$1"
    helm_cmd dependency list --max-col-width 200 "$target" |\
        grep -v '^$' |\
        awk 'NR > 1 {print $1,$3}' |\
        while read line ; do
            name="$(echo $line | cut -d ' ' -f 1)"
            repo="$(echo $line | cut -d ' ' -f 2)"
            helm_cmd repo add "$name" "$repo"
        done
    helm_cmd dependency build "$target"
}

helm_build() {
    target="$1"
    helm_build_prepare "$target" > /dev/stderr
    helm_sorted "$@"
}

git_remove_untracked() {
    git_cmd clean -d -f
}

getd() {
    mkdir -p "$1"
    echo "$1"
}

get_tmpd() {
    d="${WORKD:-$(__default WORKD)}"
    getd "$d"
}

get_tmpfile() {
    mktemp -p "$(get_tmpd)"
}

# sed result of diff, keeping diff exit code
#
# $1: left
# $2: right
# $@: sed args
diff_sed() {
    __diff_sed_result="$(get_tmpfile)"
    diff_cmd "$1" "$2" > "$__diff_sed_result"
    __diff_sed_ret=$?
    shift 2
    sed "$@" < "$__diff_sed_result"
    return $__diff_sed_ret
}

manifest2id() {
    yq_cmd '(.apiVersion)+">"+(.kind)+">"+(.metadata.namespace // "")+">"+(.metadata.name)' -r | grep -v '^-'
}
