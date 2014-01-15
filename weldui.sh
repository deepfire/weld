#!/bin/bash

usage() {
    cat <<EOF
  Usage:
    $0 --OPTIONS* COMMIT

  Interactively amend COMMIT, rebasing HEAD atop changes.

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

weld --no-cherry --no-weld --manual-amend ${WELD_EXTRA_OPTIONS} "${COMMIT}"

