#!/bin/bash

# Some logics of this script are copied from [scripts/build_kernel]. Thanks to UtsavBalar1231.

# Ensure the script exits on error
set -e

TOOLCHAIN_PATH=$HOME/toolchain/zyc-clang/bin
GIT_COMMIT_ID=$(git rev-parse --short=8 HEAD)

# Enable ccache for speed up compiling 
export CCACHE_DIR="$HOME/.cache/ccache_mikernel" 
export CC="ccache gcc"
export CXX="ccache g++"
export PATH="/usr/lib/ccache/bin:$TOOLCHAIN_PATH:$PATH"
echo "CCACHE_DIR: [$CCACHE_DIR]"

MAKE_ARGS="AS=as ARCH=arm64 SUBARCH=arm64 O=out CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu-"

# Check clang is existing.
echo "[clang --version]:"
clang --version

echo "Cleaning..."

rm -rf out/
rm -rf anykernel/

echo "Clone AnyKernel3 for packing kernel (repo: https://github.com/liyafe1997/AnyKernel3)"
git clone https://github.com/liyafe1997/AnyKernel3 -b kona --single-branch --depth=1 anykernel

# Add date to local version
local_version_str="-perf"

if [ "$1" == "bpf" ]; then
local_version_date_str="-O2-bpf-$(date +%Y%m%d)-${GIT_COMMIT_ID}-perf"
else
local_version_date_str="-O2-$(date +%Y%m%d)-${GIT_COMMIT_ID}-perf"
fi

sed -i "s/${local_version_str}/${local_version_date_str}/g" arch/arm64/configs/enuma_defconfig

echo "Building for AOSP......"
make CC="ccache clang" CXX="ccache clang++" $MAKE_ARGS enuma_defconfig

scripts/config --file out/.config \
    -d CC_WERROR \
    -e KSU \
    -e KSU_TRACEPOINT_HOOK \
    -e KSU_SUSFS_HAS_MAGIC_MOUNT \
    -e KSU_SUSFS \
    -e KPM

make CC="ccache clang" CXX="ccache clang++" $MAKE_ARGS -j$(nproc)


if [ -f "out/arch/arm64/boot/Image" ]; then
    echo "The file [out/arch/arm64/boot/Image] exists. AOSP Build successfully."
else
    echo "The file [out/arch/arm64/boot/Image] does not exist. Seems AOSP build failed."
    exit 1
fi

echo "Generating [out/arch/arm64/boot/dtb]......"
find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb

rm -rf anykernel/kernels/

mkdir -p anykernel/kernels/

# Patch for SukiSU KPM support. 
cd out/arch/arm64/boot/
wget https://github.com/SukiSU-Ultra/SukiSU_KernelPatch_patch/releases/download/0.12.0/patch_linux
chmod +x patch_linux
./patch_linux
rm Image
mv oImage Image
cd -

cp out/arch/arm64/boot/Image anykernel/kernels/
cp out/arch/arm64/boot/dtb anykernel/kernels/

cd anykernel 

if [ "$1" == "bpf" ]; then
ZIP_FILENAME=anykernel3_aosp_bpf_$(date +'%Y%m%d_%H%M%S')_${GIT_COMMIT_ID}.zip
else
ZIP_FILENAME=anykernel3_aosp_$(date +'%Y%m%d_%H%M%S')_${GIT_COMMIT_ID}.zip
fi

zip -r9 $ZIP_FILENAME ./* -x .git .gitignore out/ ./*.zip

mv $ZIP_FILENAME ../

cd ..


echo "Build for AOSP finished."

echo "Done. The flashable zip is: [./$ZIP_FILENAME]"
