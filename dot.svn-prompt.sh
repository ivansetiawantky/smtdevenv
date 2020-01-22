parse_svn_branch() {
    # parse_svn_url | sed -e 's#^'"$(parse_svn_repository_root)"'##g' | awk '{print "["$1"]" }'
    parse_svn_url | sed -e 's#^'"$(parse_svn_repository_root)"'##g' | egrep -o '(tags|branches)/[^/]+|trunk' | egrep -o '[^/]+$' | awk '{print $1}'
}

parse_svn_url() {
    LANG=C svn info 2>/dev/null | sed -ne 's#^URL: ##p'
}

parse_svn_repository_root() {
    LANG=C svn info 2>/dev/null | sed -ne 's#^Repository Root: ##p'
}

parse_svn_working_copy_root_path() {
    LANG=C svn info 2>/dev/null | sed -ne 's#^Working Copy Root Path: ##p'
}

parse_svn_rev() {
    LANG=C svn info 2> /dev/null | grep "Revision" | sed 's/Revision: \(.*\)/\1/'
}

__svn_prompt() {
    branch=$(parse_svn_branch)
    if [[ -z "$branch" ]] ; then
	return
    fi

    rev=$(parse_svn_rev)
    wkcproot=$(parse_svn_working_copy_root_path)
    # dirty=$(LANG=C svn status "$wkcproot" 2> /dev/null)
    dirty=$(LANG=C svn status 2> /dev/null)
    if [[ ! -z "$dirty" ]] ; then
	echo "[""$branch"",""$rev" "*""]"
    else
	echo "[""$branch"",""$rev""]"
    fi
}
