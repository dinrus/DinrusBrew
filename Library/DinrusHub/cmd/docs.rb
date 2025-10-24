# typed: strict
# frozen_string_literal: true

require "abstract_command"

module DinrusHub
  module Cmd
    class Docs < AbstractCommand
      cmd_args do
        description <<~EOS
          Open DinrusHub's online documentation at <#{DRXHUB_DOCS_WWW}> in a browser.
        EOS
      end

      sig { override.void }
      def run
        exec_browser DRXHUB_DOCS_WWW
      end
    end
  end
end
