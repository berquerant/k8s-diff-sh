#!/bin/bash

thisd="$(cd $(dirname $0); pwd)"
. "${thisd}/../common.sh"
cd "$(test_projectd)"

left="tests/data/kustomize/overlays/left"
right="tests/data/kustomize/overlays/right"
gotd="$(mktemp -d)"
mkdir -p "$gotd"

test_kustomize_diff() {
    ./kustomize.sh "$left" "$right" > "${gotd}/got"
    diff -u "${thisd}/golden.diff" "${gotd}/got"
}


test_run_multi "test_kustomize_diff"
