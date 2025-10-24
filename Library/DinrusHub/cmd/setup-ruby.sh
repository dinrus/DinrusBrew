# Documentation defined in Library/DinrusHub/cmd/setup-ruby.rb

# DRXHUB_LIBRARY is set by brew.sh
# DRXHUB_BREW_FILE is set by extend/ENV/super.rb
# shellcheck disable=SC2154
homebrew-setup-ruby() {
  source "${DRXHUB_LIBRARY}/DinrusHub/utils/helpers.sh"
  source "${DRXHUB_LIBRARY}/DinrusHub/utils/ruby.sh"
  setup-ruby-path

  if [[ -z "${DRXHUB_DEVELOPER}" ]]
  then
    return
  fi

  # Avoid running Bundler if the command doesn't need it.
  local command="$1"
  if [[ -n "${command}" ]]
  then
    source "${DRXHUB_LIBRARY}/DinrusHub/command_path.sh"

    command_path="$(homebrew-command-path "${command}")"
    if [[ -n "${command_path}" ]]
    then
      if [[ "${command_path}" != *"/dev-cmd/"* ]]
      then
        return
      elif ! grep -q "DinrusHub.install_bundler_gems\!" "${command_path}"
      then
        return
      fi
    fi
  fi

  setup-gem-home-bundle-gemfile

  if ! bundle check &>/dev/null
  then
    "${DRXHUB_BREW_FILE}" install-bundler-gems
  fi
}
