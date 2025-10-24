# frozen_string_literal: true

require "download_strategy"

RSpec.describe GitHubGitDownloadStrategy do
  subject(:strategy) { described_class.new(url, name, version) }

  let(:name) { "dhub" }
  let(:url) { "https://github.com/homebrew/brew.git" }
  let(:version) { nil }

  it "parses the URL and sets the corresponding instance variables" do
    expect(strategy.instance_variable_get(:@user)).to eq("homebrew")
    expect(strategy.instance_variable_get(:@repo)).to eq("dhub")
  end
end
