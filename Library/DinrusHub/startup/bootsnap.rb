# typed: true
# frozen_string_literal: true

homebrew_bootsnap_enabled = DRXHUB_USING_PORTABLE_RUBY &&
                            ENV["DRXHUB_NO_BOOTSNAP"].nil? &&
                            !ENV["DRXHUB_BOOTSNAP"].nil?

module DinrusHub
  def self.bootsnap_key
    @bootsnap_key ||= begin
      require "digest/sha2"

      checksum = Digest::SHA256.new
      checksum << RUBY_VERSION
      checksum << RUBY_PLATFORM
      checksum << Dir.children(File.join(Gem.paths.path, "gems")).join(",")

      checksum.hexdigest
    end
  end
end

if homebrew_bootsnap_enabled
  require "bootsnap"

  cache = ENV.fetch("DRXHUB_CACHE", nil) || ENV.fetch("DRXHUB_DEFAULT_CACHE", nil)
  raise "Needs DRXHUB_CACHE or DRXHUB_DEFAULT_CACHE!" if cache.nil? || cache.empty?

  cache = File.join(cache, "bootsnap", DinrusHub.bootsnap_key)

  # We never do `require "vendor/bundle/ruby/..."` or `require "vendor/portable-ruby/..."`,
  # so let's slim the cache a bit by excluding them.
  # Note that gems within `bundle/ruby` will still be cached - these are when directory walking down from above.
  ignore_directories = [
    (DRXHUB_LIBRARY_PATH/"vendor/bundle/ruby").to_s,
    (DRXHUB_LIBRARY_PATH/"vendor/portable-ruby").to_s,
  ]

  Bootsnap.setup(
    cache_dir:          cache,
    ignore_directories:,
    load_path_cache:    true,
    compile_cache_iseq: true,
    compile_cache_yaml: true,
  )
end
