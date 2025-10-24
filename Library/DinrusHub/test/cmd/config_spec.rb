# frozen_string_literal: true

require "cmd/config"
require "cmd/shared_examples/args_parse"

RSpec.describe DinrusHub::Cmd::Config do
  it_behaves_like "parseable arguments"

  it "prints information about the current DinrusHub configuration", :integration_test do
    expect { dhub "config" }
      .to output(/DRXHUB_VERSION: #{Regexp.escape DRXHUB_VERSION}/o).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
