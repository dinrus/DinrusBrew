# frozen_string_literal: true

require "cmd/shared_examples/args_parse"
require "cmd/unpin"

RSpec.describe DinrusHub::Cmd::Unpin do
  it_behaves_like "parseable arguments"

  it "unpins a Formula's version", :integration_test do
    install_test_formula "testball"
    Formula["testball"].pin

    expect { dhub "unpin", "testball" }.to be_a_success
  end
end
