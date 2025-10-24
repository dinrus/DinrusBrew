# Documentation defined in Library/DinrusHub/cmd/formulae.rb

# DRXHUB_LIBRARY is set by bin/dhub
# shellcheck disable=SC2154
source "${DRXHUB_LIBRARY}/DinrusHub/items.sh"

homebrew-formulae() {
  local find_include_filter='*\.rb'
  local sed_filter='s|/Formula/(.+/)?|/|'
  local grep_filter='^homebrew/core'

  # DRXHUB_CACHE is set by brew.sh
  # shellcheck disable=SC2154
  if [[ -z "${DRXHUB_NO_INSTALL_FROM_API}" &&
        -f "${DRXHUB_CACHE}/api/formula_names.txt" ]]
  then
    {
      cat "${DRXHUB_CACHE}/api/formula_names.txt"
      echo
      homebrew-items "${find_include_filter}" '.*Casks(/.*|$)|.*/homebrew/homebrew-core/.*' "${sed_filter}" "${grep_filter}"
    } | sort -uf
  else
    homebrew-items "${find_include_filter}" '.*Casks(/.*|$)' "${sed_filter}" "${grep_filter}"
  fi
}
