#!/bin/sh

username="$1"

line="$(grep -w ^${username} AUTHORS)"
grep_exit_code="$?"
test "${grep_exit_code}" != "0" && {
	echo "ERROR: unknown author username: ${username}" >&2
	exit 1
}
echo ${line} | cut -d" " -f2-

