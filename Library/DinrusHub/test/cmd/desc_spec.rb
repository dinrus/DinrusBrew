# frozen_string_literal: true

require "cmd/desc"
require "cmd/shared_examples/args_parse"

RSpec.describe DinrusHub::Cmd::Desc do
  it_behaves_like "parseable arguments"

  it "shows a given Formula's description", :integration_test do
    setup_test_formula "testball"

    expect { dhub "desc", "testball" }
      .to output("testball: Some test\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "errors when searching without --eval-all", :integration_test do
    setup_test_formula "testball"

    expect { dhub "desc", "--search", "testball" }
      .to output(/`dhub desc --search` needs `--eval-all` passed or `\$DRXHUB_EVAL_ALL` set!/).to_stderr
      .and be_a_failure
  end

  it "successfully searches with --search --eval-all", :integration_test do
    setup_test_formula "testball"

    expect { dhub "desc", "--search", "--eval-all", "ball" }
      .to output(/testball: Some test/).to_stdout
      .and not_to_output.to_stderr
  end

  it "successfully searches without --eval-all, with API", :integration_test do
    setup_test_formula "testball"

    expect { dhub "desc", "--search", "testball", "DRXHUB_NO_INSTALL_FROM_API" => nil }
      .to be_a_success
  end
end
