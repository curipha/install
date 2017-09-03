#!/usr/bin/env bash

# Install Lua

set -o nounset
set -o errexit

APPLICATION=Lua
VERSION=5.3.4

URIFORMAT='https://www.lua.org/ftp/lua-${VERSION}.tar.gz'


# Functions
help() {
  cat <<HELP 1>&2
Usage: ${0} [-v <version>]

  -v <version>  Set version of ${APPLICATION} (Default = ${VERSION})

Example:
  ${0} -v ${VERSION}
      Install ${APPLICATION} ${VERSION}
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


while getopts hv: ARG; do
  case $ARG in
    "v" ) VERSION="$OPTARG";;
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
puts Making...
${MAKE} "$(uname -s | tr '[:upper:]' '[:lower:]')" > /dev/null

puts Installing...
${MAKE} install INSTALL_TOP="${PREFIX}" > /dev/null

# Clean up
puts Cleaning...
cd "${CUR_DIR}" || exit
rm -fr "${TMP_DIR}"

