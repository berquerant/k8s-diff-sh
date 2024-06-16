#!/bin/bash

thisd="$(cd $(dirname $0); pwd)"
. "${thisd}/common.sh"

if [ -z "$1" ] ; then
    name="$(short_selfname)"
    cat - <<EOS > /dev/stderr
kustomize build and diff between branches
${name} DIR LEFT_BRANCH RIGHT_BRANCH [QUERY_LEFT] [QUERY_RIGHT]

e.g.
${name} overlays/env master new 'select(.metadata.name=="xxx")'

EOS
    __usage
    exit 1
fi

target="$1"
left="$2"
right="$3"
query_left="${4}"
query_right="${5:-$4}"

original_branch="$(git_cmd branch --show-current)"

left_kustomized="$(get_tmpfile)"
right_kustomized="$(get_tmpfile)"

git_cmd switch "$left"
left_sha="$(git_cmd rev-parse --short HEAD)"
kustomize_sorted "$target" | yq_cmd "$query_left" > "$left_kustomized"

git_cmd switch "$right"
right_sha="$(git_cmd rev-parse --short HEAD)"
kustomize_sorted "$target" | yq_cmd "$query_right" > "$right_kustomized"

left_name="[${left}] ${left_sha} ${target} ${query_left}"
right_name="[${right}] ${right_sha} ${target} ${query_right}"

diff_sed "$left_kustomized" "$right_kustomized" \
         -e "s|${left_kustomized}|${left_name}|" \
         -e "s|${right_kustomized}|${right_name}|"
ret=$?

git_cmd switch "$original_branch"
exit $ret
