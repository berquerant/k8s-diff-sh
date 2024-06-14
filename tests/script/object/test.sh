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
    diff -u "${thisd}/golden.diff" "${gotd}/got"
}

test_object_sh_diff_id() {
    DIFF_ID=1 ./object.sh "$left" "$right" > "${gotd}/got"
    diff -u "${thisd}/golden.id.diff" "${gotd}/got"
}


test_run_multi "test_object_sh_diff" \
               "test_object_sh_diff_id"
