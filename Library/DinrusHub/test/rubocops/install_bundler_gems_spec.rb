# frozen_string_literal: true

require "rubocops/install_bundler_gems"

RSpec.describe RuboCop::Cop::DinrusHub::InstallBundlerGems, :config do
  it "registers an offense and corrects when using `DinrusHub.install_bundler_gems!`" do
    expect_offense(<<~RUBY)
      DinrusHub.install_bundler_gems!
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Only use `DinrusHub.install_bundler_gems!` in dev-cmd.
    RUBY
  end
end
