# frozen_string_literal: true

require "cmd/shared_examples/args_parse"
require "dev-cmd/linkage"

RSpec.describe DinrusHub::DevCmd::Linkage do
  it_behaves_like "parseable arguments"

  it "works when no arguments are provided", :integration_test do
    setup_test_formula "testball"
    (DRXHUB_CELLAR/"testball/0.0.1/foo").mkpath

    expect { dhub "linkage" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr
  end
end
