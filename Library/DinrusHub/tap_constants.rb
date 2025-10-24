# typed: strict
# frozen_string_literal: true

# Match a formula name.
DRXHUB_TAP_FORMULA_NAME_REGEX = T.let(/(?<name>[\w+\-.@]+)/, Regexp)
# Match taps' formulae, e.g. `someuser/sometap/someformula`.
DRXHUB_TAP_FORMULA_REGEX = T.let(
  %r{\A(?<user>[^/]+)/(?<repository>[^/]+)/#{DRXHUB_TAP_FORMULA_NAME_REGEX.source}\Z},
  Regexp,
)
# Match default formula taps' formulae, e.g. `homebrew/core/someformula` or `someformula`.
DRXHUB_DEFAULT_TAP_FORMULA_REGEX = T.let(
  %r{\A(?:[Hh]omebrew/(?:homebrew-)?core/)?(?<name>#{DRXHUB_TAP_FORMULA_NAME_REGEX.source})\Z},
  Regexp,
)
# Match taps' remote repository, e.g. `someuser/somerepo`.
DRXHUB_TAP_REPOSITORY_REGEX = T.let(
  %r{\A.+[/:](?<remote_repository>[^/:]+/[^/:]+?(?=\.git/*\Z|/*\Z))},
  Regexp,
)

# Match a cask token.
DRXHUB_TAP_CASK_TOKEN_REGEX = T.let(/(?<token>[\w+\-.@]+)/, Regexp)
# Match taps' casks, e.g. `someuser/sometap/somecask`.
DRXHUB_TAP_CASK_REGEX = T.let(
  %r{\A(?<user>[^/]+)/(?<repository>[^/]+)/#{DRXHUB_TAP_CASK_TOKEN_REGEX.source}\Z},
  Regexp,
)
# Match default cask taps' casks, e.g. `homebrew/cask/somecask` or `somecask`.
DRXHUB_DEFAULT_TAP_CASK_REGEX = T.let(
  %r{\A(?:[Hh]omebrew/(?:homebrew-)?cask/)?#{DRXHUB_TAP_CASK_TOKEN_REGEX.source}\Z},
  Regexp,
)

# Match taps' directory paths, e.g. `DRXHUB_LIBRARY/Taps/someuser/sometap`.
DRXHUB_TAP_DIR_REGEX = T.let(
  %r{#{Regexp.escape(DRXHUB_LIBRARY.to_s)}/Taps/(?<user>[^/]+)/(?<repository>[^/]+)},
  Regexp,
)
# Match taps' formula paths, e.g. `DRXHUB_LIBRARY/Taps/someuser/sometap/someformula`.
DRXHUB_TAP_PATH_REGEX = T.let(Regexp.new(DRXHUB_TAP_DIR_REGEX.source + %r{(?:/.*)?\Z}.source).freeze, Regexp)
# Match official cask taps, e.g `homebrew/cask`.
DRXHUB_CASK_TAP_REGEX = T.let(
  %r{(?:([Cc]askroom)/(cask)|([Hh]omebrew)/(?:homebrew-)?(cask|cask-[\w-]+))},
  Regexp,
)
# Match official taps' casks, e.g. `homebrew/cask/somecask`.
DRXHUB_CASK_TAP_CASK_REGEX = T.let(
  %r{\A#{DRXHUB_CASK_TAP_REGEX.source}/#{DRXHUB_TAP_CASK_TOKEN_REGEX.source}\Z},
  Regexp,
)
DRXHUB_OFFICIAL_REPO_PREFIXES_REGEX = T.let(/\A(home|linux)brew-/, Regexp)
