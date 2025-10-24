# typed: strict
# frozen_string_literal: true

require "abstract_command"

module DinrusHub
  module Cmd
    class Cellar < AbstractCommand
      sig { override.returns(String) }
      def self.command_name = "--cellar"

      cmd_args do
        description <<~EOS
          Display DinrusHub's Cellar path. *Default:* `$(dhub --prefix)/Cellar`, or if
          that directory doesn't exist, `$(dhub --repository)/Cellar`.

          If <formula> is provided, display the location in the Cellar where <formula>
          would be installed, without any sort of versioned directory as the last path.
        EOS

        named_args :formula
      end

      sig { override.void }
      def run
        if args.no_named?
          puts DRXHUB_CELLAR
        else
          puts args.named.to_resolved_formulae.map(&:rack)
        end
      end
    end
  end
end
