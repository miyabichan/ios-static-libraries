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
if [ ! -e "cyrus-sasl-${CYRUS_SASL_VERSION}.tar.gz" ]
then
  curl -O "http://ftp.andrew.cmu.edu/pub/cyrus-mail/cyrus-sasl-${CYRUS_SASL_VERSION}.tar.gz"
fi

# Extract source
rm -rf "cyrus-sasl-${CYRUS_SASL_VERSION}"
tar zxvf "cyrus-sasl-${CYRUS_SASL_VERSION}.tar.gz"

# Build
pushd "cyrus-sasl-${CYRUS_SASL_VERSION}"
CC="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/usr/bin/gcc-4.2"
CFLAGS="-isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDK}.sdk -arch ${ARCH} -pipe -Os -gdwarf-2"
LDFLAGS="-isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDK}.sdk -arch ${ARCH}"
if [ "${SDK}" == "3.2" ]
then
  if [ "${PLATFORM}" == "iPhoneSimulator" ]
  then
    # Work around linker error "ld: library not found for -lcrt1.10.6.o" on iPhone Simulator 3.2
    CFLAGS="${CFLAGS} -mmacosx-version-min=10.5"
    LDFLAGS="${LDFLAGS} -mmacosx-version-min=10.5"
  fi
fi
export CC="${CC}"
export CFLAGS="${CFLAGS}"
export LDFLAGS="${LDFLAGS}"
./configure --prefix="${ROOTDIR}" --host="${ARCH}-apple-darwin" --disable-shared --enable-static --with-openssl="${ROOTDIR}"
(cd lib && make)
(cd include && make saslinclude_HEADERS="hmac-md5.h md5.h sasl.h saslplug.h saslutil.h prop.h" install)
(cd lib && make install)
popd

# Clean up
rm -rf "cyrus-sasl-${CYRUS_SASL_VERSION}"
