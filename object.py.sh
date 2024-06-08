#!/bin/bash

thisd="$(cd $(dirname $0); pwd)"
. "${thisd}/common.sh"

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

Requires:
- Python 3.12.2
- https://github.com/yaml/pyyaml 6.0.1
EOS
    exit 1
fi

left="$1"
right="$2"
objid_only="$DIFF_ID"
context="${CONTEXT:-3}"

if [ "$left" = "default" ] ; then
    left="$(get_tmpfile)"
fi
if [ "$right" = "default" ] ; then
    right="$(get_tmpfile)"
fi

cmd="python ${thisd}/object.py"
if [ -n "$objid_only" ] ; then
    cmd="${cmd} -I"
fi
cmd="${cmd} -C ${context} ${left} ${right}"
$cmd