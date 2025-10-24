# typed: strict
# frozen_string_literal: true

module DinrusHub
  module DevCmd
    class Debugger < AbstractCommand
      cmd_args do
        description <<~EOS
          Run the specified DinrusHub command in debug mode.

          To pass flags to the command, use `--` to separate them from the `dhub` flags.
          For example: `dhub debugger -- list --formula`.
        EOS
        switch "-O", "--open",
               description: "Start remote debugging over a Unix socket."

        named_args :command, min: 1
      end

      sig { override.void }
      def run
        raise UsageError, "Debugger is only supported with portable Ruby!" unless DRXHUB_USING_PORTABLE_RUBY

        unless Commands.valid_ruby_cmd?(args.named.first)
          raise UsageError, "`#{args.named.first}` is not a valid Ruby command!"
        end

        brew_rb = (DRXHUB_LIBRARY_PATH/"dhub.rb").resolved_path
        debugger_method = if args.open?
          "open"
        else
          "start"
        end

        env = {}
        env[:RUBY_DEBUG_FORK_MODE] = "parent"
        env[:RUBY_DEBUG_NONSTOP] = "1" unless ENV["DRXHUB_RDBG"]

        with_env(**env) do
          system(*DRXHUB_RUBY_EXEC_ARGS,
                 "-I", $LOAD_PATH.join(File::PATH_SEPARATOR),
                 "-rdebug/#{debugger_method}",
                 brew_rb, *args.named)
        end
      end
    end
  end
end
