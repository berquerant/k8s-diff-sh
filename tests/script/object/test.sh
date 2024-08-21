#!/bin/bash

thisd="$(cd $(dirname $0); pwd)"
. "${thisd}/../common.sh"
cd "$(test_projectd)"

left="tests/data/object/left.yaml"
right="tests/data/object/right.yaml"
gotd="$(mktemp -d)"
mkdir -p "$gotd"

test_object_sh_diff() {
    ./object.sh "$left" "$right" > "${gotd}/got"
    r=$?
    [ $r -eq 0 ] && return 1
    diff -u "${thisd}/golden.diff" "${gotd}/got"
}

test_object_sh_no_diff() {
    ./object.sh "$left" "$left"
}

test_run_multi "test_object_sh_diff" \
               "test_object_sh_no_diff"
