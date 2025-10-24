# frozen_string_literal: true

require "cmd/cleanup"
require "cmd/shared_examples/args_parse"

RSpec.describe DinrusHub::Cmd::CleanupCmd do
  before do
    FileUtils.mkdir_p DRXHUB_LIBRARY/"DinrusHub/vendor/"
    FileUtils.touch DRXHUB_LIBRARY/"DinrusHub/vendor/portable-ruby-version"
  end

  after do
    FileUtils.rm_rf DRXHUB_LIBRARY/"DinrusHub"
  end

  it_behaves_like "parseable arguments"

  describe "--prune=all", :integration_test do
    it "removes all files in DinrusHub's cache" do
      (DRXHUB_CACHE/"test").write "test"

      expect { dhub "cleanup", "--prune=all" }
        .to output(%r{#{Regexp.escape(DRXHUB_CACHE)}/test}o).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end
end
