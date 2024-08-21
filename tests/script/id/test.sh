#!/bin/bash

thisd="$(cd $(dirname $0); pwd)"
. "${thisd}/../common.sh"
cd "$(test_projectd)"

left="tests/data/object/left.yaml"
right="tests/data/object/right.yaml"
gotd="$(mktemp -d)"
mkdir -p "$gotd"

test_id_sh_diff() {
    ./id.sh "$left" "$right" > "${gotd}/got"
    r=$?
    [ $r -eq 0 ] && return 1
    diff -u "${thisd}/golden.diff" "${gotd}/got"
}

test_id_sh_stdin_diff() {
    ./id.sh - "$right" < "$left" > "${gotd}/got"
    r=$?
    [ $r -eq 0 ] && return 1
    diff -u "${thisd}/golden.stdin.diff" "${gotd}/got"
}

test_id_sh_extract() {
    ./id.sh "$left" > "${gotd}/got"
    diff -u "${thisd}/golden.extract" "${gotd}/got"
}

test_id_sh_stdin_extract() {
    ./id.sh - < "$left" > "${gotd}/got"
    diff -u "${thisd}/golden.extract" "${gotd}/got"
}

test_run_multi "test_id_sh_diff" \
               "test_id_sh_stdin_diff" \
               "test_id_sh_extract" \
               "test_id_sh_stdin_extract"
