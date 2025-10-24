# Documentation defined in Library/DinrusHub/cmd/--version.rb

# DRXHUB_CORE_REPOSITORY, DRXHUB_CASK_REPOSITORY, DRXHUB_VERSION are set by brew.sh
# shellcheck disable=SC2154
version_string() {
  local repo="$1"
  if ! [[ -d "${repo}" ]]
  then
    echo "N/A"
    return
  fi

  local pretty_revision
  pretty_revision="$(git -C "${repo}" rev-parse --short --verify --quiet HEAD)"
  if [[ -z "${pretty_revision}" ]]
  then
    echo "(no Git repository)"
    return
  fi

  local git_last_commit_date
  git_last_commit_date="$(git -C "${repo}" show -s --format='%cd' --date=short HEAD)"
  echo "(git revision ${pretty_revision}; last commit ${git_last_commit_date})"
}

homebrew-version() {
  echo "DinrusHub ${DRXHUB_VERSION}"

  if [[ -n "${DRXHUB_NO_INSTALL_FROM_API}" || -d "${DRXHUB_CORE_REPOSITORY}" ]]
  then
    echo "DinrusHub/homebrew-core $(version_string "${DRXHUB_CORE_REPOSITORY}")"
  fi

  if [[ -d "${DRXHUB_CASK_REPOSITORY}" ]]
  then
    echo "DinrusHub/homebrew-cask $(version_string "${DRXHUB_CASK_REPOSITORY}")"
  fi
}
