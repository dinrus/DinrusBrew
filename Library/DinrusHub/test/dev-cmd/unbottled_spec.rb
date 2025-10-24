# frozen_string_literal: true

require "cmd/shared_examples/args_parse"
require "dev-cmd/unbottled"

RSpec.describe DinrusHub::DevCmd::Unbottled do
  it_behaves_like "parseable arguments"
end
