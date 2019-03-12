#!/bin/bash 

set -o errtrace
set -e

trap _exit_trap EXIT
trap _err_trap ERR
_showed_traceback=f

_exit_trap() {
  local _ec="$?"
  if [[ $_ec != 0 && "${_showed_traceback}" != t ]]; then
    _traceback 1
  fi
}

_err_trap() {
  local _ec="$?"
  local _cmd="${BASH_COMMAND:-unknown}"
  _traceback 1
  _showed_traceback=t
  echo "The command ${_cmd} exited with exit code ${_ec}." 1>&2
}

_traceback() {
  # Hide the _traceback() call.
  local -i start=$(( ${1:-0} + 1 ))
  local -i end=${#BASH_SOURCE[@]}
  local -i i=0
  local -i j=0

  echo "Traceback (last called is first):" 1>&2
  for ((i=${start}; i < ${end}; i++)); do
    j=$(( $i - 1 ))
    local function="${FUNCNAME[$i]}"
    local file="${BASH_SOURCE[$i]}"
    local line="${BASH_LINENO[$j]}"
    echo "     ${function}() in ${file}:${line}" 1>&2
  done
}

_get_sed() {
  o="sed"
  which gnused 1>/dev/null 2>/dev/null && o="gnused"
  which gsed 1>/dev/null 2>/dev/null && o="gsed"
  echo $o
}

print_info() {
  #? Helper to print message
  local _message=$1
  local _name="Undef"
  if [ ! "$0" == "-bash" ]; then
    _name=$(basename $0)
  fi
  echo -e "[\033[0;96m${_name}\033[0m] ${_message}"
}

print_warn() {
  #? Helper to print warning message
  local _message=$1
  print_info "\033[0;33m${_message}\033[0m"
}

print_err() {
  #? Helper to print error message
  local _message=$1
  print_info "\033[0;31m${_message}\033[0m"
}

print_debug() {
  #? Helper to print debug message
  if [[ "${DEBUG}x" == "truex" ]] ; then
    local _message=$1
    print_info "\033[0;95m${_message}\033[0m"
  fi
}

print_empty() {
  #? To make it clear you want an empty line but with the script name
  print_info ""
}

empty_line() {
  #? To make it clear you want an empty line
  echo
}

generate_horizontal_line() {
  #? [OLD API] Helper to generate an horizontal line. [length] ['CHAR']
  generate_line "$@"
}

generate_line() {
  #? Helper to generate a line. [length] ['CHAR']
  local line_length=${1:-80}
  local line_char=${2:-\-}
  local line=$(printf "%${line_length}s\n" | tr ' ' "${line_char}")
  echo "${line}"
}

wrap_output_with_funcname_on() {
  #? To start prefixing stdout by the Function name
  exec 6>&1  #6 is alias for 1
  exec 7>&2  #7 is alias for 2
  exec &> >($(_get_sed) -u "s/^/\[\x1B[0;92m ${FUNCNAME[1]} \x1B[0m\] /")
}

wrap_output_with_funcname_off() {
  #? To stop prefixing stdout by the Function name
  exec 1>&6 6>&- #Restore stdout and close fd6
  exec 2>&7 7>&- #Restore stderr and close fd7
}
