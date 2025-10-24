# Documentation defined in Library/DinrusHub/cmd/update.rb

# DRXHUB_API_DOMAIN, DRXHUB_CURLRC, DRXHUB_DEBUG, DRXHUB_DEVELOPER, DRXHUB_GIT_EMAIL, DRXHUB_GIT_NAME,
# DRXHUB_GITHUB_API_TOKEN, DRXHUB_NO_ENV_HINTS, DRXHUB_NO_INSTALL_CLEANUP, DRXHUB_NO_INSTALL_FROM_API,
# DRXHUB_UPDATE_TO_TAG are from the user environment
# DRXHUB_LIBRARY, DRXHUB_PREFIX, DRXHUB_REPOSITORY are set by bin/dhub
# DRXHUB_API_DEFAULT_DOMAIN, DRXHUB_AUTO_UPDATE_CASK_TAP, DRXHUB_AUTO_UPDATE_CORE_TAP,
# DRXHUB_AUTO_UPDATE_SECS, DRXHUB_BREW_DEFAULT_GIT_REMOTE, DRXHUB_BREW_GIT_REMOTE, DRXHUB_CACHE,
# DRXHUB_CASK_REPOSITORY, DRXHUB_CELLAR, DRXHUB_CORE_DEFAULT_GIT_REMOTE, DRXHUB_CORE_GIT_REMOTE,
# DRXHUB_CORE_REPOSITORY, DRXHUB_CURL, DRXHUB_DEV_CMD_RUN, DRXHUB_FORCE_BREWED_CA_CERTIFICATES,
# DRXHUB_FORCE_BREWED_CURL, DRXHUB_FORCE_BREWED_GIT, DRXHUB_LINUXBREW_CORE_MIGRATION,
# DRXHUB_SYSTEM_CURL_TOO_OLD, DRXHUB_USER_AGENT_CURL are set by brew.sh
# shellcheck disable=SC2154
source "${DRXHUB_LIBRARY}/DinrusHub/utils/lock.sh"

# Replaces the function in Library/DinrusHub/brew.sh to cache the Curl/Git executable to
# provide speedup when using Curl/Git repeatedly (as update.sh does).
curl() {
  if [[ -z "${CURL_EXECUTABLE}" ]]
  then
    CURL_EXECUTABLE="$("${DRXHUB_LIBRARY}/DinrusHub/shims/shared/curl" --homebrew=print-path)"
    if [[ -z "${CURL_EXECUTABLE}" ]]
    then
      odie "Can't find a working Curl!"
    fi
  fi
  "${CURL_EXECUTABLE}" "$@"
}

git() {
  if [[ -z "${GIT_EXECUTABLE}" ]]
  then
    GIT_EXECUTABLE="$("${DRXHUB_LIBRARY}/DinrusHub/shims/shared/git" --homebrew=print-path)"
    if [[ -z "${GIT_EXECUTABLE}" ]]
    then
      odie "Can't find a working Git!"
    fi
  fi
  "${GIT_EXECUTABLE}" "$@"
}

git_init_if_necessary() {
  safe_cd "${DRXHUB_REPOSITORY}"
  if [[ ! -d ".git" ]]
  then
    set -e
    trap '{ rm -rf .git; exit 1; }' EXIT
    git init
    git config --bool core.autocrlf false
    git config --bool core.symlinks true
    if [[ "${DRXHUB_BREW_DEFAULT_GIT_REMOTE}" != "${DRXHUB_BREW_GIT_REMOTE}" ]]
    then
      echo "DRXHUB_BREW_GIT_REMOTE set: using ${DRXHUB_BREW_GIT_REMOTE} as the Homebrew/brew Git remote."
    fi
    git config remote.origin.url "${DRXHUB_BREW_GIT_REMOTE}"
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git fetch --force --tags origin
    git remote set-head origin --auto >/dev/null
    git reset --hard origin/master
    SKIP_FETCH_BREW_REPOSITORY=1
    set +e
    trap - EXIT
  fi

  [[ -d "${DRXHUB_CORE_REPOSITORY}" ]] || return
  safe_cd "${DRXHUB_CORE_REPOSITORY}"
  if [[ ! -d ".git" ]]
  then
    set -e
    trap '{ rm -rf .git; exit 1; }' EXIT
    git init
    git config --bool core.autocrlf false
    git config --bool core.symlinks true
    if [[ "${DRXHUB_CORE_DEFAULT_GIT_REMOTE}" != "${DRXHUB_CORE_GIT_REMOTE}" ]]
    then
      echo "DRXHUB_CORE_GIT_REMOTE set: using ${DRXHUB_CORE_GIT_REMOTE} as the DinrusHub/homebrew-core Git remote."
    fi
    git config remote.origin.url "${DRXHUB_CORE_GIT_REMOTE}"
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git fetch --force origin refs/heads/master:refs/remotes/origin/master
    git remote set-head origin --auto >/dev/null
    git reset --hard origin/master
    SKIP_FETCH_CORE_REPOSITORY=1
    set +e
    trap - EXIT
  fi
}

repository_var_suffix() {
  local repository_directory="${1}"
  local repository_var_suffix

  if [[ "${repository_directory}" == "${DRXHUB_REPOSITORY}" ]]
  then
    repository_var_suffix=""
  else
    repository_var_suffix="${repository_directory#"${DRXHUB_LIBRARY}/Taps"}"
    repository_var_suffix="$(echo -n "${repository_var_suffix}" | tr -C "A-Za-z0-9" "_" | tr "[:lower:]" "[:upper:]")"
  fi
  echo "${repository_var_suffix}"
}

