#!/bin/bash

usage() {
    cat <<EOF
  Usage:
    $0 --OPTIONS* ON WHAT

  Move WHAT commit down, directly on top of ON, within HEAD,
  then rebase.

  OPTIONS are handled by being passed to weld.

EOF
}

while test -z "${opt_done}"
do
    case "$1"
        in
        "--"* )
            WELD_EXTRA_OPTIONS+=" ${1}"
            shift
            ;;
        * )
            break
            ;;
    esac
done

ON="$1"
WHAT="$2"

weld --no-weld --no-amend ${WELD_EXTRA_OPTIONS} "${ON}" "${WHAT}"

