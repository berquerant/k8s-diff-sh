#!/bin/bash

thisd="$(cd "$(dirname "$0")" || exit 1; pwd)"
. "${thisd}/common.sh"

if [ -z "$1" ] ; then
    name="$(short_selfname)"
    cat - <<EOS > /dev/stderr
build and diff
${name} COMMON_COMMAND LEFT_ARGS RIGHT_ARGS

e.g.
${name} 'kubectl kustomize' 'overlays/left' 'overlays/right'
${name} 'helm template datadog/datadog' '--version 3.68.0' '--version 3.69.3 --set datadog.logLevel=debug'

EOS
    __usage
    exit 1
fi

command="$1"
left_args="$2"
right_args="$3"

left_result="$(get_tmpfile)"
right_result="$(get_tmpfile)"

# shellcheck disable=SC2086
$command $left_args | sort_yaml > "$left_result"
# shellcheck disable=SC2086
$command $right_args | sort_yaml > "$right_result"

left_name="${command} ${left_args}"
right_name="${command} ${right_args}"
diff_sed "$left_result" "$right_result" \
         -e "s|${left_result}|${left_name}|" \
         -e "s|${right_result}|${right_name}|"
