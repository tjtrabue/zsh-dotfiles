#!/usr/bin/env bash

# Trap errors and print error message
set -euo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Variables {{{
declare DOTFILES_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)";
declare THIS_EXEC="$(basename "${BASH_SOURCE[0]}")";

declare IMPORT="${DOTFILES_REPO}/bash/source";
declare VERBOSE=false;
# }}}

# Imports {{{
source "${IMPORT}/colors.bash";
source "${IMPORT}/functions_log.bash";
# }}}

# Functions {{{
_help() {
  cat <<EOF
${THIS_EXEC}

<insert description here>

USAGE:
  ${THIS_EXEC} [OPTIONS]

OPTIONS:
  -h | --help
    Print the help message (this message) and exit.

  -v | --verbose
    Run with extra logging output.
EOF
exit 0;
}

main() {
  log_info "Hello, world!";
}
# }}}

# Parse CLI Options {{{
args=$(getopt -o hvf --long help,verbose,full-install -n 'init_arch' -- "$@")
eval set -- "$args"

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -v | --verbose)
      VERBOSE=true;
      shift;
      ;;

    -h | --help)
      _help;
      shift;
      break;
      ;;

    --)
      shift;
      break
      ;;

    *)
      err "Unknown option $1 to ${THIS_EXEC}"
      exit 2
      ;;
  esac
done
# }}}

main "${@}";

# vim:foldenable:foldmethod=marker:
