#!/usr/bin/env bash

# Install Vim

set -o nounset
set -o errexit

APPLICATION=Vim
CONFIGURE_OPT=( --with-features=normal --enable-multibyte --enable-terminal --disable-netbeans --enable-fail-if-missing )

URI="https://github.com/vim/vim.git"


# Functions
help() {
  cat <<HELP 1>&2
Usage: ${0} [-l <luaprefix>]

  -l <luaprefix>  Enable Lua with <luaprefix> as its prefix
                  (If <luaprefix> = "-", it treats that Lua exists on PATH.)

Example:
  ${0} -l \$HOME/app/lua
      Install latest ${APPLICATION} with Lua
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
    "l" )
      CONFIGURE_OPT+=( --enable-luainterp )
      [[ "${OPTARG}" != "-" ]] && CONFIGURE_OPT+=( --with-lua-prefix="${OPTARG}" )
    ;;
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
${MAKE} > /dev/null

puts Installing...
${MAKE} install > /dev/null

# Clean up
puts Cleaning...
cd "${CUR_DIR}" || exit
rm -fr "${TMP_DIR}"

