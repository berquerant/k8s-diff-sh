#!/bin/bash

thisd="$(cd $(dirname $0); pwd)"
. "${thisd}/common.sh"

__object_rootd="$(get_tmpd)"
leftd() {
    getd "${__object_rootd}/left"
}
rightd() {
    getd "${__object_rootd}/right"
}
documentd() {
    getd "$1/documents"
}
index_file() {
    mkdir -p "$1"
    echo "$1/index"
}

manifest2id() {
    yq_cmd '(.apiVersion)+">"+(.kind)+">"+(.metadata.namespace // "")+">"+(.metadata.name)' -r | grep -v '^-'
}

# $1 : manifest
# $2 : rootd
divide_manifests() {
    manifest="$1"
    rootd="$2"
    index=0
    while true ; do
        file="$(documentd $rootd)/${index}"
        yq_cmd "select(documentIndex == ${index})" "$manifest" | sort_yaml > "$file"
        if [ -z "$(cat $file)" ] ; then
            break
        fi
        id="$(cat $file | manifest2id)"
        echo "${id} ${file}" >> "$(index_file $rootd)"
        index=$((index + 1))
    done
}

# $1 : left
# $2 : right
prepare_manifests() {
    divide_manifests "$1" "$(leftd)"
    divide_manifests "$2" "$(rightd)"
}

# $1 rootd
uniq_id() {
    awk '{print $1}' "$(index_file $1)" | sort
}

uniq_id_all() {
    (uniq_id "$(leftd)" ; uniq_id "$(rightd)") | sort -u
}

# $1 : id
# $2 : index file
find_manifest() {
    found="$(awk -v x=$1 '$1==x{print $2}' $2)"
    if [ -n "$found" ] ; then
        echo "$found"
    else
        get_tmpfile
    fi
}

# $1 : left
# $2 : right
# $3 : id
diff_object_by_id() {
    left="$1"
    right="$2"
    id="$3"

    lfile="$(find_manifest $id $(index_file $(leftd)))"
    rfile="$(find_manifest $id $(index_file $(rightd)))"

    left_name="${left} ${id}"
    right_name="${right} ${id}"
    set +e
    ret=0
    __diff "$lfile" "$rfile" |\
        sed_cmd -e "s|${lfile}|${left_name}|" \
                -e "s|${rfile}|${right_name}|"
    ret=$?
    set -e
    return $ret
}

# $1 : left
# $2 : right
diff_object() {
    id_list="$(get_tmpfile)"
    uniq_id_all > "$id_list"
    ret=0
    while read id ; do
        diff_object_by_id "$1" "$2" "$id"
        r=$?
        if [ $r -gt 0 ] ; then
            ret=$r
        fi
    done < "$id_list"
    return $ret
}

# $1 : left
# $2 : right
diff_id() {
    lfile="$(get_tmpfile)"
    rfile="$(get_tmpfile)"
    uniq_id "$(leftd)" > "$lfile"
    uniq_id "$(rightd)" > "$rfile"
    left_name="$1"
    right_name="$2"
    __diff "$lfile" "$rfile" |\
        sed_cmd -e "s|${lfile}|${left_name}|" \
                -e "s|${rfile}|${right_name}|"
}

__diff() {
    diff -U "${CONTEXT:-3}" "$@" | awk -v left=$1 -v right=$2 '{
  if (($1 == "---" || $1 == "+++") && ($2 == left || $2 == right)) {
    print $1, $2
  } else {
    print
  }
}'
}


if [ $# -lt 2 ] ; then
    name="$(short_selfname)"
    cat - <<EOS > /dev/stderr
diff by object
${name} LEFT RIGHT

e.g.
${name} left.yml right.yml
DIFF_ID=1 ${name} left.yml right.yml # object id diff only
DIFF_ID=1 ${name} default right.yml # dump object ids of right.yml
CONTEXT=5 ${name} left.yml right.yml # diff context lines
EOS
    exit 1
fi

left="$1"
right="$2"
objid_only="$DIFF_ID"

prepare_manifests "$left" "$right"

if [ -n "$objid_only" ] ; then
    diff_id "$left" "$right"
else
    diff_object "$left" "$right"
fi
