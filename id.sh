#!/bin/bash

thisd="$(cd $(dirname $0); pwd)"
. "${thisd}/common.sh"

if [ $# -lt 1 ] ; then
    name="$(short_selfname)"
    cat - <<EOS > /dev/stderr
extract object id
${name} some.yml

extract object id from stdin
${name} -

diff object ids
${name} left.yml right.yml

CONTEXT=5 ${name} left.yml right.yml

Exit status is 0 if inputs are the same.
EOS
    exit 1
fi

left="$1"
right="$2"

stdin_filename="-"
stdin_name="stdin"

sorted_id() {
    manifest2id | sort
}

if [ -z "$right" ] ; then
    set -e
    if [ "$left" = "$stdin_filename" ] ; then
        sorted_id
    else
        sorted_id < "$left"
    fi
    exit
fi

if [ "$left" = "$stdin_filename" ] ; then
    left="$(get_tmpfile)"
    cat - > "$left"
    left_stdin=1
fi
if [ "$right" = "$stdin_filename" ] ; then
    right="$(get_tmpfile)"
    cat - > "$right"
    right_stdin=1
fi

lfile="$(get_tmpfile)"
rfile="$(get_tmpfile)"
sorted_id < "$left" > "$lfile"
sorted_id < "$right" > "$rfile"
left_name="$left"
right_name="$right"
if [ -n "$left_stdin" ] ; then
    left_name="$stdin_name"
fi
if [ -n "$right_stdin" ] ; then
    right_name="$stdin_name"
fi

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

diff_sed "$lfile" "$rfile" \
         -e "s|${lfile}|${left_name}|" \
         -e "s|${rfile}|${right_name}|"
