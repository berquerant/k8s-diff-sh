#!/bin/bash

thisd="$(cd "$(dirname "$0")" || exit; pwd)"
. "${thisd}/common.sh"

if [ -z "$1" ] ; then
    name="$(short_selfname)"
    cat - <<EOS > /dev/stderr
kustomize build and diff
${name} LEFT_DIR RIGHT_DIR [QUERY_LEFT] [QUERY_RIGHT]

e.g.
${name} overlays/env1 overlays/env2 'select(.metadata.name=="xxx")'

EOS
    __usage
    exit 1
fi

left="$1"
right="$2"
query_left="${3}"
query_right="${4:-$3}"

left_kustomized="$(get_tmpfile)"
right_kustomized="$(get_tmpfile)"
kustomize_sorted "$left" | yq_cmd "$query_left" > "$left_kustomized"
kustomize_sorted "$right" | yq_cmd "$query_right" > "$right_kustomized"
left_name="${left} ${query_left}"
right_name="${right} ${query_right}"
diff_sed "$left_kustomized" "$right_kustomized" \
         -e "s|${left_kustomized}|${left_name}|" \
         -e "s|${right_kustomized}|${right_name}|"
