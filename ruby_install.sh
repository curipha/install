#!/usr/bin/env bash

# Install Ruby

set -o errexit
set -o nounset
set -o pipefail

APPLICATION=Ruby
VERSION=3.1.0
CONFIGURE_OPT=( --enable-shared --with-out-ext="*dbm*,*win32*" --disable-install-doc )

URIFORMAT='https://cache.ruby-lang.org/pub/ruby/${VERSION:0:3}/ruby-${VERSION}.tar.xz'


# Functions
help() {
  cat <<HELP 1>&2
Usage: ${0} [-v <version>] [ -s <opensslprefix> ]

  -v <version>        Set version of ${APPLICATION} (Default = ${VERSION})
  -s <opensslprefix>  Set <opensslprefix> as OpenSSL prefix

Example:
  ${0} -v ${VERSION}
      Install ${APPLICATION} ${VERSION}

  ${0} -s /usr/local/ssl
      Install ${APPLICATION} ${VERSION} built with OpenSSL on specified prefix
HELP

  exit
}

puts() {
  echo -e "\033[1m${*}\033[0m"
}
abort() {
  echo "$@" 1>&2
  exit 1
}


while getopts hv:s: ARG; do
  case $ARG in
    "v" ) VERSION="$OPTARG";;
    "s" ) CONFIGURE_OPT+=( --with-opt-dir="${OPTARG}" );;
    * ) help;;
  esac
done

case ${OSTYPE} in
  linux*)   MAKE=make;;
  freebsd*) MAKE=gmake;;
  *)
    abort "Unknown OS type: ${OSTYPE}"
  ;;
esac


# Create working directory
CUR_DIR=$(pwd)
TMP_DIR=$(mktemp -d "${APPLICATION,,}.XXXXXXXXXX")

cd "${TMP_DIR}" || exit

# Get tarball
URI=$(eval printf "${URIFORMAT}")
puts Retrieving "${URI}" ...
curl -q --location --remote-name-all --progress-bar --tlsv1.2 "${URI}"

# Extract tarball
HTTP_FILE=${URI##*/}
tar xf "${HTTP_FILE}"

cd "${HTTP_FILE%.tar.[a-z0-9]*}" || exit

# Remove files in PREFIX
PREFIX="${HOME}/app/${APPLICATION,,}"
[[ -d "${PREFIX}" ]] && rm -fr "${PREFIX}"

# Make
puts Configuring...
./configure --quiet --prefix="${PREFIX}" "${CONFIGURE_OPT[@]}"

puts Making...
${MAKE} > /dev/null

puts Installing...
${MAKE} install > /dev/null

# Clean up
puts Cleaning...
cd "${CUR_DIR}" || exit
rm -fr "${TMP_DIR}"
