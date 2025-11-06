#!/bin/bash

thisd="$(cd "$(dirname "$0")" || exit 1; pwd)"
. "${thisd}/common.sh"

sync_rootd() {
    getd "$(get_cached)/sync"
}

kget() {
    kubectl get -o yaml "$@" | yq '.items[] | split_doc'
}

dest() {
    echo "$(sync_rootd)/${1}-${2}.yml"
}

__save() {
    local -r __prefix="$1"
    local -r __target="$2"
    shift 2
    local __dest
    __dest="$(dest "$__prefix" "$__target")"
    kget "$__target" "$@" > "$__dest"
    echo >&2 "Saved to "${__dest}
}

save() {
    __save "before" "$@"
}

diff_sync() {
    local -r __target="$1"
    shift
    local __src
    __src="$(dest "before" "$__target")"
    if [[ ! -s "$__src" ]] ; then
        save "$__target" "$@"
    else
        __save "after" "$__target" "$@"
        local __dest
        __dest="$(dest "after" "$__target")"
        echo >&2 "Diff between ${__src} and ${__dest}"
        diff_cmd "$__src" "$__dest"
    fi
}

usage() {
    local -r name="${0##*/}"
    cat >&2 <<EOS
${name} OPERATION TARGET [KUBECTL_GET_OPTION...]

${name} (save|s) TARGET [KUBECTL_GET_OPTION...]
  Save the TARGET as 'before' file.

${name} (diff|d) TARGET [KUBECTL_GET_OPTION...]
  Save the TARGET as 'after' file and compare 'before' and 'after'.
  Fallback to 'save' if 'before' file not exists.

EOS
    __usage
}

readonly op="$1"
readonly target="$2"
shift
if [[ -z "$op" || -z "$target" ]] ; then
    usage
    exit 1
fi

set -e
case "$op" in
    "-h" | "--help")
        usage
        exit
        ;;
    "save" | "s") save "$@" ;;
    "diff" | "d") diff_sync "$@" ;;
    *)
        usage
        exit 1
        ;;
esac
