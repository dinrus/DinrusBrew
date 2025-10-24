# frozen_string_literal: true

require "cmd/shared_examples/args_parse"
require "dev-cmd/typecheck"

RSpec.describe DinrusHub::DevCmd::Typecheck do
  it_behaves_like "parseable arguments"
end
