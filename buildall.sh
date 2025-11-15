#!/bin/bash
set -e

git switch android15-lineage22-mod

bash build_aosp.sh
rm -rf anykernel out
git reset --hard HEAD
bash build.sh

rm -rf anykernel out
git reset --hard HEAD

git switch backport-5.4-bpf-test

bash build_aosp.sh bpf
rm -rf anykernel out
git reset --hard HEAD
bash build.sh bpf