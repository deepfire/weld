#!/bin/sh

username="$1"
authors_db="${2:-AUTHORS}"

line="$(grep -w ^${username} ${authors_db})"
grep_exit_code="$?"
test "${grep_exit_code}" != "0" && {
	echo "ERROR: unknown author username: ${username}" >&2
	exit 1
}
echo ${line} | cut -d" " -f2-

