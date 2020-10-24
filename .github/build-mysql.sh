#!/bin/bash

MYSQL_VERSION=$1
ROOT=$(cd "$(dirname "$0")" && pwd)
: "${RUNNER_TEMP:=$ROOT/working}"
: "${RUNNER_TOOL_CACHE:=$ROOT/dist}"
PREFIX=$RUNNER_TOOL_CACHE/mysql/$MYSQL_VERSION/x64

echo "::group::download MySQL souce"
(
    set -eux
    mkdir -p "$RUNNER_TEMP"
    cd "$RUNNER_TEMP"
    rm -rf ./*
    curl -sSL "https://github.com/mysql/mysql-server/archive/mysql-$MYSQL_VERSION.tar.gz" -o mysql-src.tar.gz
)
echo "::endgroup::"

echo "::group::extract"
(
    set -eux
    cd "$RUNNER_TEMP"
    tar zxvf mysql-src.tar.gz
)
echo "::endgroup::"

echo "::group::build"
(
    set -eux
    # detect the number of CPU Core
    JOBS=1
    if command -v sysctl > /dev/null; then
        # on macOX
        JOBS=$(sysctl -n hw.logicalcpu_max || echo "$JOBS")
    fi
    if command -v nproc > /dev/null; then
        # on Linux
        JOBS=$(nproc || echo "$JOBS")
    fi

    # build
    cd "$RUNNER_TEMP"
    mkdir build
    cd build
    cmake "../mysql-server-mysql-$MYSQL_VERSION" -DDOWNLOAD_BOOST=1 -DWITH_BOOST=../boost -DCMAKE_INSTALL_PREFIX="$PREFIX"
    make "-j$JOBS"
)
echo "::endgroup::"

echo "::group::install"
(
    set -eux
    cd "$RUNNER_TEMP/build"
    make install
)
echo "::endgroup::"

# archive
echo "::group::archive"
(
    set -eux
    cd "$PREFIX"
    tar vczf "$RUNNER_TEMP/mysql.tar.gz" .
)
echo "::endgroup::"