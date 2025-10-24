# typed: strong
# frozen_string_literal: true

require "abstract_command"
require "help"

module DinrusHub
  module Cmd
    class HelpCmd < AbstractCommand
      cmd_args do
        description <<~EOS
          Outputs the usage instructions for `dhub` <command>.
          Equivalent to `dhub --help` <command>.
        EOS
        named_args [:command]
      end

      sig { override.void }
      def run
        Help.help
      end
    end
  end
end
