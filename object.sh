#!/bin/bash

thisd="$(cd $(dirname $0); pwd)"
. "${thisd}/common.sh"

manifest2id() {
    yq_cmd '(.apiVersion)+">"+(.kind)+">"+(.metadata.namespace // "")+">"+(.metadata.name)' -r | grep -v '^-'
}

# $1 : manifest
# $2 : rootd
divide_manifests() {
    mkdir -p "$2"
    index=0
    while true ; do
        file="$2/${index}"
        yq_cmd "select(documentIndex == ${index})" "$1" | sort_yaml > "$file"
        if [ -z "$(cat $file)" ] ; then
            break
        fi
        id="$(cat $file | manifest2id)"
        echo "${id} ${file}"
        index=$((index + 1))
    done
}

# $1 : rootd
index_file() {
    mkdir -p "$1"
    echo "$1/index"
}

# $1 : rootd
id_file() {
    mkdir -p "$1"
    echo "$1/id"
}

# $1 : left
# $2 : right
# $3 : rootd
prepare_manifests() {
    lindex="$(index_file $3/left)"
    rindex="$(index_file $3/right)"
    lid="$(id_file $3/left)"
    rid="$(id_file $3/right)"
    divide_manifests "$1" "$3/left" > "$lindex"
    divide_manifests "$2" "$3/right" > "$rindex"
    cat "$lindex" | cut -d " " -f 1 | sort | grep -v '^$' > "$lid"
    cat "$rindex" | cut -d " " -f 1 | sort | grep -v '^$' > "$rid"
}

# $1 : rootd
uniq_id() {
    t="$(get_tmpfile)"
    cat "$(id_file $1/left)" >> "$t"
    cat "$(id_file $1/right)" >> "$t"
    cat "$t" | sort -u | grep -v '^$'
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
# $3 : rootd
# $4 : id
diff_object() {
    lfile="$(find_manifest $4 $(index_file $3/left))"
    rfile="$(find_manifest $4 $(index_file $3/right))"

    left_name="$1 $4"
    right_name="$2 $4"
    set +e
    __diff "$lfile" "$rfile" |\
        sed_cmd -e "s|${lfile}|${left_name}|" \
                -e "s|${rfile}|${right_name}|"
    set -e
}

# $1 : left
# $2 : right
# $3 : rootd
diff_object_by_id() {
    uniq_id "$3" | while read id ; do
        diff_object "$1" "$2" "$3" "$id"
    done
}

# $1 : left
# $2 : right
# $3 : rootd
diff_id() {
    lfile="$(id_file $3/left)"
    rfile="$(id_file $3/right)"
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

rootd="$(get_tmpd)/object.sh"
mkdir -p "$rootd"
prepare_manifests "$left" "$right" "$rootd"

if [ -n "$objid_only" ] ; then
    diff_id "$left" "$right" "$rootd"
else
    diff_object_by_id "$left" "$right" "$rootd"
fi