upstream_branch() {
  local upstream_branch

  upstream_branch="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)"
  if [[ -z "${upstream_branch}" ]]
  then
    git remote set-head origin --auto >/dev/null
    upstream_branch="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)"
  fi
  upstream_branch="${upstream_branch#refs/remotes/origin/}"
  [[ -z "${upstream_branch}" ]] && upstream_branch="master"
  echo "${upstream_branch}"
}

read_current_revision() {
  git rev-parse -q --verify HEAD
}

pop_stash() {
  [[ -z "${STASHED}" ]] && return
  if [[ -n "${DRXHUB_VERBOSE}" ]]
  then
    echo "Restoring your stashed changes to ${DIR}..."
    git stash pop
  else
    git stash pop "${QUIET_ARGS[@]}" 1>/dev/null
  fi
  unset STASHED
}

pop_stash_message() {
  [[ -z "${STASHED}" ]] && return
  echo "To restore the stashed changes to ${DIR}, run:"
  echo "  cd ${DIR} && git stash pop"
  unset STASHED
}

reset_on_interrupt() {
  if [[ "${INITIAL_BRANCH}" != "${UPSTREAM_BRANCH}" && -n "${INITIAL_BRANCH}" ]]
  then
    git checkout "${INITIAL_BRANCH}" "${QUIET_ARGS[@]}"
  fi

  if [[ -n "${INITIAL_REVISION}" ]]
  then
    git rebase --abort &>/dev/null
    git merge --abort &>/dev/null
    git reset --hard "${INITIAL_REVISION}" "${QUIET_ARGS[@]}"
  fi

  if [[ -n "${DRXHUB_NO_UPDATE_CLEANUP}" ]]
  then
    pop_stash
  else
    pop_stash_message
  fi

  exit 130
}

# Used for testing purposes, e.g. for testing formula migration after
# renaming it in the currently checked-out branch. To test run
# "dhub update --simulate-from-current-branch"
simulate_from_current_branch() {
  local DIR
  local TAP_VAR
  local UPSTREAM_BRANCH
  local CURRENT_REVISION

  DIR="$1"
  cd "${DIR}" || return
  TAP_VAR="$2"
  UPSTREAM_BRANCH="$3"
  CURRENT_REVISION="$4"

  INITIAL_REVISION="$(git rev-parse -q --verify "${UPSTREAM_BRANCH}")"
  export DRXHUB_UPDATE_BEFORE"${TAP_VAR}"="${INITIAL_REVISION}"
  export DRXHUB_UPDATE_AFTER"${TAP_VAR}"="${CURRENT_REVISION}"
  if [[ "${INITIAL_REVISION}" != "${CURRENT_REVISION}" ]]
  then
    DRXHUB_UPDATED="1"
  fi
  if ! git merge-base --is-ancestor "${INITIAL_REVISION}" "${CURRENT_REVISION}"
  then
    odie "Your ${DIR} HEAD is not a descendant of ${UPSTREAM_BRANCH}!"
  fi
}

merge_or_rebase() {
  if [[ -n "${DRXHUB_VERBOSE}" ]]
  then
    echo "Updating ${DIR}..."
  fi

  local DIR
  local TAP_VAR
  local UPSTREAM_BRANCH

  DIR="$1"
  cd "${DIR}" || return
  TAP_VAR="$2"
  UPSTREAM_BRANCH="$3"
  unset STASHED

  trap reset_on_interrupt SIGINT

  if [[ "${DIR}" == "${DRXHUB_REPOSITORY}" && -n "${DRXHUB_UPDATE_TO_TAG}" ]]
  then
    UPSTREAM_TAG="$(
      git tag --list |
        sort --field-separator=. --key=1,1nr -k 2,2nr -k 3,3nr |
        grep --max-count=1 '^[0-9]*\.[0-9]*\.[0-9]*$'
    )"
  else
    UPSTREAM_TAG=""
  fi

  if [[ -n "${UPSTREAM_TAG}" ]]
  then
    REMOTE_REF="refs/tags/${UPSTREAM_TAG}"
    UPSTREAM_BRANCH="stable"
  else
    REMOTE_REF="origin/${UPSTREAM_BRANCH}"
  fi

  if [[ -n "$(git status --untracked-files=all --porcelain 2>/dev/null)" ]]
  then
    if [[ -n "${DRXHUB_VERBOSE}" ]]
    then
      echo "Stashing uncommitted changes to ${DIR}..."
    fi
    git merge --abort &>/dev/null
    git rebase --abort &>/dev/null
    git reset --mixed "${QUIET_ARGS[@]}"
    if ! git -c "user.email=brew-update@localhost" \
       -c "user.name=dhub update" \
       stash save --include-untracked "${QUIET_ARGS[@]}"
    then
      odie <<EOS
Could not 'git stash' in ${DIR}!
Please stash/commit manually if you need to keep your changes or, if not, run:
  cd ${DIR}
  git reset --hard origin/master
