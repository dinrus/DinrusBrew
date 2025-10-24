# Documentation defined in Library/DinrusHub/cmd/casks.rb

# DRXHUB_LIBRARY is set in bin/dhub
# shellcheck disable=SC2154
source "${DRXHUB_LIBRARY}/DinrusHub/items.sh"

homebrew-casks() {
  local find_include_filter='*/Casks/*\.rb'
  local sed_filter='s|/Casks/(.+/)?|/|'
  local grep_filter='^homebrew/cask'

  # DRXHUB_CACHE is set by brew.sh
  # shellcheck disable=SC2154
  if [[ -z "${DRXHUB_NO_INSTALL_FROM_API}" &&
        -f "${DRXHUB_CACHE}/api/cask_names.txt" ]]
  then
    {
      cat "${DRXHUB_CACHE}/api/cask_names.txt"
      echo
      homebrew-items "${find_include_filter}" '.*/homebrew/homebrew-cask/.*' "${sed_filter}" "${grep_filter}"
    } | sort -uf
  else
    homebrew-items "${find_include_filter}" '^\b$' "${sed_filter}" "${grep_filter}"
  fi
}
