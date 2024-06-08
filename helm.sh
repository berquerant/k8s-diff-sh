#!/bin/bash

thisd="$(cd $(dirname $0); pwd)"
. "${thisd}/common.sh"

if [ -z "$1" ] ; then
    name="$(short_selfname)"
    cat - <<EOS > /dev/stderr
helm template and diff
${name} CHART LEFT_VALUES RIGHT_VALUES [QUERY_LEFT] [QUERY_RIGHT]

e.g.
${name} datadog/datadog left_values.yml right_values.yml
${name} datadog/datadog default right_values.yml
HELM_OPT='--version 3.54.2' ${name} datadog/datadog left_values.yml right_values.yml
HELM_OPT='--version 3.54.2' HELM_OPT_RIGHT='--version 3.65.0' ${name} datadog/datadog default default

EOS
    __usage
    exit 1
fi

target="$1"
left="$2"
right="$3"
query_left="${4}"
query_right="${5:-$4}"

if [ "$left" = "default" ] ; then
    left_default=1
    left="$(get_tmpfile)"
fi
if [ "$right" = "default" ] ; then
    right_default=1
    right="$(get_tmpfile)"
fi

left_result="$(get_tmpfile)"
right_result="$(get_tmpfile)"
left_opt="$HELM_OPT"
right_opt="${HELM_OPT_RIGHT:-$left_opt}"

helm_sorted "$target" --values "$left" --generate-name $left_opt | yq_cmd "$query_left" > "$left_result"
helm_sorted "$target" --values "$right" --generate-name $right_opt | yq_cmd "$query_right" > "$right_result"

if [ -n "$left_default" ] ; then
    left="default"
fi
if [ -n "$right_default" ] ; then
    right="default"
fi

left_name="${left} ${query_left}"
right_name="${right} ${query_right}"
diff_cmd "$left_result" "$right_result" |\
    sed_cmd -e "s|${left_result}|${left_name}|" \
            -e "s|${right_result}|${right_name}|"
