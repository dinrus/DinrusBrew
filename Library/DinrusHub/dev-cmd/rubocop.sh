# Documentation defined in Library/DinrusHub/dev-cmd/rubocop.rb

# DRXHUB_LIBRARY is from the user environment.
# DRXHUB_RUBY_PATH is set by utils/ruby.sh
# DRXHUB_BREW_FILE is set by extend/ENV/super.rb
# shellcheck disable=SC2154
homebrew-rubocop() {
  source "${DRXHUB_LIBRARY}/DinrusHub/utils/ruby.sh"
  setup-ruby-path
  setup-gem-home-bundle-gemfile

  BUNDLE_WITH="style"
  export BUNDLE_WITH

  if ! bundle check &>/dev/null
  then
    "${DRXHUB_BREW_FILE}" install-bundler-gems --add-groups="${BUNDLE_WITH}"
  fi

  export PATH="${GEM_HOME}/bin:${PATH}"

  RUBOCOP="${DRXHUB_LIBRARY}/DinrusHub/utils/rubocop.rb"
  exec "${DRXHUB_RUBY_PATH}" "${RUBOCOP}" "$@"
}
