#!/bin/sh
set -e

# Copyright (c) 2010, Pierre-Olivier Latour
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * The name of Pierre-Olivier Latour may not be used to endorse or
#       promote products derived from this software without specific prior
#       written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Retrieve iOS SDK to use
SDK=$1
if [ "${SDK}" == "" ]
then
  AVAIL_SDKS=`xcodebuild -showsdks | grep "iphoneos"`
  FIRST_SDK=`echo "$AVAIL_SDKS" | head -n1`
  if [ "$AVAIL_SDKS" == "$FIRST_SDK" ]; then
    SDK=`echo "$FIRST_SDK" | cut -d\  -f2`
    echo "No iOS SDK specified. Using the only one available: $SDK"
  else
    echo "Please specify an iOS SDK version number from the following possibilities:"
    echo "$AVAIL_SDKS"
    exit 1
  fi
fi

# Project version to use to build c-ares (changing this may break the build)
export CARES_VERSION="1.7.3"

# Project version to use to build bzip2 (changing this may break the build)
export BZIP2_VERSION="1.0.6"

# Project version to use to build expat (changing this may break the build)
export EXPAT_VERSION="2.0.1"

# Project version to use to build zlib (changing this may break the build)
export ZLIB_VERSION="1.2.6"

# Project versions to use to build libEtPan (changing this may break the build)
export OPENSSL_VERSION="1.0.0c"
export CYRUS_SASL_VERSION="2.1.23"
export LIBETPAN_VERSION="1.0"

# Project versions to use to build libssh2 and cURL (changing this may break the build)
export GNUPG_VERSION="1.4.11"
export LIBGPG_ERROR_VERSION="1.10"
export LIBGCRYPT_VERSION="1.4.6"
export LIBSSH2_VERSION="1.2.7"
export CURL_VERSION="7.21.3"

# Platforms to build for (changing this may break the build)
PLATFORMS="iPhoneSimulator iPhoneOS-V6 iPhoneOS-V7"

# Build projects
DEVELOPER=`xcode-select --print-path`
TOPDIR=`pwd`
for PLATFORM in ${PLATFORMS}
do
  ROOTDIR="${TOPDIR}/${PLATFORM}-${SDK}"
  if [ "${PLATFORM}" == "iPhoneOS-V7" ]
  then
    PLATFORM="iPhoneOS"
    ARCH="armv7"
  elif [ "${PLATFORM}" == "iPhoneOS-V6" ]
  then
    PLATFORM="iPhoneOS"
    ARCH="armv6"
  else
    ARCH="i386"
  fi
  rm -rf "${ROOTDIR}"
  mkdir -p "${ROOTDIR}"
  
  export DEVELOPER="${DEVELOPER}"
  export ROOTDIR="${ROOTDIR}"
  export PLATFORM="${PLATFORM}"
  export SDK="${SDK}"
  export ARCH="${ARCH}"
  
  # Build c-ares
  ./build-cares.sh > "${ROOTDIR}-cares.log"

  # Build bzip2
  ./build-bzip2.sh > "${ROOTDIR}-bzip2.log"

  # Build expat
  ./build-expat.sh > "${ROOTDIR}-expat.log"

  # Build zlib
  ./build-zlib.sh > "${ROOTDIR}-zlib.log"
  
  # Build OpenSSL
  ./build-openssl.sh > "${ROOTDIR}-OpenSSL.log"
  
  # Build Cyrus SASL
  ./build-cyrus-sasl.sh > "${ROOTDIR}-Cyrus-SASL.log"
  
  # Build libEtPan
  ./build-libetpan.sh > "${ROOTDIR}-libEtPan.log"
  
  # Build GnuPG
  ./build-GnuPG.sh > "${ROOTDIR}-GnuPG.log"
  
  # Build libgpg-error
  ./build-libgpg-error.sh > "${ROOTDIR}-libgpg-error.log"
  
  # Build libgcrypt
  ./build-libgcrypt.sh > "${ROOTDIR}-libgcrypt.log"
  
  # Build libssh2
  ./build-libssh2.sh > "${ROOTDIR}-libssh2.log"
  
  # Build cURL
  ./build-cURL.sh > "${ROOTDIR}-cURL.log"
  
  # Remove junk
  rm -rf "${ROOTDIR}/bin"
  rm -rf "${ROOTDIR}/certs"
  rm -rf "${ROOTDIR}/libexec"
  rm -rf "${ROOTDIR}/man"
  rm -rf "${ROOTDIR}/misc"
  rm -rf "${ROOTDIR}/private"
  rm -rf "${ROOTDIR}/sbin"
  rm -rf "${ROOTDIR}/share"
  rm -rf "${ROOTDIR}/openssl.cnf"
done

# Create archive if necessary
if [ "$2" == "--create-archive" ]
then
  DIRECTORY="Binaries"
  DATE=`date -u "+%Y-%m-%d-%H%M%S"`
  ARCHIVE="ios-libraries-${DATE}.zip"
  MANIFEST="SDK ${SDK}\nOpenSSL ${OPENSSL_VERSION}\nCyrus SASL ${CYRUS_SASL_VERSION}\nlibEtPan ${LIBETPAN_VERSION}\nzlib ${ZLIB_VERSION}\nGnuPG ${GNUPG_VERSION}\nlibgpg-error ${LIBGPG_ERROR_VERSION}\nlibgcrypt ${LIBGCRYPT_VERSION}\nlibssh2 ${LIBSSH2_VERSION}\ncURL ${CURL_VERSION}"
  SUMMARY="SDK ${SDK} + OpenSSL ${OPENSSL_VERSION} + Cyrus SASL ${CYRUS_SASL_VERSION} + libEtPan ${LIBETPAN_VERSION} + zlib ${ZLIB_VERSION} + GnuPG ${GNUPG_VERSION} + libgpg-error ${LIBGPG_ERROR_VERSION} + libgcrypt ${LIBGCRYPT_VERSION} + libssh2 ${LIBSSH2_VERSION} + cURL ${CURL_VERSION}"
  
  # Build archive
  mkdir -p "${DIRECTORY}"
  echo "${MANIFEST}" > "${DIRECTORY}/Manifest.txt"
  for PLATFORM in ${PLATFORMS}; do
    mv "${PLATFORM}-${SDK}" "${DIRECTORY}"
  done
  ditto -c -k --keepParent "${DIRECTORY}" "${ARCHIVE}"
  rm -rf "${DIRECTORY}"
  
  # Upload to Google Code
  if [ "$3" != "" ]
  then
    ./googlecode_upload.pl --file "${ARCHIVE}" --summary "${SUMMARY}" --labels "Type-Archive" --project "ios-static-libraries" --user "$3"
  fi
fi
