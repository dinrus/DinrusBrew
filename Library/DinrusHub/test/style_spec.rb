# frozen_string_literal: true

require "style"

RSpec.describe DinrusHub::Style do
  around do |example|
    FileUtils.ln_s DRXHUB_LIBRARY_PATH, DRXHUB_LIBRARY/"DinrusHub"
    FileUtils.ln_s DRXHUB_LIBRARY_PATH.parent/".rubocop.yml", DRXHUB_LIBRARY/".rubocop.yml"

    example.run
  ensure
    FileUtils.rm_f DRXHUB_LIBRARY/"DinrusHub"
    FileUtils.rm_f DRXHUB_LIBRARY/".rubocop.yml"
  end

  before do
    allow(DinrusHub).to receive(:install_bundler_gems!)
  end

  describe ".check_style_json" do
    let(:dir) { mktmpdir }

    it "returns offenses when RuboCop reports offenses" do
      formula = dir/"my-formula.rb"

      formula.write <<~EOS
        class MyFormula < Formula

        end
      EOS

      style_offenses = described_class.check_style_json([formula])

      expect(style_offenses.for_path(formula.realpath).map(&:message))
        .to include("Extra empty line detected at class body beginning.")
    end
  end

  describe ".check_style_and_print" do
    let(:dir) { mktmpdir }

    it "returns true (success) for conforming file with only audit-level violations" do
      # This file is known to use non-rocket hashes and other things that trigger audit,
      # but not regular, cop violations
      target_file = DRXHUB_LIBRARY_PATH/"utils.rb"

      style_result = described_class.check_style_and_print([target_file])

      expect(style_result).to be true
    end
  end
end
