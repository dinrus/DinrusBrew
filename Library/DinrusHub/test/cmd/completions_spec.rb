# frozen_string_literal: true

require "cmd/completions"
require "cmd/shared_examples/args_parse"

RSpec.describe DinrusHub::Cmd::CompletionsCmd do
  it_behaves_like "parseable arguments"

  it "runs the status subcommand correctly", :integration_test do
    DRXHUB_REPOSITORY.cd do
      system "git", "init"
    end

    dhub "completions", "link"
    expect { dhub "completions" }
      .to output(/Completions are linked/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
