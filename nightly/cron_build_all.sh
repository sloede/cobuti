#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

for b in llvm libcxx llvm-openmp; do
  fn="/tmp/build_nightly_${b}.`date '+%A' | awk '{print tolower($0)}'`"
  touch $fn
  $SCRIPT_DIR/build_nightly_$b &> $fn
done
