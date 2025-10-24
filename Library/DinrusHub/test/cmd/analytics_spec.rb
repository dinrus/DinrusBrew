# frozen_string_literal: true

require "cmd/analytics"
require "cmd/shared_examples/args_parse"

RSpec.describe DinrusHub::Cmd::Analytics do
  it_behaves_like "parseable arguments"

  it "when DRXHUB_NO_ANALYTICS is unset is disabled after running `dhub analytics off`", :integration_test do
    DRXHUB_REPOSITORY.cd do
      system "git", "init"
    end

    dhub "analytics", "off"
    expect { dhub "analytics", "DRXHUB_NO_ANALYTICS" => nil }
      .to output(/analytics are disabled/i).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
