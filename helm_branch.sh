#!/bin/bash

thisd="$(cd "$(dirname "$0")" || exit 1; pwd)"
. "${thisd}/common.sh"

if [ -z "$1" ] ; then
    name="$(short_selfname)"
    cat - <<EOS > /dev/stderr
helm build and diff between branches
${name} DIR LEFT_BRANCH RIGHT_BRANCH [QUERY_LEFT] [QUERY_RIGHT]

e.g.
${name} path/to/chart/dir master changed
HELM_OPT='--values path/to/values.yaml' ${name} path/to/chart/dir master changed
HELM_OPT_RIGHT='--values path/to/values.yaml' ${name} path/to/chart/dir master changed

NOTE:
This script removes untracked git files and directories to ensure helm dependency build.
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

left_result="$(get_tmpfile)"
right_result="$(get_tmpfile)"
left_opt="$HELM_OPT"
right_opt="${HELM_OPT_RIGHT:-$left_opt}"

git_remove_untracked
git_cmd switch "$left"
left_sha="$(git_cmd rev-parse --short HEAD)"
# shellcheck disable=SC2086
helm_build "$target" --generate-name $left_opt | yq_cmd "$query_left" > "$left_result"

git_remove_untracked
git_cmd switch "$right"
right_sha="$(git_cmd rev-parse --short HEAD)"
# shellcheck disable=SC2086
helm_build "$target" --generate-name $right_opt | yq_cmd "$query_right" > "$right_result"

left_name="[${left}] ${left_sha} ${target} ${query_left}"
right_name="[${right}] ${right_sha} ${target} ${query_right}"

diff_sed "$left_result" "$right_result" \
         -e "s|${left_result}|${left_name}|" \
         -e "s|${right_result}|${right_name}|"
ret=$?

git_remove_untracked
git_cmd switch "$original_branch"
exit $ret
