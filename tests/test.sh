#!/bin/bash

pip install PyYAML==6.0.1

thisd="$(cd $(dirname $0); pwd)"
find "${thisd}/script" -type f -name test.sh | xargs -n 1 bash
