#!/bin/bash

SCRIPT_DIR=/home/mic/Code/Helpers/autobuild

# for b in clang libcxx gcc; do
for b in clang libcxx; do
  fn="/tmp/build_nightly_${b}.`date '+%A' | awk '{print tolower($0)}'`"
  touch $fn
  $SCRIPT_DIR/build_nightly_$b &> $fn
done
