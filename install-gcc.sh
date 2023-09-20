#!/bin/bash

# Exit on any error
set -e

# Define GCC version
GCC_VERSION="10.2.0"
BUILD_DIR="gcc-build"

function compile_gcc() {
    # Delete previous installations and build directories (use with caution)
    sudo rm -rf /opt/gcc-${GCC_VERSION}
    rm -rf ${BUILD_DIR}
    rm -rf gcc-${GCC_VERSION}

    # Install dependencies
    sudo yum install -y wget gcc-c++ glibc-static libstdc++-static libmpc-devel mpfr-devel gmp-devel zlib-devel

    # Define download URL
    MIRROR_URL="http://mirrors.concertpass.com/gcc/releases/gcc-${GCC_VERSION}"
    DOWNLOAD_FILE="gcc-${GCC_VERSION}.tar.gz"

    # Download and extract the source
    wget ${MIRROR_URL}/$DOWNLOAD_FILE
    tar -xzf $DOWNLOAD_FILE
    rm -f $DOWNLOAD_FILE

    cd gcc-${GCC_VERSION}

    # Download prerequisites
    ./contrib/download_prerequisites

    # Create build directory and navigate to it
    cd ..
    mkdir ${BUILD_DIR}
    cd ${BUILD_DIR}

    # Configure, build, and install
    ../gcc-${GCC_VERSION}/configure --prefix=/opt/gcc-${GCC_VERSION} --enable-languages=c,c++ --disable-multilib
    make -j$(nproc)
    sudo make install
}

function download_gcc() {
    # Delete previous installations (use with caution)
    sudo rm -rf /opt/gcc-${GCC_VERSION}
    
    # Assuming you're providing a direct link to the compiled tarball for GCC
    DOWNLOAD_LINK=$1

    # Download and extract the compiled GCC
    wget $DOWNLOAD_LINK -O gcc-${GCC_VERSION}.tar.gz
    sudo tar -xzvf gcc-${GCC_VERSION}.tar.gz -C /opt
}

function recover_symlinks() {
    # Restore previous symlinks
    if [ -e "/lib/libstdc++.so.6.bak" ]; then
        sudo mv /lib/libstdc++.so.6.bak /lib/libstdc++.so.6
    fi

    if [ -d "/lib64" ] && [ -e "/lib64/libstdc++.so.6.bak" ]; then
        sudo mv /lib64/libstdc++.so.6.bak /lib64/libstdc++.so.6
    fi

    sudo ldconfig
}

case "$1" in
    compile)
        compile_gcc
        ;;
    download)
        if [ -z "$2" ]; then
            echo "Please provide a download link for the compiled GCC tarball."
            exit 1
        fi
        download_gcc $2
        ;;
    recover)
        recover_symlinks
        ;;
    *)
        echo "Usage: $0 {compile|download|recover}"
        exit 1
esac
