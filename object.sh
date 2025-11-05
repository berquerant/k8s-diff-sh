#!/bin/bash

thisd="$(cd "$(dirname "$0")" || exit 1; pwd)"
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

# $1 : manifest
# $2 : rootd
divide_manifests() {
    manifest="$1"
    rootd="$2"
    index=0
    touch "$(index_file "$rootd")"
    while true ; do
        file="$(documentd "$rootd")/${index}"
        yq_cmd "select(documentIndex == ${index})" "$manifest" | sort_yaml > "$file"
        if [ -z "$(cat "$file")" ] ; then
            break
        fi
        set +e
        id="$(manifest2id < "$file")"
        set -e
        if [ -n "$id" ] ; then
            echo "${id} ${file}" >> "$(index_file "$rootd")"
        fi
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
    awk '{print $1}' "$(index_file "$1")" | sort
}

uniq_id_all() {
    (uniq_id "$(leftd)" ; uniq_id "$(rightd)") | sort -u
}

# $1 : id
# $2 : index file
find_manifest() {
    found="$(awk -v x="$1" '$1==x{print $2}' "$2")"
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

    lfile="$(find_manifest "$id" "$(index_file "$(leftd)")")"
    rfile="$(find_manifest "$id" "$(index_file "$(rightd)")")"

    left_name="${left} ${id}"
    right_name="${right} ${id}"

    ret=0
    diff_sed "$lfile" "$rfile" \
             -e "s|${lfile}|${left_name}|" \
             -e "s|${rfile}|${right_name}|"
    ret=$?
    return $ret
}

# $1 : left
# $2 : right
diff_object() {
    diff_object_res="$(get_tmpfile)"
    echo 0 > "$diff_object_res"
    set +e
    uniq_id_all | while read -r id ; do
        diff_object_by_id "$1" "$2" "$id"
        r=$?
        if [ $r -ne 0 ] ; then
            echo "$r" > "$diff_object_res"
        fi
    done
    return "$(cat "$diff_object_res")"
}

# override diff_cmd in common.sh
diff_cmd() {
    __diff "$@"
}

__diff() {
    __diff_res="$(get_tmpfile)"
    diff -U "${CONTEXT:-3}" "$1" "$2" > "$__diff_res"
    __diff_ret="$?"

    awk -v left="$1" -v right="$2" '{
  if (($1 == "---" || $1 == "+++") && ($2 == left || $2 == right)) {
    print $1, $2
  } else {
    print
  }
}' "$__diff_res"
    return $__diff_ret
}


if [ $# -lt 2 ] ; then
    name="$(short_selfname)"
    cat - <<EOS > /dev/stderr
diff by object
${name} LEFT RIGHT

e.g.
${name} left.yml right.yml
CONTEXT=5 ${name} left.yml right.yml # diff context lines

Exit status is 0 if inputs are the same.
EOS
    exit 1
fi

left="$1"
right="$2"

prepare_manifests "$left" "$right"
diff_object "$left" "$right"
