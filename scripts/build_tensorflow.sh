#!/usr/bin/env bash

VENDOR_DIR="$(pwd)/vendor"
BAZEL_DIR=`cd $VENDOR_DIR; bazel info output_base`
TENSORFLOW_DIR="$BAZEL_DIR/external/org_tensorflow"

# tensorflow: initialize bazel directories
eval "cd $VENDOR_DIR; bazel build @org_tensorflow//tensorflow:all_files"

# tensorflow: do not use interactive configure so can be installed automatically
GEN_GIT_SOURCE=tensorflow/tools/git/gen_git_source.py
eval "cd $TENSORFLOW_DIR; chmod a+x ${GEN_GIT_SOURCE}"
eval "cd $TENSORFLOW_DIR; python ${GEN_GIT_SOURCE} --configure ${TENSORFLOW_DIR}"
# tensorflow: run interactive configure instead of automatic
# if [ ! -d "$TENSORFLOW_DIR/bazel-bin" ]; then
#   eval "cd $TENSORFLOW_DIR; $TENSORFLOW_DIR/configure"
# fi

# tensorflow: build
eval "cd $TENSORFLOW_DIR; bazel build -c opt //tensorflow:libtensorflow.so"
eval "cd $VENDOR_DIR; rm -rf bazel-*"

# protobuf: copy files
mkdir -p $VENDOR_DIR/protobuf/Headers
cp -rf $TENSORFLOW_DIR/bazel-org_tensorflow/external/protobuf/src/ $VENDOR_DIR/protobuf/Headers/
cp -f $TENSORFLOW_DIR/bazel-out/host/bin/external/protobuf/libprotobuf.a $VENDOR_DIR/protobuf/libprotobuf.a

# eiger: copy files
mkdir -p $VENDOR_DIR/eigen/Headers
cp -rf $TENSORFLOW_DIR/bazel-org_tensorflow/external/eigen_archive/ $VENDOR_DIR/eigen/Headers/
mkdir -p $VENDOR_DIR/eigen/Generated
cp -rf $TENSORFLOW_DIR/bazel-org_tensorflow/third_party/ $VENDOR_DIR/eigen/Generated/third_party/

# tensorflow: copy files and rename libtensorflow.dylib to for xcode debugging
mkdir -p $VENDOR_DIR/tensorflow/Headers/tensorflow
cp -rf $TENSORFLOW_DIR/bazel-org_tensorflow/tensorflow/ $VENDOR_DIR/tensorflow/Headers/tensorflow/
mkdir -p $VENDOR_DIR/tensorflow/Generated
cp -rf $TENSORFLOW_DIR/bazel-genfiles/tensorflow/ $VENDOR_DIR/tensorflow/Generated/tensorflow/
cp -f $TENSORFLOW_DIR/bazel-out/local-opt/bin/tensorflow/libtensorflow.so $VENDOR_DIR/tensorflow/libtensorflow.dylib
exec sudo install_name_tool -id $VENDOR_DIR/tensorflow/libtensorflow.dylib $VENDOR_DIR/tensorflow/libtensorflow.dylib

# TODO: figure out why install_name_tool fails, eg. later commands do not execute