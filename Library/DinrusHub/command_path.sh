# does the quickest output of dhub command possible for the basic cases of an
# official Bash or Ruby normal or dev-cmd command.
# DRXHUB_LIBRARY is set by brew.sh
# shellcheck disable=SC2154
homebrew-command-path() {
  case "$1" in
    # check we actually have command and not e.g. commandsomething
    command) ;;
    command*) return 1 ;;
    *) ;;
  esac

  local first_command found_command
  for arg in "$@"
  do
    if [[ -z "${first_command}" && "${arg}" == "command" ]]
    then
      first_command=1
      continue
    elif [[ -f "${DRXHUB_LIBRARY}/DinrusHub/cmd/${arg}.sh" ]]
    then
      echo "${DRXHUB_LIBRARY}/DinrusHub/cmd/${arg}.sh"
      found_command=1
    elif [[ -f "${DRXHUB_LIBRARY}/DinrusHub/dev-cmd/${arg}.sh" ]]
    then
      echo "${DRXHUB_LIBRARY}/DinrusHub/dev-cmd/${arg}.sh"
      found_command=1
    elif [[ -f "${DRXHUB_LIBRARY}/DinrusHub/cmd/${arg}.rb" ]]
    then
      echo "${DRXHUB_LIBRARY}/DinrusHub/cmd/${arg}.rb"
      found_command=1
    elif [[ -f "${DRXHUB_LIBRARY}/DinrusHub/dev-cmd/${arg}.rb" ]]
    then
      echo "${DRXHUB_LIBRARY}/DinrusHub/dev-cmd/${arg}.rb"
      found_command=1
    else
      return 1
    fi
  done

  if [[ -n "${found_command}" ]]
  then
    return 0
  else
    return 1
  fi
}