EOS
    fi
    git reset --hard "${QUIET_ARGS[@]}"
    STASHED="1"
  fi

  INITIAL_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null)"
  if [[ -n "${UPSTREAM_TAG}" ]] ||
     [[ "${INITIAL_BRANCH}" != "${UPSTREAM_BRANCH}" && -n "${INITIAL_BRANCH}" ]]
  then
    # Recreate and check out `#{upstream_branch}` if unable to fast-forward
    # it to `origin/#{@upstream_branch}`. Otherwise, just check it out.
    if [[ -z "${UPSTREAM_TAG}" ]] &&
       git merge-base --is-ancestor "${UPSTREAM_BRANCH}" "${REMOTE_REF}" &>/dev/null
    then
      git checkout --force "${UPSTREAM_BRANCH}" "${QUIET_ARGS[@]}"
    else
      if [[ -n "${UPSTREAM_TAG}" && "${UPSTREAM_BRANCH}" != "master" ]] &&
         [[ "${INITIAL_BRANCH}" != "master" ]]
      then
        git branch --force "master" "origin/master" "${QUIET_ARGS[@]}"
      fi

      git checkout --force -B "${UPSTREAM_BRANCH}" "${REMOTE_REF}" "${QUIET_ARGS[@]}"
    fi
  fi

  INITIAL_REVISION="$(read_current_revision)"
  export DRXHUB_UPDATE_BEFORE"${TAP_VAR}"="${INITIAL_REVISION}"

  # ensure we don't munge line endings on checkout
  git config --bool core.autocrlf false

  # make sure symlinks are saved as-is
  git config --bool core.symlinks true

  if [[ "${DIR}" == "${DRXHUB_CORE_REPOSITORY}" && -n "${DRXHUB_LINUXBREW_CORE_MIGRATION}" ]]
  then
    # Don't even try to rebase/merge on linuxbrew-core migration but rely on
    # stashing etc. above.
    git reset --hard "${QUIET_ARGS[@]}" "${REMOTE_REF}"
    unset DRXHUB_LINUXBREW_CORE_MIGRATION
  elif [[ -z "${DRXHUB_MERGE}" ]]
  then
    # Work around bug where git rebase --quiet is not quiet
    if [[ -z "${DRXHUB_VERBOSE}" ]]
    then
      git rebase "${QUIET_ARGS[@]}" "${REMOTE_REF}" >/dev/null
    else
      git rebase "${QUIET_ARGS[@]}" "${REMOTE_REF}"
    fi
  else
    git merge --no-edit --ff "${QUIET_ARGS[@]}" "${REMOTE_REF}" \
      --strategy=recursive \
      --strategy-option=ours \
      --strategy-option=ignore-all-space
  fi

  CURRENT_REVISION="$(read_current_revision)"
  export DRXHUB_UPDATE_AFTER"${TAP_VAR}"="${CURRENT_REVISION}"

  if [[ "${INITIAL_REVISION}" != "${CURRENT_REVISION}" ]]
  then
    DRXHUB_UPDATED="1"
  fi

  trap '' SIGINT

  if [[ -n "${DRXHUB_NO_UPDATE_CLEANUP}" ]]
  then
    if [[ "${INITIAL_BRANCH}" != "${UPSTREAM_BRANCH}" && -n "${INITIAL_BRANCH}" ]] &&
       [[ ! "${INITIAL_BRANCH}" =~ ^v[0-9]+\.[0-9]+\.[0-9]|stable$ ]]
    then
      git checkout "${INITIAL_BRANCH}" "${QUIET_ARGS[@]}"
    fi

    pop_stash
  else
    pop_stash_message
  fi

  trap - SIGINT
}

homebrew-update() {
  local option
  local DIR
  local UPSTREAM_BRANCH

  for option in "$@"
  do
    case "${option}" in
      -\? | -h | --help | --usage)
        dhub help update
        exit $?
        ;;
      --verbose) DRXHUB_VERBOSE=1 ;;
      --debug) DRXHUB_DEBUG=1 ;;
      --quiet) DRXHUB_QUIET=1 ;;
      --merge)
        shift
        DRXHUB_MERGE=1
        ;;
      --force) DRXHUB_UPDATE_FORCE=1 ;;
      --simulate-from-current-branch)
        shift
        DRXHUB_SIMULATE_FROM_CURRENT_BRANCH=1
        ;;
      --auto-update) export DRXHUB_UPDATE_AUTO=1 ;;
      --*)
        onoe "Unknown option: ${option}"
        dhub help update
        exit 1
        ;;
      -*)
        [[ "${option}" == *v* ]] && DRXHUB_VERBOSE=1
        [[ "${option}" == *q* ]] && DRXHUB_QUIET=1
        [[ "${option}" == *d* ]] && DRXHUB_DEBUG=1
        [[ "${option}" == *f* ]] && DRXHUB_UPDATE_FORCE=1
        ;;
      *)
        odie <<EOS
