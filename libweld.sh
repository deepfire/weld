## Generic
error() {
	echo "ERROR: $1" >&2
	exit 1
}

random() {
	hexdump -n 2 -e '/2 "%u"' /dev/urandom # 'dash' has no ${RANDOM}
}
validate_random() {
	if test -z "$(random)"
	then error "libweld.sh:random() evaluates to an empty string, which seems not random enough.  Cannot continue."
	fi
}

## Context layer
CTX_STORE=.git/weld-context
CTX_CMDLINE="$@"
ctx_path() {
	echo ${CTX_STORE}
}
ctx_present_p() {
	test -f ${CTX_STORE}
}
ctx_save_var() {
	local var="$1"
        eval "echo \"${var}=\\\"\${$var}\\\"\"" >> ${CTX_STORE}
}
ctx_commit_phase() {
	local phase=$1
	local value=$2
	eval "$1=${2:-t}"
	ctx_save_var ${phase}
}
ctx_continue() {
	weld --continue
}

## Git layer
git_head_ref_shortname() {
	echo $1 | sed s%refs/heads/%%
}

git_move_branch() {
	local branch="$1"
	local to="$2"

        git checkout --quiet ${branch}
        git reset --hard ${to}
}

git_kill_branch() {
	local branch="$1"

	git branch -D ${b} 2>/dev/null || true
}

git_ensure_clean_tree() {
	local force="$1"; shift

	if git status --porcelain 2>&1 | grep "^??" > /dev/null
	then
		if test -z "${force}"
		then
			error "FATAL: unstaged changes in working tree -- safe operation impossible."
			exit 1
		else
			echo "WARNING: unstaged changes in working tree -- but --force was passed to override safety check, continuing."
		fi
	fi
}

abort_restore_user_context() {
	local branch=$1; shift
	local backup=$1; shift
	local orig_head=$1; shift
	local diff_reapply_on_error=$1; shift

	git_move_branch ${branch} ${backup}
        git checkout --quiet $(git_head_ref_shortname ${orig_head})
	test -z "${diff_reapply_on_error}" || {
		git cherry-pick --no-commit ${diff_reapply_on_error}
		git_kill_branch ${diff_reapply_on_error}
	}
}

git_ensure_no_changes() {
	local branch=$1; shift
	local backup=$1; shift
	local orig_head=$1; shift
	local diff_reapply_on_error=$1; shift
	local yes=$1; shift

	local retval=0
	echo -n "; weld:  verifying:  "
	if git diff --exit-code ${backup} ${branch}
	then
		echo "OK -- zero diff between old and new versions of '${branch}'"
	else
		echo "DIFF -- difference between old and new versions of '${branch}' !"
		while true
		do
			echo "WARNING: non-zero diff between old and new versions of '${branch}'.  What to do:"
			echo -e "\n   [r]EVIEW / [a]CCEPT or [any-key] to ABORT:"
			echo -ne "\n  Your choice: "
			if test -z "${yes}"
			then read choice
			else choice=a
			fi
			case "${choice}" in
				r )
					echo "You chose REVIEW"
					git diff --exit-code ${backup} ${branch} | less;;
				a )
					echo "You chose ACCEPT"
					break;;
				* )
					echo "You chose ABORT"
					retval=1
					break;;
			esac
		done
		if test ${retval} = "1"
		then
			## Undo the successful rebase that was rejected by user:
			git reset --hard
			abort_restore_user_context ${branch} ${backup} ${orig_head} ${diff_reapply_on_error}
		fi
	fi
	return ${retval}
}
