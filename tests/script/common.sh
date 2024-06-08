#!/bin/bash

test_projectd() {
    git rev-parse --show-toplevel
}

test_log() {
    echo "[test] $*" > /dev/stderr
}

test_run() {
    test_log "Start $1"
    "$1"
    ret=$?
    test_log "End $1"
    return $ret
}

test_run_multi() {
    result="$(mktemp)"

    ret=0
    while [ -n "$1" ] ; do
        test_run $1
        r=$?
        if [ $r -gt 0 ] ; then
            ret=$r
        fi
        echo "$1 ${r}" >> "$result"
        shift
    done

    test_log "----------"
    cat "$result" > /dev/stderr
    return $ret
}
