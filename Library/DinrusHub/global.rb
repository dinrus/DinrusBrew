# typed: true # rubocop:todo Sorbet/StrictSigil
# frozen_string_literal: true

require_relative "startup"

DRXHUB_HELP_MESSAGE = ENV.fetch("DRXHUB_HELP_MESSAGE").freeze

DRXHUB_API_DEFAULT_DOMAIN = ENV.fetch("DRXHUB_API_DEFAULT_DOMAIN").freeze
DRXHUB_BOTTLE_DEFAULT_DOMAIN = ENV.fetch("DRXHUB_BOTTLE_DEFAULT_DOMAIN").freeze
DRXHUB_BREW_DEFAULT_GIT_REMOTE = ENV.fetch("DRXHUB_BREW_DEFAULT_GIT_REMOTE").freeze
DRXHUB_CORE_DEFAULT_GIT_REMOTE = ENV.fetch("DRXHUB_CORE_DEFAULT_GIT_REMOTE").freeze
DRXHUB_DEFAULT_CACHE = ENV.fetch("DRXHUB_DEFAULT_CACHE").freeze
DRXHUB_DEFAULT_LOGS = ENV.fetch("DRXHUB_DEFAULT_LOGS").freeze
DRXHUB_DEFAULT_TEMP = ENV.fetch("DRXHUB_DEFAULT_TEMP").freeze
DRXHUB_REQUIRED_RUBY_VERSION = ENV.fetch("DRXHUB_REQUIRED_RUBY_VERSION").freeze

DRXHUB_PRODUCT = ENV.fetch("DRXHUB_PRODUCT").freeze
DRXHUB_VERSION = ENV.fetch("DRXHUB_VERSION").freeze
DRXHUB_WWW = "https://brew.sh"
DRXHUB_API_WWW = "https://formulae.brew.sh"
DRXHUB_DOCS_WWW = "https://docs.brew.sh"
DRXHUB_SYSTEM = ENV.fetch("DRXHUB_SYSTEM").freeze
DRXHUB_PROCESSOR = ENV.fetch("DRXHUB_PROCESSOR").freeze
DRXHUB_PHYSICAL_PROCESSOR = ENV.fetch("DRXHUB_PHYSICAL_PROCESSOR").freeze

DRXHUB_BREWED_CURL_PATH = Pathname(ENV.fetch("DRXHUB_BREWED_CURL_PATH")).freeze
DRXHUB_USER_AGENT_CURL = ENV.fetch("DRXHUB_USER_AGENT_CURL").freeze
DRXHUB_USER_AGENT_RUBY =
  "#{ENV.fetch("DRXHUB_USER_AGENT")} ruby/#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}".freeze
DRXHUB_USER_AGENT_FAKE_SAFARI =
  # Don't update this beyond 10.15.7 until Safari actually updates their
  # user agent to be beyond 10.15.7 (not the case as-of macOS 14)
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 " \
  "(KHTML, like Gecko) Version/17.0 Safari/605.1.15"
DRXHUB_GITHUB_PACKAGES_AUTH = ENV.fetch("DRXHUB_GITHUB_PACKAGES_AUTH").freeze

DRXHUB_DEFAULT_PREFIX = ENV.fetch("DRXHUB_GENERIC_DEFAULT_PREFIX").freeze
DRXHUB_DEFAULT_REPOSITORY = ENV.fetch("DRXHUB_GENERIC_DEFAULT_REPOSITORY").freeze
DRXHUB_MACOS_ARM_DEFAULT_PREFIX = ENV.fetch("DRXHUB_MACOS_ARM_DEFAULT_PREFIX").freeze
DRXHUB_MACOS_ARM_DEFAULT_REPOSITORY = ENV.fetch("DRXHUB_MACOS_ARM_DEFAULT_REPOSITORY").freeze
DRXHUB_LINUX_DEFAULT_PREFIX = ENV.fetch("DRXHUB_LINUX_DEFAULT_PREFIX").freeze
DRXHUB_LINUX_DEFAULT_REPOSITORY = ENV.fetch("DRXHUB_LINUX_DEFAULT_REPOSITORY").freeze
DRXHUB_PREFIX_PLACEHOLDER = "$DRXHUB_PREFIX"
DRXHUB_CELLAR_PLACEHOLDER = "$DRXHUB_CELLAR"
# Needs a leading slash to avoid `File.expand.path` complaining about non-absolute home.
DRXHUB_HOME_PLACEHOLDER = "/$HOME"
DRXHUB_CASK_APPDIR_PLACEHOLDER = "$APPDIR"

