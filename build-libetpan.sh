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

# Download source
if [ ! -e "libetpan-${LIBETPAN_VERSION}.tar.gz" ]
then
  curl -O "http://switch.dl.sourceforge.net/project/libetpan/libetpan/${LIBETPAN_VERSION}/libetpan-${LIBETPAN_VERSION}.tar.gz"
fi

# Extract source
rm -rf "libetpan-${LIBETPAN_VERSION}"
tar zxvf "libetpan-${LIBETPAN_VERSION}.tar.gz"

# Build
pushd "libetpan-${LIBETPAN_VERSION}/build-mac"
sed '/OpenSSL/d;/openssl/d' "update.sh" > "mini-update.sh"  # Patch update.sh not to download OpenSSL
chmod a+x "mini-update.sh"
./mini-update.sh
rm -rf "OpenSSL"
sed '/HAVE_CURL/d;/HAVE_EXPAT/d;/HAVE_IPV6/d' "../config.h" > "include/config.h"  # Patch include/config.h to disable HAVE_CURL, HAVE_EXPAT and HAVE_IPV6
PWD=`pwd`
${DEVELOPER}/usr/bin/xcodebuild -target "static libetpan iphone" -configuration "Release" -sdk "${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDK}.sdk" build "ARCHS=${ARCH}" "HEADER_SEARCH_PATHS=${PWD}/include ${ROOTDIR}/include"
mv "build/Release-${PLATFORM}/include/libetpan/" "${ROOTDIR}/include/"
mv "build/Release-${PLATFORM}/libetpan-iphone.a" "${ROOTDIR}/lib/libetpan.a"
popd

# Clean up
rm -rf "libetpan-${LIBETPAN_VERSION}"
