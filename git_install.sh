#!/usr/bin/env bash

# Install Git

set -o nounset
set -o errexit

APPLICATION=Git
VERSION=2.33.1
CONFIGURE_OPT=( USE_LIBPCRE1=1 NO_EXPAT=1 NO_TCLTK=1 NO_GETTEXT=1 ) # Change to USE_LIBPCRE2 if you want to use PCRE v2

URIFORMAT='https://www.kernel.org/pub/software/scm/git/git-${VERSION}.tar.xz'
URIFORMAT_SIG='https://www.kernel.org/pub/software/scm/git/git-${VERSION}.tar.sign'


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

# Get tarball and signature
URI=$(eval printf "${URIFORMAT}")
URI_SIG=$(eval printf "${URIFORMAT_SIG}")
puts Retrieving "${URI}" and signature ...
curl -q --location --remote-name-all --progress-bar --tlsv1.2 "${URI}" "${URI_SIG}"

# Verify signature
puts Verifying...
SIG_FILE=${URI_SIG##*/}
unxz --quiet --keep "${URI##*/}"
gpg \
  --keyserver hkps://keyserver.ubuntu.com:443 \
  --keyserver-options timeout=10 \
  --recv-keys "$(gpg --list-packets "${SIG_FILE}" | grep -m1 keyid | grep -Eo '[0-9A-F]{16}')" || abort Failed to receive key
gpg --verify "${SIG_FILE}" || abort Failed to verify signature

# Extract tarball
HTTP_FILE=${URI##*/}
tar xf "${HTTP_FILE}"

cd "${HTTP_FILE%.tar.[a-z0-9]*}" || exit

# Remove files in PREFIX
PREFIX="${HOME}/app/${APPLICATION,,}"
[[ -d "${PREFIX}" ]] && rm -fr "${PREFIX}"

# Make
puts Making...
${MAKE} prefix="${PREFIX}" CFLAGS="${CFLAGS:--O2 -pipe -w}" "${CONFIGURE_OPT[@]}" all > /dev/null

puts Installing...
${MAKE} prefix="${PREFIX}" CFLAGS="${CFLAGS:--O2 -pipe -w}" "${CONFIGURE_OPT[@]}" install > /dev/null

# Clean up
puts Cleaning...
cd "${CUR_DIR}" || exit
rm -fr "${TMP_DIR}"
