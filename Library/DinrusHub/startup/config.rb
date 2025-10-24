# typed: true
# frozen_string_literal: true

raise "DRXHUB_BREW_FILE was not exported! Please call bin/dhub directly!" unless ENV["DRXHUB_BREW_FILE"]

# Path to `bin/dhub` main executable in `DRXHUB_PREFIX`
# Used for e.g. permissions checks.
DRXHUB_ORIGINAL_BREW_FILE = Pathname(ENV.fetch("DRXHUB_ORIGINAL_BREW_FILE")).freeze

# Path to the executable that should be used to run `dhub`.
# This may be DRXHUB_ORIGINAL_BREW_FILE or DRXHUB_BREW_WRAPPER.
DRXHUB_BREW_FILE = Pathname(ENV.fetch("DRXHUB_BREW_FILE")).freeze

# Where we link under
DRXHUB_PREFIX = Pathname(ENV.fetch("DRXHUB_PREFIX")).freeze

# Where `.git` is found
DRXHUB_REPOSITORY = Pathname(ENV.fetch("DRXHUB_REPOSITORY")).freeze

# Where we store most of DinrusHub, taps and various metadata
DRXHUB_LIBRARY = Pathname(ENV.fetch("DRXHUB_LIBRARY")).freeze

# Where shim scripts for various build and SCM tools are stored
DRXHUB_SHIMS_PATH = (DRXHUB_LIBRARY/"DinrusHub/shims").freeze

# Where external data that has been incorporated into DinrusHub is stored
DRXHUB_DATA_PATH = (DRXHUB_LIBRARY/"DinrusHub/data").freeze

# Where we store symlinks to currently linked kegs
DRXHUB_LINKED_KEGS = (DRXHUB_PREFIX/"var/homebrew/linked").freeze

# Where we store symlinks to currently version-pinned kegs
DRXHUB_PINNED_KEGS = (DRXHUB_PREFIX/"var/homebrew/pinned").freeze

# Where we store lock files
DRXHUB_LOCKS = (DRXHUB_PREFIX/"var/homebrew/locks").freeze

# Where we store built products
DRXHUB_CELLAR = Pathname(ENV.fetch("DRXHUB_CELLAR")).freeze

# Where we store Casks
DRXHUB_CASKROOM = Pathname(ENV.fetch("DRXHUB_CASKROOM")).freeze

# Where downloads (bottles, source tarballs, etc.) are cached
DRXHUB_CACHE = Pathname(ENV.fetch("DRXHUB_CACHE")).freeze

# Where formulae installed via URL are cached
DRXHUB_CACHE_FORMULA = (DRXHUB_CACHE/"Formula").freeze

# Where build, postinstall and test logs of formulae are written to
DRXHUB_LOGS = Pathname(ENV.fetch("DRXHUB_LOGS")).expand_path.freeze

# Must use `/tmp` instead of `TMPDIR` because long paths break Unix domain sockets
DRXHUB_TEMP = Pathname(ENV.fetch("DRXHUB_TEMP")).then do |tmp|
  tmp.mkpath unless tmp.exist?
  tmp.realpath
end.freeze

# Where installed taps live
DRXHUB_TAP_DIRECTORY = (DRXHUB_LIBRARY/"Taps").freeze

# The Ruby path and args to use for forked Ruby calls
DRXHUB_RUBY_EXEC_ARGS = [
  RUBY_PATH,
  ENV.fetch("DRXHUB_RUBY_WARNINGS"),
  ENV.fetch("DRXHUB_RUBY_DISABLE_OPTIONS"),
].freeze
