#!/bin/bash

thisd="$(cd "$(dirname "$0")" || exit; pwd)"
. "${thisd}/common.sh"

if [ -z "$1" ] ; then
    name="$(short_selfname)"
    cat - <<EOS > /dev/stderr
build and diff between branches
${name} LEFT_BRANCH RIGHT_BRANCH COMMON_COMMAND LEFT_ARGS RIGHT_ARGS

e.g.
${name} master new 'kubectl kustomize' 'overlays/env' 'overlays/env'

EOS
    __usage
    exit 1
fi

left_branch="$1"
right_branch="$2"
command="$3"
left_args="$4"
right_args="$5"

original_branch="$(git_cmd branch --show-current)"

left_result="$(get_tmpfile)"
right_result="$(get_tmpfile)"

git_cmd switch "$left_branch"
left_sha="$(git_cmd rev-parse --short HEAD)"
# shellcheck disable=SC2086
$command $left_args | sort_yaml > "$left_result"

git_cmd switch "$right_branch"
right_sha="$(git_cmd rev-parse --short HEAD)"
# shellcheck disable=SC2086
$command $right_args | sort_yaml > "$right_result"

left_name="[${left_branch}] ${left_sha} ${command} ${left_args}"
right_name="[${right_branch}] ${right_sha} ${command} ${right_args}"

diff_sed "$left_result" "$right_result" \
         -e "s|${left_result}|${left_name}|" \
         -e "s|${right_result}|${right_name}|"
ret=$?

git_cmd switch "$original_branch"
exit $ret
