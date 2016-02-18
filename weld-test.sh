#!/usr/bin/env bash

at_exit() {
	rm -rf /tmp/weldtest*
}
trap at_exit EXIT

with_test_repo() {
	tmpdir=$(mktemp -d /tmp/weldtestXXXX)

	mkdir -p ${tmpdir}
	cd ${tmpdir}
	git init --quiet
	for ((i=0; i<5; i++))
	do
		touch $i
		git add $i
		git commit --message $i --quiet
	done
	eval "$1" >${tmpdir}/.git/stdout 2>${tmpdir}/.git/stderr
	shift
	"$@"
	rm -rf ${tmpdir}
}

expect_files() {
	test "$*" = "$(ls | sed ':a;/$/{N;s/\n/ /;ba}')"
}

expect_history() {
	test "$*" = "$(git log --pretty=format:%s | sed '$ a\\n' | tac | tail -n+3 | sed ':a;/$/{N;s/\n/ /;ba}')"
}

expect_branches() {
	test "$*" = "$(git branch | tr -d ' *' | sed ':a;/$/{N;s/\n/ /;ba}')"
}

export -f expect_files expect_history expect_branches

n_success=0
n_expectfail=0

summarize() {
	cat <<EOF
#
# Test results:
#
#          successful:  ${n_success}
#   expected failures:  ${n_expectfail}
#
EOF
}

check_one() {
	local name="$1"; subtest="$2"; expectation="$3"; shift 3

	if ! bash -c "set -x; ${subtest} $*" 2> ${tmpdir}/.git/check
	then if test ${expectation} = 'fail'
	     then
		     echo -e "--- check:"; cat ${tmpdir}/.git/check
		     echo -e "EXPECTED FAIL ${name}:${subtest}"
		     n_expectfail=$((n_expectfail+1))
		     return 0
	     fi
	     echo -e "--- stdout:"; cat ${tmpdir}/.git/stdout
	     echo -e "--- stderr:"; cat ${tmpdir}/.git/stderr
	     echo -e "--- check:"; cat ${tmpdir}/.git/check
	     trap '' EXIT
	     echo -e "--- test ${name} FAILED"
	     echo "--- changing directory ${tmpdir}"
	     echo "--- debug:  set -x; $@"
	     echo -e "FAIL ${name}:${subtest}"
	     bash
	     exit 1
	else
		n_success=$((n_success+1))
	fi
}

check() {
	local name="$1"; shift
	local cmd

	declare -a cmd=()
	for x in "$@"
	do
		if test "${x}" != ";"
		then
			cmd+=("${x}")
		else
			eval check_one "${name}" "${cmd[@]}"
			cmd=()
		fi
	done
	if test "${#cmd[@]}" != 0
	then
		eval check_one "${name}" "${cmd[@]}"
	fi
}

run_test() {
	local name="$1"; shift
	local cmd="$1";  shift

	printf -- "%15s:  %30s;  expecting: $*\n" "${name}" "${cmd}"
	with_test_repo "${cmd}" check ${name} "$@"
}

###
### Tests
###
run_test "DROP"                                             \
	 "weldrop --yes HEAD~2"                             \
	 expect_history    pass 0 1   3 4               ";" \
	 expect_files      pass 0 1   3 4

run_test "MOVE-DOWN"                                        \
	 "weldmove --yes HEAD~3 HEAD~1"                     \
	 expect_history    pass 0 1 3 2 4               ";" \
	 expect_files      pass 0 1 2 3 4

run_test "MOVE-UP"                                          \
	 "weldmove --yes HEAD~1 HEAD~3"                     \
	 expect_history    pass 0 2 3 1 4               ";" \
	 expect_files      pass 0 1 2 3 4

run_test "WELD-2-ARG"                                       \
	 "weld HEAD~3 HEAD~1"                               \
	 expect_history    pass 0 1 2   4               ";" \
	 expect_files      pass 0 1 2 3 4

run_test "WELD-1-ARG"                                       \
	 "weld HEAD~3"                                      \
	 expect_history    pass 0 1 2 3                 ";" \
	 expect_files      pass 0 1 2 3 4

run_test "WELDIT"                                           \
	 "weldit --message lol HEAD~1"                      \
	 expect_history    pass 0 1 2 lol 4             ";" \
	 expect_files      pass 0 1 2 3 4

run_test "WELD-TREE"                                        \
	 "touch 6; weld --yes HEAD~3 tree"                  \
	 expect_history    pass 0 1 2 3 4               ";" \
         expect_files      pass 0 1 2 3 4 6             ";" \
	 expect_branches   fail "master"

summarize