This command updates dhub itself, and does not take formula names.
Use \`dhub upgrade $@\` instead.
EOS
        ;;
    esac
  done

  if [[ -n "${DRXHUB_DEBUG}" ]]
  then
    set -x
  fi

  if [[ -z "${DRXHUB_UPDATE_TO_TAG}" ]]
  then
    if [[ -n "${DRXHUB_DEVELOPER}" || -n "${DRXHUB_DEV_CMD_RUN}" ]]
    then
      export DRXHUB_NO_UPDATE_CLEANUP="1"
    else
      export DRXHUB_UPDATE_TO_TAG="1"
    fi
  fi

  # check permissions
  if [[ -e "${DRXHUB_CELLAR}" && ! -w "${DRXHUB_CELLAR}" ]]
  then
    odie <<EOS
${DRXHUB_CELLAR} is not writable. You should change the
ownership and permissions of ${DRXHUB_CELLAR} back to your
user account:
  sudo chown -R ${USER-\$(whoami)} ${DRXHUB_CELLAR}
EOS
  fi

  if [[ -d "${DRXHUB_CORE_REPOSITORY}" ]] ||
     [[ -z "${DRXHUB_NO_INSTALL_FROM_API}" ]]
  then
    DRXHUB_CORE_AVAILABLE="1"
  fi

  if [[ ! -w "${DRXHUB_REPOSITORY}" ]]
  then
    odie <<EOS
${DRXHUB_REPOSITORY} is not writable. You should change the
ownership and permissions of ${DRXHUB_REPOSITORY} back to your
user account:
  sudo chown -R ${USER-\$(whoami)} ${DRXHUB_REPOSITORY}
EOS
  fi

  # we may want to use DinrusHub CA certificates
  if [[ -n "${DRXHUB_FORCE_BREWED_CA_CERTIFICATES}" && ! -f "${DRXHUB_PREFIX}/etc/ca-certificates/cert.pem" ]]
  then
    # we cannot install DinrusHub CA certificates if homebrew/core is unavailable.
    if [[ -n "${DRXHUB_CORE_AVAILABLE}" ]]
    then
      dhub install ca-certificates
      setup_ca_certificates
    fi
  fi

  # we may want to use a DinrusHub curl
  if [[ -n "${DRXHUB_FORCE_BREWED_CURL}" && ! -x "${DRXHUB_PREFIX}/opt/curl/bin/curl" ]]
  then
    # we cannot install a DinrusHub cURL if homebrew/core is unavailable.
    if [[ -z "${DRXHUB_CORE_AVAILABLE}" ]] || ! dhub install curl
    then
      odie "'curl' must be installed and in your PATH!"
    fi

    setup_curl
  fi

  if ! git --version &>/dev/null ||
     [[ -n "${DRXHUB_FORCE_BREWED_GIT}" && ! -x "${DRXHUB_PREFIX}/opt/git/bin/git" ]]
  then
    # we cannot install a DinrusHub Git if homebrew/core is unavailable.
    if [[ -z "${DRXHUB_CORE_AVAILABLE}" ]] || ! dhub install git
    then
      odie "'git' must be installed and in your PATH!"
    fi

    setup_git
  fi

  [[ -f "${DRXHUB_CORE_REPOSITORY}/.git/shallow" ]] && DRXHUB_CORE_SHALLOW=1
  [[ -f "${DRXHUB_CASK_REPOSITORY}/.git/shallow" ]] && DRXHUB_CASK_SHALLOW=1
  if [[ -n "${DRXHUB_CORE_SHALLOW}" && -n "${DRXHUB_CASK_SHALLOW}" ]]
  then
    SHALLOW_COMMAND_PHRASE="These commands"
    SHALLOW_REPO_PHRASE="repositories"
  else
    SHALLOW_COMMAND_PHRASE="This command"
    SHALLOW_REPO_PHRASE="repository"
  fi

  if [[ -n "${DRXHUB_CORE_SHALLOW}" || -n "${DRXHUB_CASK_SHALLOW}" ]]
  then
    odie <<EOS
${DRXHUB_CORE_SHALLOW:+
  homebrew-core is a shallow clone.}${DRXHUB_CASK_SHALLOW:+
  homebrew-cask is a shallow clone.}
To \`dhub update\`, first run:${DRXHUB_CORE_SHALLOW:+
  git -C "${DRXHUB_CORE_REPOSITORY}" fetch --unshallow}${DRXHUB_CASK_SHALLOW:+
  git -C "${DRXHUB_CASK_REPOSITORY}" fetch --unshallow}
${SHALLOW_COMMAND_PHRASE} may take a few minutes to run due to the large size of the ${SHALLOW_REPO_PHRASE}.
This restriction has been made on GitHub's request because updating shallow
clones is an extremely expensive operation due to the tree layout and traffic of
DinrusHub/homebrew-core and DinrusHub/homebrew-cask. We don't do this for you
automatically to avoid repeatedly performing an expensive unshallow operation in
CI systems (which should instead be fixed to not use shallow clones). Sorry for
the inconvenience!
EOS
  fi

  export GIT_TERMINAL_PROMPT="0"
  export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -oBatchMode=yes"

  if [[ -n "${DRXHUB_GIT_NAME}" ]]
  then
    export GIT_AUTHOR_NAME="${DRXHUB_GIT_NAME}"
    export GIT_COMMITTER_NAME="${DRXHUB_GIT_NAME}"
  fi

  if [[ -n "${DRXHUB_GIT_EMAIL}" ]]
  then
    export GIT_AUTHOR_EMAIL="${DRXHUB_GIT_EMAIL}"
    export GIT_COMMITTER_EMAIL="${DRXHUB_GIT_EMAIL}"
  fi

  if [[ -z "${DRXHUB_VERBOSE}" ]]
  then
    export GIT_ADVICE="false"
    QUIET_ARGS=(-q)
  else
    QUIET_ARGS=()
  fi

  # DRXHUB_CURLRC is optionally defined in the user environment.
  # shellcheck disable=SC2153
  if [[ -z "${DRXHUB_CURLRC}" ]]
  then
    CURL_DISABLE_CURLRC_ARGS=(-q)
  else
    CURL_DISABLE_CURLRC_ARGS=()
  fi

  # only allow one instance of dhub update
  lock update

  git_init_if_necessary

  if [[ "${DRXHUB_BREW_DEFAULT_GIT_REMOTE}" != "${DRXHUB_BREW_GIT_REMOTE}" ]]
  then
    safe_cd "${DRXHUB_REPOSITORY}"
    echo "DRXHUB_BREW_GIT_REMOTE set: using ${DRXHUB_BREW_GIT_REMOTE} as the Homebrew/brew Git remote."
    git remote set-url origin "${DRXHUB_BREW_GIT_REMOTE}"
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git fetch --force --tags origin
    SKIP_FETCH_BREW_REPOSITORY=1
  fi

  if [[ -d "${DRXHUB_CORE_REPOSITORY}" ]] &&
     [[ "${DRXHUB_CORE_DEFAULT_GIT_REMOTE}" != "${DRXHUB_CORE_GIT_REMOTE}" ||
        -n "${DRXHUB_LINUXBREW_CORE_MIGRATION}" ]]
  then
    if [[ -n "${DRXHUB_LINUXBREW_CORE_MIGRATION}" ]]
    then
      # This means a migration is needed (in case it isn't run this time)
      safe_cd "${DRXHUB_REPOSITORY}"
      git config --bool homebrew.linuxbrewmigrated false
    fi

    safe_cd "${DRXHUB_CORE_REPOSITORY}"
    echo "DRXHUB_CORE_GIT_REMOTE set: using ${DRXHUB_CORE_GIT_REMOTE} as the DinrusHub/homebrew-core Git remote."
    git remote set-url origin "${DRXHUB_CORE_GIT_REMOTE}"
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git fetch --force origin refs/heads/master:refs/remotes/origin/master
    SKIP_FETCH_CORE_REPOSITORY=1
  fi

  safe_cd "${DRXHUB_REPOSITORY}"

  # This means a migration is needed but hasn't completed (yet).
  if [[ "$(git config homebrew.linuxbrewmigrated 2>/dev/null)" == "false" ]]
  then
    export DRXHUB_MIGRATE_LINUXBREW_FORMULAE=1
  fi

  # if an older system had a newer curl installed, change each repo's remote URL from git to https
  if [[ -n "${DRXHUB_SYSTEM_CURL_TOO_OLD}" && -x "${DRXHUB_PREFIX}/opt/curl/bin/curl" ]] &&
     [[ "$(git config remote.origin.url)" =~ ^git:// ]]
  then
    git config remote.origin.url "${DRXHUB_BREW_GIT_REMOTE}"
    git config -f "${DRXHUB_CORE_REPOSITORY}/.git/config" remote.origin.url "${DRXHUB_CORE_GIT_REMOTE}"
  fi

  # kill all of subprocess on interrupt
  trap '{ /usr/bin/pkill -P $$; wait; exit 130; }' SIGINT

  local update_failed_file="${DRXHUB_REPOSITORY}/.git/UPDATE_FAILED"
  local missing_remote_ref_dirs_file="${DRXHUB_REPOSITORY}/.git/FAILED_FETCH_DIRS"
  rm -f "${update_failed_file}"
  rm -f "${missing_remote_ref_dirs_file}"

  for DIR in "${DRXHUB_REPOSITORY}" "${DRXHUB_LIBRARY}"/Taps/*/*
  do
    if [[ -z "${DRXHUB_NO_INSTALL_FROM_API}" ]] &&
       [[ -n "${DRXHUB_UPDATE_AUTO}" || (-z "${DRXHUB_DEVELOPER}" && -z "${DRXHUB_DEV_CMD_RUN}") ]] &&
       [[ -n "${DRXHUB_UPDATE_AUTO}" &&
          (("${DIR}" == "${DRXHUB_CORE_REPOSITORY}" && -z "${DRXHUB_AUTO_UPDATE_CORE_TAP}") ||
          ("${DIR}" == "${DRXHUB_CASK_REPOSITORY}" && -z "${DRXHUB_AUTO_UPDATE_CASK_TAP}")) ]]
    then
      continue
    fi

    [[ -d "${DIR}/.git" ]] || continue
    cd "${DIR}" || continue

    if [[ "${DIR}" = "${DRXHUB_REPOSITORY}" && "${DRXHUB_REPOSITORY}" = "${DRXHUB_PREFIX}" ]]
    then
      # Git's fsmonitor prevents the release of our locks
      git config --bool core.fsmonitor false
    fi

    if ! git config --local --get remote.origin.url &>/dev/null
    then
      opoo "No remote 'origin' in ${DIR}, skipping update!"
      continue
    fi

    if [[ -n "${DRXHUB_VERBOSE}" ]]
    then
      echo "Checking if we need to fetch ${DIR}..."
    fi

    TAP_VAR="$(repository_var_suffix "${DIR}")"
    UPSTREAM_BRANCH_DIR="$(upstream_branch)"
    declare UPSTREAM_BRANCH"${TAP_VAR}"="${UPSTREAM_BRANCH_DIR}"
    declare PREFETCH_REVISION"${TAP_VAR}"="$(git rev-parse -q --verify refs/remotes/origin/"${UPSTREAM_BRANCH_DIR}")"

    if [[ -n "${GITHUB_ACTIONS}" && -n "${DRXHUB_UPDATE_SKIP_BREW}" && "${DIR}" == "${DRXHUB_REPOSITORY}" ]]
    then
      continue
    fi

    # Force a full update if we don't have any tags.
    if [[ "${DIR}" == "${DRXHUB_REPOSITORY}" && -z "$(git tag --list)" ]]
    then
      DRXHUB_UPDATE_FORCE=1
    fi

    if [[ -z "${DRXHUB_UPDATE_FORCE}" ]]
    then
      [[ -n "${SKIP_FETCH_BREW_REPOSITORY}" && "${DIR}" == "${DRXHUB_REPOSITORY}" ]] && continue
      [[ -n "${SKIP_FETCH_CORE_REPOSITORY}" && "${DIR}" == "${DRXHUB_CORE_REPOSITORY}" ]] && continue
    fi

    if [[ -z "${UPDATING_MESSAGE_SHOWN}" ]]
    then
      if [[ -n "${DRXHUB_UPDATE_AUTO}" ]]
      then
        # Outputting a command but don't want to run it, hence single quotes.
        # shellcheck disable=SC2016
        ohai 'Auto-updating DinrusHub...' >&2
        if [[ -z "${DRXHUB_NO_ENV_HINTS}" && -z "${DRXHUB_AUTO_UPDATE_SECS}" ]]
        then
          # shellcheck disable=SC2016
          echo 'Adjust how often this is run with DRXHUB_AUTO_UPDATE_SECS or disable with' >&2
          # shellcheck disable=SC2016
          echo 'DRXHUB_NO_AUTO_UPDATE. Hide these hints with DRXHUB_NO_ENV_HINTS (see `man dhub`).' >&2
        fi
      else
        ohai 'Updating DinrusHub...' >&2
      fi
      UPDATING_MESSAGE_SHOWN=1
    fi

    # The upstream repository's default branch may not be master;
    # check refs/remotes/origin/HEAD to see what the default
    # origin branch name is, and use that. If not set, fall back to "master".
    # the refspec ensures that the default upstream branch gets updated
    (
      UPSTREAM_REPOSITORY_URL="$(git config remote.origin.url)"
      unset UPSTREAM_REPOSITORY
      unset UPSTREAM_REPOSITORY_TOKEN

      # DRXHUB_UPDATE_FORCE and DRXHUB_UPDATE_AUTO aren't modified here so ignore subshell warning.
      # shellcheck disable=SC2030
      if [[ "${UPSTREAM_REPOSITORY_URL}" == "https://github.com/"* ]]
      then
        UPSTREAM_REPOSITORY="${UPSTREAM_REPOSITORY_URL#https://github.com/}"
        UPSTREAM_REPOSITORY="${UPSTREAM_REPOSITORY%.git}"
      elif [[ "${DIR}" != "${DRXHUB_REPOSITORY}" ]] &&
           [[ "${UPSTREAM_REPOSITORY_URL}" =~ https://([[:alnum:]_:]+)@github.com/(.*)$ ]]
      then
        UPSTREAM_REPOSITORY="${BASH_REMATCH[2]%.git}"
        UPSTREAM_REPOSITORY_TOKEN="${BASH_REMATCH[1]#*:}"
      fi

      if [[ -n "${UPSTREAM_REPOSITORY}" ]]
      then
        # UPSTREAM_REPOSITORY_TOKEN is parsed (if exists) from UPSTREAM_REPOSITORY_URL
        # DRXHUB_GITHUB_API_TOKEN is optionally defined in the user environment.
        # shellcheck disable=SC2153
        if [[ -n "${UPSTREAM_REPOSITORY_TOKEN}" ]]
        then
          CURL_GITHUB_API_ARGS=("--header" "Authorization: token ${UPSTREAM_REPOSITORY_TOKEN}")
        elif [[ -n "${DRXHUB_GITHUB_API_TOKEN}" ]]
        then
          CURL_GITHUB_API_ARGS=("--header" "Authorization: token ${DRXHUB_GITHUB_API_TOKEN}")
        else
          CURL_GITHUB_API_ARGS=()
        fi

        if [[ "${DIR}" == "${DRXHUB_REPOSITORY}" && -n "${DRXHUB_UPDATE_TO_TAG}" ]]
        then
          # Only try to `git fetch` when the upstream tags have changed
          # (so the API does not return 304: unmodified).
          GITHUB_API_ETAG="$(sed -n 's/^ETag: "\([a-f0-9]\{32\}\)".*/\1/p' ".git/GITHUB_HEADERS" 2>/dev/null)"
          GITHUB_API_ACCEPT="application/vnd.github+json"
          GITHUB_API_ENDPOINT="tags"
        else
          # Only try to `git fetch` when the upstream branch is at a different SHA
          # (so the API does not return 304: unmodified).
          GITHUB_API_ETAG="$(git rev-parse "refs/remotes/origin/${UPSTREAM_BRANCH_DIR}")"
          GITHUB_API_ACCEPT="application/vnd.github.sha"
          GITHUB_API_ENDPOINT="commits/${UPSTREAM_BRANCH_DIR}"
        fi

        # DRXHUB_CURL is set by brew.sh (and isn't misspelt here)
        # shellcheck disable=SC2153
        UPSTREAM_SHA_HTTP_CODE="$(
          curl \
            "${CURL_DISABLE_CURLRC_ARGS[@]}" \
            "${CURL_GITHUB_API_ARGS[@]}" \
            --silent --max-time 3 \
            --location --no-remote-time --output /dev/null --write-out "%{http_code}" \
            --dump-header "${DIR}/.git/GITHUB_HEADERS" \
            --user-agent "${DRXHUB_USER_AGENT_CURL}" \
            --header "X-GitHub-Api-Version:2022-11-28" \
            --header "Accept: ${GITHUB_API_ACCEPT}" \
            --header "If-None-Match: \"${GITHUB_API_ETAG}\"" \
            "https://api.github.com/repos/${UPSTREAM_REPOSITORY}/${GITHUB_API_ENDPOINT}"
        )"

        # Touch FETCH_HEAD to confirm we've checked for an update.
        [[ -f "${DIR}/.git/FETCH_HEAD" ]] && touch "${DIR}/.git/FETCH_HEAD"
        [[ -z "${DRXHUB_UPDATE_FORCE}" ]] && [[ "${UPSTREAM_SHA_HTTP_CODE}" == "304" ]] && exit
      fi

      # DRXHUB_VERBOSE isn't modified here so ignore subshell warning.
      # shellcheck disable=SC2030
      if [[ -n "${DRXHUB_VERBOSE}" ]]
      then
        echo "Fetching ${DIR}..."
      fi

      local tmp_failure_file="${DIR}/.git/TMP_FETCH_FAILURES"
      rm -f "${tmp_failure_file}"

      if [[ -n "${DRXHUB_UPDATE_AUTO}" ]]
      then
        git fetch --tags --force "${QUIET_ARGS[@]}" origin \
          "refs/heads/${UPSTREAM_BRANCH_DIR}:refs/remotes/origin/${UPSTREAM_BRANCH_DIR}" 2>/dev/null
      else
        # Capture stderr to tmp_failure_file
        if ! git fetch --tags --force "${QUIET_ARGS[@]}" origin \
           "refs/heads/${UPSTREAM_BRANCH_DIR}:refs/remotes/origin/${UPSTREAM_BRANCH_DIR}" 2>>"${tmp_failure_file}"
        then
          # Reprint fetch errors to stderr
          [[ -f "${tmp_failure_file}" ]] && cat "${tmp_failure_file}" 1>&2

          if [[ "${UPSTREAM_SHA_HTTP_CODE}" == "404" ]]
          then
            TAP="${DIR#"${DRXHUB_LIBRARY}"/Taps/}"
            echo "${TAP} does not exist! Run \`dhub untap ${TAP}\` to remove it." >>"${update_failed_file}"
          else
            echo "Fetching ${DIR} failed!" >>"${update_failed_file}"

            if [[ -f "${tmp_failure_file}" ]] &&
               [[ "$(cat "${tmp_failure_file}")" == "fatal: couldn't find remote ref refs/heads/${UPSTREAM_BRANCH_DIR}" ]]
            then
              echo "${DIR}" >>"${missing_remote_ref_dirs_file}"
            fi
          fi
        fi
      fi

      rm -f "${tmp_failure_file}"
    ) &
  done

  wait
  trap - SIGINT

  if [[ -f "${missing_remote_ref_dirs_file}" ]]
  then
    DRXHUB_MISSING_REMOTE_REF_DIRS="$(cat "${missing_remote_ref_dirs_file}")"
    rm -f "${missing_remote_ref_dirs_file}"
    export DRXHUB_MISSING_REMOTE_REF_DIRS
  fi

  for DIR in "${DRXHUB_REPOSITORY}" "${DRXHUB_LIBRARY}"/Taps/*/*
  do
    if [[ -z "${DRXHUB_NO_INSTALL_FROM_API}" ]] &&
       [[ -n "${DRXHUB_UPDATE_AUTO}" || (-z "${DRXHUB_DEVELOPER}" && -z "${DRXHUB_DEV_CMD_RUN}") ]] &&
       [[ -n "${DRXHUB_UPDATE_AUTO}" &&
          (("${DIR}" == "${DRXHUB_CORE_REPOSITORY}" && -z "${DRXHUB_AUTO_UPDATE_CORE_TAP}") ||
          ("${DIR}" == "${DRXHUB_CASK_REPOSITORY}" && -z "${DRXHUB_AUTO_UPDATE_CASK_TAP}")) ]]
    then
      continue
    fi

    [[ -d "${DIR}/.git" ]] || continue
    cd "${DIR}" || continue
    if ! git config --local --get remote.origin.url &>/dev/null
    then
      # No need to display a (duplicate) warning here
      continue
    fi

    TAP_VAR="$(repository_var_suffix "${DIR}")"
    UPSTREAM_BRANCH_VAR="UPSTREAM_BRANCH${TAP_VAR}"
    UPSTREAM_BRANCH="${!UPSTREAM_BRANCH_VAR}"
    CURRENT_REVISION="$(read_current_revision)"

    PREFETCH_REVISION_VAR="PREFETCH_REVISION${TAP_VAR}"
    PREFETCH_REVISION="${!PREFETCH_REVISION_VAR}"
    POSTFETCH_REVISION="$(git rev-parse -q --verify refs/remotes/origin/"${UPSTREAM_BRANCH}")"

    # DRXHUB_UPDATE_FORCE and DRXHUB_VERBOSE weren't modified in subshell.
    # shellcheck disable=SC2031
    if [[ -n "${DRXHUB_SIMULATE_FROM_CURRENT_BRANCH}" ]]
    then
      simulate_from_current_branch "${DIR}" "${TAP_VAR}" "${UPSTREAM_BRANCH}" "${CURRENT_REVISION}"
    elif [[ -z "${DRXHUB_UPDATE_FORCE}" &&
            "${PREFETCH_REVISION}" == "${POSTFETCH_REVISION}" &&
            "${CURRENT_REVISION}" == "${POSTFETCH_REVISION}" ]] ||
         [[ -n "${GITHUB_ACTIONS}" && -n "${DRXHUB_UPDATE_SKIP_BREW}" && "${DIR}" == "${DRXHUB_REPOSITORY}" ]]
    then
      export DRXHUB_UPDATE_BEFORE"${TAP_VAR}"="${CURRENT_REVISION}"
      export DRXHUB_UPDATE_AFTER"${TAP_VAR}"="${CURRENT_REVISION}"
    else
      merge_or_rebase "${DIR}" "${TAP_VAR}" "${UPSTREAM_BRANCH}"
    fi
  done

  if [[ -z "${DRXHUB_NO_INSTALL_FROM_API}" ]]
  then
    local api_cache="${DRXHUB_CACHE}/api"
    mkdir -p "${api_cache}"

    for json in formula cask formula_tap_migrations cask_tap_migrations
    do
      local filename="${json}.jws.json"
      local cache_path="${api_cache}/${filename}"
      if [[ -f "${cache_path}" ]]
      then
        INITIAL_JSON_BYTESIZE="$(wc -c "${cache_path}")"
      fi

      if [[ -n "${DRXHUB_VERBOSE}" ]]
      then
        echo "Checking if we need to fetch ${filename}..."
      fi

      JSON_URLS=()
      if [[ -n "${DRXHUB_API_DOMAIN}" && "${DRXHUB_API_DOMAIN}" != "${DRXHUB_API_DEFAULT_DOMAIN}" ]]
      then
        JSON_URLS=("${DRXHUB_API_DOMAIN}/${filename}")
      fi

      JSON_URLS+=("${DRXHUB_API_DEFAULT_DOMAIN}/${filename}")
      for json_url in "${JSON_URLS[@]}"
      do
        time_cond=()
        if [[ -s "${cache_path}" ]]
        then
          time_cond=("--time-cond" "${cache_path}")
        fi
        curl \
          "${CURL_DISABLE_CURLRC_ARGS[@]}" \
          --fail --compressed --silent \
          --speed-limit "${DRXHUB_CURL_SPEED_LIMIT}" --speed-time "${DRXHUB_CURL_SPEED_TIME}" \
          --location --remote-time --output "${cache_path}" \
          "${time_cond[@]}" \
          --user-agent "${DRXHUB_USER_AGENT_CURL}" \
          "${json_url}"
        curl_exit_code=$?
        [[ ${curl_exit_code} -eq 0 ]] && break
      done

      if [[ "${json}" == "formula" ]] && [[ -f "${api_cache}/formula_names.txt" ]]
      then
        mv -f "${api_cache}/formula_names.txt" "${api_cache}/formula_names.before.txt"
      elif [[ "${json}" == "cask" ]] && [[ -f "${api_cache}/cask_names.txt" ]]
      then
        mv -f "${api_cache}/cask_names.txt" "${api_cache}/cask_names.before.txt"
      fi

      if [[ ${curl_exit_code} -eq 0 ]]
      then
        touch "${cache_path}"

        CURRENT_JSON_BYTESIZE="$(wc -c "${cache_path}")"
        if [[ "${INITIAL_JSON_BYTESIZE}" != "${CURRENT_JSON_BYTESIZE}" ]]
        then

          if [[ "${json}" == "formula" ]]
          then
            rm -f "${api_cache}/formula_aliases.txt"
          fi
          DRXHUB_UPDATED="1"

          if [[ -n "${DRXHUB_VERBOSE}" ]]
          then
            echo "Updated ${filename}."
          fi
        fi
      else
        echo "Failed to download ${json_url}!" >>"${update_failed_file}"
      fi

    done

    # Not a typo, these are the files we used to download that no longer need so should cleanup.
    rm -f "${DRXHUB_CACHE}/api/formula.json" "${DRXHUB_CACHE}/api/cask.json"
  else
    if [[ -n "${DRXHUB_VERBOSE}" ]]
    then
      echo "DRXHUB_NO_INSTALL_FROM_API set: skipping API JSON downloads."
    fi
  fi

  if [[ -f "${update_failed_file}" ]]
  then
    onoe <"${update_failed_file}"
    rm -f "${update_failed_file}"
    export DRXHUB_UPDATE_FAILED="1"
  fi

  safe_cd "${DRXHUB_REPOSITORY}"

  # DRXHUB_UPDATE_AUTO wasn't modified in subshell.
  # shellcheck disable=SC2031
  if [[ -n "${DRXHUB_UPDATED}" ]] ||
     [[ -n "${DRXHUB_UPDATE_FAILED}" ]] ||
     [[ -n "${DRXHUB_MISSING_REMOTE_REF_DIRS}" ]] ||
     [[ -n "${DRXHUB_UPDATE_FORCE}" ]] ||
     [[ -n "${DRXHUB_MIGRATE_LINUXBREW_FORMULAE}" ]] ||
     [[ -d "${DRXHUB_LIBRARY}/LinkedKegs" ]] ||
     [[ ! -f "${DRXHUB_CACHE}/all_commands_list.txt" ]] ||
     [[ -n "${DRXHUB_DEVELOPER}" && -z "${DRXHUB_UPDATE_AUTO}" ]]
  then
    dhub update-report "$@"
    return $?
  elif [[ -z "${DRXHUB_UPDATE_AUTO}" && -z "${DRXHUB_QUIET}" ]]
  then
    echo "Already up-to-date."
  fi
}
