#!/bin/bash

set -e
thisd="$(cd $(dirname $0); pwd)"
. "${thisd}/common.sh"

if [ $# -lt 2 ] ; then
    name="$(short_selfname)"
    cat - <<EOS > /dev/stderr
diff by object
${name} LEFT RIGHT [ID_ONLY]

e.g.
${name} left.yml right.yml
${name} left.yml right.yml 1 # object id diff only
${name} default right.yml 1 # dump object ids of right.yml
OBJDIFF='diff' ${name} left.yml right.yml # OBJDIFF overrides DIFF

EOS
    __usage
    exit 1
fi

left="$1"
right="$2"
objid_only="$3"

object2id() {
    yq_cmd '(.apiVersion) + "^" + (.kind) + "^" + (.metadata.namespace) + "^" + (.metadata.name)' -r | grep -v '^-'
}

objdiff_cmd() {
    if [ -n "$OBJDIFF" ] ; then
        $OBJDIFF "$@"
    else
        diff_cmd "$@"
    fi
}

if [ "$left" = "default" ] ; then
    left_default=1
    left="$(mktemp)"
fi
if [ "$right" = "default" ] ; then
    right_default=1
    right="$(mktemp)"
fi

if [ -n "$objid_only" ] ; then
    ltmp="$(mktemp)"
    rtmp="$(mktemp)"
    cat "$left" | object2id | sort > "$ltmp"
    cat "$right" | object2id | sort > "$rtmp"
    if [ -n "$left_default" ] ; then
        left="default"
    fi
    if [ -n "$right_default" ] ; then
        right="default"
    fi
    lname="${left}"
    rname="${right}"
    objdiff_cmd "$ltmp" "$rtmp" |\
        sed_cmd -e "s|${ltmp}|${lname}|" \
                -e "s|${rtmp}|${rname}|"
    exit
fi

query_object_by_id() {
    obj_id="$1"

    api="$(echo $obj_id | cut -d '^' -f 1)"
    kind="$(echo $obj_id | cut -d '^' -f 2)"
    ns="$(echo $obj_id | cut -d '^' -f 3)"
    name="$(echo $obj_id | cut -d '^' -f 4)"

    query="select(.apiVersion == \"${api}\" and .kind == \"${kind}\" and .metadata.namespace == \"${ns}\" and .metadata.name == \"${name}\")"
    yq_cmd "$query" | sort_yaml
}

id_list="$(mktemp)"
cat "$left" | object2id >> "${id_list}"
cat "$right" | object2id >> "${id_list}"

ltmp="$(mktemp)"
rtmp="$(mktemp)"
cat "$id_list" | sort -u | while read obj_id ; do
    echo "----------"
    echo "CHECK ${obj_id}"
    cat "$left" | query_object_by_id "$obj_id" > "$ltmp"
    cat "$right" | query_object_by_id "$obj_id" > "$rtmp"
    if [ -n "$left_default" ] ; then
        lname="default"
    else
        lname="${left}"
    fi
    if [ -n "$right_default" ] ; then
        rname="default"
    else
        rname="${right}"
    fi
    objdiff_cmd "$ltmp" "$rtmp" |\
        sed_cmd -e "s|${ltmp}|${lname}|" \
                -e "s|${rtmp}|${rname}|"
done
