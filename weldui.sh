#!/bin/bash

usage() {
    cat <<EOF
  Usage:
    $0 --OPTIONS* COMMIT [BRANCH]

  Interactively amend COMMIT, rebasing BRANCH atop changes.

  When BRANCH is not specified, current HEAD is assumed.

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

BRANCH="${2:-$(git symbolic-ref HEAD | sed s%refs/heads/%%)}"

weld --no-cherry --no-weld --manual-amend ${WELD_EXTRA_OPTIONS} "${BRANCH}" "${COMMIT}"

