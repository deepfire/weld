#!/bin/bash

usage() {
    cat <<EOF
  Usage:
    $0 --OPTIONS* COMMIT]

  Drop COMMIT from HEAD, via rebase.

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

COMMIT="$1"

weld --drop-commit ${WELD_EXTRA_OPTIONS} "${COMMIT}"

