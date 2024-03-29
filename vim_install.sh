#!/usr/bin/env bash

# Install Vim

set -o errexit
set -o nounset
set -o pipefail

APPLICATION=Vim
CONFIGURE_OPT=(
  --with-features=normal
  --enable-fail-if-missing
  --enable-multibyte
  --disable-netbeans
)

URI="https://github.com/vim/vim.git"


# Functions
help() {
  cat <<HELP 1>&2
Usage: ${0}

Example:
  ${0}
      Install latest ${APPLICATION}
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


while getopts hl: ARG; do
  case $ARG in
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

# Clone repository
puts Cloning "${URI}" ...
git clone --branch master --depth 1 -- ${URI} .

# Remove files in PREFIX
PREFIX="${HOME}/app/${APPLICATION,,}"
[[ -d "${PREFIX}" ]] && rm -fr "${PREFIX}"

# Make
puts Configuring...
./configure --quiet --prefix="${PREFIX}" "${CONFIGURE_OPT[@]}"

puts Making...
${MAKE} -j 2 > /dev/null

puts Installing...
${MAKE} install > /dev/null

# Clean up
puts Cleaning...
cd "${CUR_DIR}" || exit
rm -fr "${TMP_DIR}"
