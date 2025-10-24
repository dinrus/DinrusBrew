# typed: strict
# frozen_string_literal: true

require "abstract_command"

module DinrusHub
  module Cmd
    class Developer < AbstractCommand
      cmd_args do
        description <<~EOS
          Control DinrusHub's developer mode. When developer mode is enabled,
          `dhub update` will update DinrusHub to the latest commit on the `master`
          branch instead of the latest stable version along with some other behaviour changes.

          `dhub developer` [`state`]:
          Display the current state of DinrusHub's developer mode.

          `dhub developer` (`on`|`off`):
          Turn DinrusHub's developer mode on or off respectively.
        EOS

        named_args %w[state on off], max: 1
      end

      sig { override.void }
      def run
        case args.named.first
        when nil, "state"
          if DinrusHub::EnvConfig.developer?
            puts "Developer mode is enabled because #{Tty.bold}DRXHUB_DEVELOPER#{Tty.reset} is set."
          elsif DinrusHub::EnvConfig.devcmdrun?
            puts "Developer mode is enabled because a developer command or `dhub developer on` was run."
          else
            puts "Developer mode is disabled."
          end
          if DinrusHub::EnvConfig.developer? || DinrusHub::EnvConfig.devcmdrun?
            if DinrusHub::EnvConfig.update_to_tag?
              puts "However, `dhub update` will update to the latest stable tag because " \
                   "#{Tty.bold}DRXHUB_UPDATE_TO_TAG#{Tty.reset} is set."
            else
              puts "`dhub update` will update to the latest commit on the `master` branch."
            end
          else
            puts "`dhub update` will update to the latest stable tag."
          end
        when "on"
          DinrusHub::Settings.write "devcmdrun", true
          if DinrusHub::EnvConfig.update_to_tag?
            puts "To fully enable developer mode, you must unset #{Tty.bold}DRXHUB_UPDATE_TO_TAG#{Tty.reset}."
          end
        when "off"
          DinrusHub::Settings.delete "devcmdrun"
          if DinrusHub::EnvConfig.developer?
            puts "To fully disable developer mode, you must unset #{Tty.bold}DRXHUB_DEVELOPER#{Tty.reset}."
          end
        else
          raise UsageError, "unknown subcommand: #{args.named.first}"
        end
      end
    end
  end
end
