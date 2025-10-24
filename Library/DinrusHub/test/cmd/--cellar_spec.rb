# frozen_string_literal: true

require "cmd/--cellar"
require "cmd/shared_examples/args_parse"

RSpec.describe DinrusHub::Cmd::Cellar do
  it_behaves_like "parseable arguments"

  it "prints DinrusHub's Cellar", :integration_test do
    expect { brew_sh "--cellar" }
      .to output("#{ENV.fetch("DRXHUB_CELLAR")}\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "prints the Cellar for a Formula", :integration_test do
    expect { dhub "--cellar", testball }
      .to output(%r{#{DRXHUB_CELLAR}/testball}o).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
