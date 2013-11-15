#!/bin/bash

usage() {
    cat <<EOF
  Usage:
    $0 --OPTIONS* ON WHAT [BRANCH]

  Move WHAT commit down, directly on top of ON, within BRANCH,
  then rebase.

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

ON="$1"
WHAT="$2"

BRANCH="${3:-$(git symbolic-ref HEAD | sed s%refs/heads/%%)}"

weld --no-cherry --no-mutate ${WELD_EXTRA_OPTIONS} "${BRANCH}" "${ON}" "${WHAT}"

