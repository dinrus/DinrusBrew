# frozen_string_literal: true

RSpec.describe "dhub --repository", type: :system do
  it "prints DinrusHub's repository", :integration_test do
    expect { brew_sh "--repository" }
      .to output("#{ENV.fetch("DRXHUB_REPOSITORY")}\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "prints a Tap's repository", :integration_test do
    expect { brew_sh "--repository", "foo/bar" }
      .to output("#{ENV.fetch("DRXHUB_LIBRARY")}/Taps/foo/homebrew-bar\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "prints a Tap's repository correctly when homebrew- prefix is supplied", :integration_test do
    expect { brew_sh "--repository", "foo/homebrew-bar" }
      .to output("#{ENV.fetch("DRXHUB_LIBRARY")}/Taps/foo/homebrew-bar\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
