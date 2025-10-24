# frozen_string_literal: true

require "cmd/help"
require "cmd/shared_examples/args_parse"

RSpec.describe DinrusHub::Cmd::HelpCmd, :integration_test do
  it_behaves_like "parseable arguments"

  describe "help" do
    it "prints help for a documented Ruby command" do
      expect { dhub "help", "cat" }
        .to output(/^Usage: dhub cat/).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end

  describe "cat" do
    it "prints help when no argument is given" do
      expect { dhub "cat" }
        .to output(/^Usage: dhub cat/).to_stderr
        .and not_to_output.to_stdout
        .and be_a_failure
    end
  end
end