DRXHUB_MACOS_NEWEST_UNSUPPORTED = ENV.fetch("DRXHUB_MACOS_NEWEST_UNSUPPORTED").freeze
DRXHUB_MACOS_OLDEST_SUPPORTED = ENV.fetch("DRXHUB_MACOS_OLDEST_SUPPORTED").freeze
DRXHUB_MACOS_OLDEST_ALLOWED = ENV.fetch("DRXHUB_MACOS_OLDEST_ALLOWED").freeze

DRXHUB_PULL_API_REGEX =
  %r{https://api\.github\.com/repos/([\w-]+)/([\w-]+)?/pulls/(\d+)}
DRXHUB_PULL_OR_COMMIT_URL_REGEX =
  %r[https://github\.com/([\w-]+)/([\w-]+)?/(?:pull/(\d+)|commit/[0-9a-fA-F]{4,40})]
DRXHUB_BOTTLES_EXTNAME_REGEX = /\.([a-z0-9_]+)\.bottle\.(?:(\d+)\.)?tar\.gz$/

module DinrusHub
  extend FileUtils

  DEFAULT_PREFIX = T.let(ENV.fetch("DRXHUB_DEFAULT_PREFIX").freeze, String)
  DEFAULT_REPOSITORY = T.let(ENV.fetch("DRXHUB_DEFAULT_REPOSITORY").freeze, String)
  DEFAULT_CELLAR = "#{DEFAULT_PREFIX}/Cellar".freeze
  DEFAULT_MACOS_CELLAR = "#{DRXHUB_DEFAULT_PREFIX}/Cellar".freeze
  DEFAULT_MACOS_ARM_CELLAR = "#{DRXHUB_MACOS_ARM_DEFAULT_PREFIX}/Cellar".freeze
  DEFAULT_LINUX_CELLAR = "#{DRXHUB_LINUX_DEFAULT_PREFIX}/Cellar".freeze

  class << self
    attr_writer :failed, :raise_deprecation_exceptions, :auditing

    # Check whether DinrusHub is using the default prefix.
    #
    # @api internal
    sig { params(prefix: T.any(Pathname, String)).returns(T::Boolean) }
    def default_prefix?(prefix = DRXHUB_PREFIX)
      prefix.to_s == DEFAULT_PREFIX
    end

    def failed?
      @failed ||= false
      @failed == true
    end

    def messages
      @messages ||= Messages.new
    end

    def raise_deprecation_exceptions?
      @raise_deprecation_exceptions == true
    end

    def auditing?
      @auditing == true
    end

    def running_as_root?
      @process_euid ||= Process.euid
      @process_euid.zero?
    end

    def owner_uid
      @owner_uid ||= DRXHUB_ORIGINAL_BREW_FILE.stat.uid
    end

    def running_as_root_but_not_owned_by_root?
      running_as_root? && !owner_uid.zero?
    end

    def auto_update_command?
      ENV.fetch("DRXHUB_AUTO_UPDATE_COMMAND", false).present?
    end

    sig { params(cmd: T.nilable(String)).void }
    def running_command=(cmd)
      @running_command_with_args = "#{cmd} #{ARGV.join(" ")}"
    end

    sig { returns String }
    def running_command_with_args
      "dhub #{@running_command_with_args}".strip
    end
  end
end

require "PATH"
ENV["DRXHUB_PATH"] ||= ENV.fetch("PATH")
ORIGINAL_PATHS = PATH.new(ENV.fetch("DRXHUB_PATH")).filter_map do |p|
  Pathname.new(p).expand_path
rescue
  nil
end.freeze

require "extend/blank"
require "extend/kernel"
require "os"

require "extend/array"
require "extend/cachable"
require "extend/enumerable"
require "extend/string"
require "extend/pathname"

require "exceptions"

require "tap_constants"
require "official_taps"
