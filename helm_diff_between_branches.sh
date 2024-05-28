#!/bin/bash

set -e
thisd="$(cd $(dirname $0); pwd)"
. "${thisd}/common.sh"

if [ -z "$1" ] ; then
    name="$(short_selfname)"
    cat - <<EOS > /dev/stderr
helm build and diff between branches
${name} DIR LEFT_BRANCH RIGHT_BRANCH [QUERY_LEFT] [QUERY_RIGHT]

e.g.
${name} path/to/chart/dir master changed
HELM_BUILD_OPT='--values path/to/values.yaml' ${name} path/to/chart/dir master changed
HELM_BUILD_OPT_RIGHT='--values path/to/values.yaml' ${name} path/to/chart/dir master changed

EOS
    __usage
    exit 1
fi

target="$1"
left="$2"
right="$3"
query_left="${4}"
query_right="${5:-$4}"

original_branch="$($(git_cmd) branch --show-current)"

left_result="$(mktemp)"
right_result="$(mktemp)"
left_opt="$HELM_BUILD_OPT"
right_opt="${HELM_BULD_OPT_RIGHT:-$left_opt}"

git_cmd switch "$left"
left_sha="$($(git_cmd) rev-parse --short HEAD)"
helm_build "$target" $left_opt | yq_cmd "$query_left" > "$left_result"

git_cmd switch "$right"
right_sha="$($(git_cmd) rev-parse --short HEAD)"
helm_build "$target" $right_opt | yq_cmd "$query_right" > "$right_result"

left_name="[${left}] ${left_sha} ${target} ${query_left}"
right_name="[${right}] ${right_sha} ${target} ${query_right}"
diff_cmd "$left_result" "$right_result" |\
    sed_cmd -e "s|${left_result}|${left_name}|" \
            -e "s|${right_result}|${right_name}|"

git_cmd switch "$original_branch"
