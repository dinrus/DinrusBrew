# frozen_string_literal: true

require "cmd/shared_examples/args_parse"
require "dev-cmd/style"

RSpec.describe DinrusHub::DevCmd::StyleCmd do
  it_behaves_like "parseable arguments"
end
