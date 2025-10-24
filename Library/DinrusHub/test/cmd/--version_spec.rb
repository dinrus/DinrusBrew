# frozen_string_literal: true

RSpec.describe "dhub --version", type: :system do
  it "prints the DinrusHub's version", :integration_test do
    expect { brew_sh "--version" }
      .to output(/^DinrusHub #{Regexp.escape(DRXHUB_VERSION)}\n/o).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
