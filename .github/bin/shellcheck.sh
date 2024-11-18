#!/bin/bash

{
    git grep -l "^#\!/bin/bash"
    git ls-files | grep "\.sh$"
} | sort -u | grep -v "^tests" | xargs shellcheck
