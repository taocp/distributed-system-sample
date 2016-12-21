#!/bin/bash

set -e -u -E # this script will exit if any sub-command fails
set -x

########################################
# download & build depend software
########################################

WORK_DIR=$(cd $(dirname $0); pwd)
DEPS_SOURCE=$WORK_DIR/thirdsrc
DEPS_PREFIX=$WORK_DIR/thirdparty
DEPS_CONFIG="--prefix=${DEPS_PREFIX} --disable-shared --with-pic"
FLAG_DIR=$WORK_DIR/.build

export PATH=${DEPS_PREFIX}/bin:$PATH
mkdir -p ${DEPS_SOURCE} ${DEPS_PREFIX} ${FLAG_DIR}

if [ ! -f "$WORK_DIR/depends.mk" ]; then
    cp $WORK_DIR/depends.mk.template $WORK_DIR/depends.mk
fi

cd ${DEPS_SOURCE}

if [ ! -f "${FLAG_DIR}/boost_1_58_0"  ] \
    || [ ! -d "${DEPS_PREFIX}/boost_1_58_0/boost"  ]; then
    wget --no-check-certificate -O boost_1_58_0.tar.bz2 http://mirrors.163.com/gentoo/distfiles/boost_1_58_0.tar.bz2
    tar xjf boost_1_58_0.tar.bz2 --recursive-unlink
    rm -rf ${DEPS_PREFIX}/boost_1_58_0
    mv boost_1_58_0 ${DEPS_PREFIX}
    touch "${FLAG_DIR}/boost_1_58_0"
fi

# protobuf
if [ ! -f "${FLAG_DIR}/protobuf_2_6_1" ] \
    || [ ! -f "${DEPS_PREFIX}/lib/libprotobuf.a" ] \
    || [ ! -d "${DEPS_PREFIX}/include/google/protobuf" ]; then
	# f**k gfw
    # wget --no-check-certificate https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz
    rm -rf protobuf
    git clone --depth=1 https://github.com/00k/protobuf
    mv protobuf/protobuf-2.6.1.tar.gz .
    tar zxf protobuf-2.6.1.tar.gz
    cd protobuf-2.6.1
    ./configure ${DEPS_CONFIG}
    make -j4
    make install
    cd -
    touch "${FLAG_DIR}/protobuf_2_6_1"
fi

# snappy
if [ ! -f "${FLAG_DIR}/snappy_1_1_1" ] \
    || [ ! -f "${DEPS_PREFIX}/lib/libsnappy.a" ] \
    || [ ! -f "${DEPS_PREFIX}/include/snappy.h" ]; then
    rm -rf snappy
    git clone --depth=1 https://github.com/00k/snappy
    mv snappy/snappy-1.1.1.tar.gz .
    tar zxf snappy-1.1.1.tar.gz
    cd snappy-1.1.1
    ./configure ${DEPS_CONFIG}
    make -j4
    make install
    cd -
    touch "${FLAG_DIR}/snappy_1_1_1"
fi

# sofa-pbrpc
if [ ! -f "${FLAG_DIR}/sofa-pbrpc_1_1_0" ] \
    || [ ! -f "${DEPS_PREFIX}/lib/libsofa-pbrpc.a" ] \
    || [ ! -d "${DEPS_PREFIX}/include/sofa/pbrpc" ]; then
    wget --no-check-certificate -O sofa-pbrpc-1.1.0.tar.gz https://github.com/baidu/sofa-pbrpc/archive/v1.1.0.tar.gz
    tar zxf sofa-pbrpc-1.1.0.tar.gz
    cd sofa-pbrpc-1.1.0
    #sed -i '' '/BOOST_HEADER_DIR=/ d' depends.mk # for Mac
    #sed -i '' '/PROTOBUF_DIR=/ d' depends.mk
    #sed -i '' '/SNAPPY_DIR=/ d' depends.mk
    sed -i '/BOOST_HEADER_DIR=/ d' depends.mk  # for Linux
    sed -i '/PROTOBUF_DIR=/ d' depends.mk
    sed -i '/SNAPPY_DIR=/ d' depends.mk
    echo "BOOST_HEADER_DIR=${DEPS_PREFIX}/boost_1_58_0" >> depends.mk
    echo "PROTOBUF_DIR=${DEPS_PREFIX}" >> depends.mk
    echo "SNAPPY_DIR=${DEPS_PREFIX}" >> depends.mk
    echo "PREFIX=${DEPS_PREFIX}" >> depends.mk
    cd src
    #PROTOBUF_DIR=${DEPS_PREFIX} sh compile_proto.sh
    cd ..
    make -j4
    make install
    cd ..
    touch "${FLAG_DIR}/sofa-pbrpc_1_1_0"
fi

## cmake for gflags
#if [ ! -f "${DEPS_PREFIX}/bin/cmake" ] ; then
#    wget --no-check-certificate -O CMake-3.2.1.tar.gz http://github.com/Kitware/CMake/archive/v3.2.1.tar.gz
#    tar zxf CMake-3.2.1.tar.gz
#    cd CMake-3.2.1
#    ./configure --prefix=${DEPS_PREFIX}
#    make -j4
#    make install
#    cd -
#fi

# gflags
if [ ! -f "${FLAG_DIR}/gflags_2_1_1" ] \
    || [ ! -f "${DEPS_PREFIX}/lib/libgflags.a" ] \
    || [ ! -d "${DEPS_PREFIX}/include/gflags" ]; then
    wget --no-check-certificate -O gflags-2.1.1.tar.gz https://github.com/schuhschuh/gflags/archive/v2.1.1.tar.gz
    tar zxf gflags-2.1.1.tar.gz
    cd gflags-2.1.1
    cmake -DCMAKE_INSTALL_PREFIX=${DEPS_PREFIX} -DGFLAGS_NAMESPACE=google -DCMAKE_CXX_FLAGS=-fPIC
    make -j4
    make install
    cd -
    touch "${FLAG_DIR}/gflags_2_1_1"
fi

cd ${WORK_DIR}

########################################
# config depengs.mk
########################################

sed -i  "s:^SOFA_PBRPC_DIR=.*:SOFA_PBRPC_DIR=$DEPS_PREFIX:" depends.mk
sed -i  "s:^PROTOBUF_DIR=.*:PROTOBUF_DIR=$DEPS_PREFIX:" depends.mk
sed -i  "s:^SNAPPY_DIR=.*:SNAPPY_DIR=$DEPS_PREFIX:" depends.mk
sed -i  "s:^GFLAGS_DIR=.*:GFLAGS_DIR=$DEPS_PREFIX:" depends.mk
sed -i  "s:^BOOST_DIR=.*:BOOST_DIR=$DEPS_PREFIX/boost_1_58_0:" depends.mk
