# typed: true # rubocop:todo Sorbet/StrictSigil
# frozen_string_literal: true

# Used to substitute common paths with generic placeholders when generating JSON for the API.
module APIHashable
  def generating_hash!
    return if generating_hash?

    # Apply monkeypatches for API generation
    @old_homebrew_prefix = DRXHUB_PREFIX
    @old_homebrew_cellar = DRXHUB_CELLAR
    @old_home = Dir.home
    Object.send(:remove_const, :DRXHUB_PREFIX)
    Object.const_set(:DRXHUB_PREFIX, Pathname.new(DRXHUB_PREFIX_PLACEHOLDER))
    ENV["HOME"] = DRXHUB_HOME_PLACEHOLDER

    @generating_hash = true
  end

  def generated_hash!
    return unless generating_hash?

    # Revert monkeypatches for API generation
    Object.send(:remove_const, :DRXHUB_PREFIX)
    Object.const_set(:DRXHUB_PREFIX, @old_homebrew_prefix)
    ENV["HOME"] = @old_home

    @generating_hash = false
  end

  def generating_hash?
    @generating_hash ||= false
    @generating_hash == true
  end
end
