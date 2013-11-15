#!/bin/bash

usage() {
    cat <<EOF
  Usage:
    $0 --OPTIONS* NICKNAME COMMIT [BRANCH]

  Re-author COMMIT to NICKNAME, rebasing BRANCH atop changes.

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

NICKNAME="$1"
COMMIT="$2"

BRANCH="${3:-$(git symbolic-ref HEAD | sed s%refs/heads/%%)}"

weld --reauthor-commit ${NICKNAME} "${BRANCH}" "${COMMIT}"

