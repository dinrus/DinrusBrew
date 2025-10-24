# typed: strict
# frozen_string_literal: true

require "abstract_command"
require "shell_command"

module DinrusHub
  module Cmd
    class Version < AbstractCommand
      include ShellCommand

      sig { override.returns(String) }
      def self.command_name = "--version"

      cmd_args do
        description <<~EOS
          Print the version numbers of DinrusHub, DinrusHub/homebrew-core and
          DinrusHub/homebrew-cask (if tapped) to standard output.
        EOS
      end
    end
  end
end
