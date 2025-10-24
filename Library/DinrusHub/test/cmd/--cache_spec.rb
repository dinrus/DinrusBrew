# frozen_string_literal: true

require "cmd/--cache"
require "cmd/shared_examples/args_parse"

RSpec.describe DinrusHub::Cmd::Cache do
  it_behaves_like "parseable arguments"

  it "prints all cache files for a given Formula", :integration_test do
    expect { dhub "--cache", testball }
      .to output(%r{#{DRXHUB_CACHE}/downloads/[\da-f]{64}--testball-}o).to_stdout
      .and be_a_success
    expect { dhub "--cache", "--formula", testball }
      .to output(%r{#{DRXHUB_CACHE}/downloads/[\da-f]{64}--testball-}o).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "prints the cache files for a given Cask", :integration_test, :needs_macos do
    expect { dhub "--cache", cask_path("local-caffeine") }
      .to output(%r{#{DRXHUB_CACHE}/downloads/[\da-f]{64}--caffeine\.zip}o).to_stdout
      .and output(/Treating #{Regexp.escape(cask_path("local-caffeine"))} as a cask/).to_stderr
      .and be_a_success
    expect { dhub "--cache", "--cask", cask_path("local-caffeine") }
      .to output(%r{#{DRXHUB_CACHE}/downloads/[\da-f]{64}--caffeine\.zip}o).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "prints the cache files for a given Formula and Cask", :integration_test, :needs_macos do
    expect { dhub "--cache", testball, cask_path("local-caffeine") }
      .to output(
        %r{
          #{DRXHUB_CACHE}/downloads/[\da-f]{64}--testball-.*\n
          #{DRXHUB_CACHE}/downloads/[\da-f]{64}--caffeine\.zip
        }xo,
      ).to_stdout
      .and output(/(Treating .* as a formula).*(Treating .* as a cask)/m).to_stderr
      .and be_a_success
  end
end
