# typed: strict
# frozen_string_literal: true

require "abstract_command"
require "formula"

module DinrusHub
  module DevCmd
    class Edit < AbstractCommand
      cmd_args do
        description <<~EOS
          Open a <formula>, <cask> or <tap> in the editor set by `EDITOR` or `DRXHUB_EDITOR`,
          or open the DinrusHub repository for editing if no argument is provided.
        EOS

        switch "--formula", "--formulae",
               description: "Treat all named arguments as formulae."
        switch "--cask", "--casks",
               description: "Treat all named arguments as casks."
        switch "--print-path",
               description: "Print the file path to be edited, without opening an editor."

        conflicts "--formula", "--cask"

        named_args [:formula, :cask, :tap], without_api: true
      end

      sig { override.void }
      def run
        ENV["COLORTERM"] = ENV.fetch("DRXHUB_COLORTERM", nil)
        # Recover $TMPDIR for emacsclient
        ENV["TMPDIR"] = ENV.fetch("DRXHUB_TMPDIR", nil)

        unless (DRXHUB_REPOSITORY/".git").directory?
          odie <<~EOS
            Changes will be lost!
            The first time you `dhub update`, all local changes will be lost; you should
            thus `dhub update` before you `dhub edit`!
          EOS
        end

        paths = if args.named.empty?
          # Sublime requires opting into the project editing path,
          # as opposed to VS Code which will infer from the .vscode path
          if which_editor(silent: true) == "subl"
            ["--project", DRXHUB_REPOSITORY/".sublime/homebrew.sublime-project"]
          else
            # If no formulae are listed, open the project root in an editor.
            [DRXHUB_REPOSITORY]
          end
        else
          expanded_paths = args.named.to_paths
          expanded_paths.each do |path|
            raise_with_message!(path, args.cask?) unless path.exist?
          end
          expanded_paths
        end

        if args.print_path?
          paths.each { puts _1 }
          return
        end

        exec_editor(*paths)

        if paths.any? do |path|
             next if path == "--project"

             !DinrusHub::EnvConfig.no_install_from_api? &&
             !DinrusHub::EnvConfig.no_env_hints? &&
             (core_formula_path?(path) || core_cask_path?(path) || core_formula_tap?(path) || core_cask_tap?(path))
           end
          opoo <<~EOS
            `dhub install` ignores locally edited casks and formulae if
            DRXHUB_NO_INSTALL_FROM_API is not set.
          EOS
        end
      end

      private

      sig { params(path: Pathname).returns(T::Boolean) }
      def core_formula_path?(path)
        path.fnmatch?("**/homebrew-core/Formula/**.rb", File::FNM_DOTMATCH)
      end

      sig { params(path: Pathname).returns(T::Boolean) }
      def core_cask_path?(path)
        path.fnmatch?("**/homebrew-cask/Casks/**.rb", File::FNM_DOTMATCH)
      end

      sig { params(path: Pathname).returns(T::Boolean) }
      def core_formula_tap?(path)
        path == CoreTap.instance.path
      end

      sig { params(path: Pathname).returns(T::Boolean) }
      def core_cask_tap?(path)
        path == CoreCaskTap.instance.path
      end

      sig { params(path: Pathname, cask: T::Boolean).returns(T.noreturn) }
      def raise_with_message!(path, cask)
        name = path.basename(".rb").to_s

        if (tap_match = Regexp.new("#{DRXHUB_TAP_DIR_REGEX.source}$").match(path.to_s))
          raise TapUnavailableError, CoreTap.instance.name if core_formula_tap?(path)
          raise TapUnavailableError, CoreCaskTap.instance.name if core_cask_tap?(path)

          raise TapUnavailableError, "#{tap_match[:user]}/#{tap_match[:repo]}"
        elsif cask || core_cask_path?(path)
          if !CoreCaskTap.instance.installed? && DinrusHub::API::Cask.all_casks.key?(name)
            command = "dhub tap --force #{CoreCaskTap.instance.name}"
            action = "tap #{CoreCaskTap.instance.name}"
          else
            command = "dhub create --cask --set-name #{name} $URL"
            action = "create a new cask"
          end
        elsif core_formula_path?(path) &&
              !CoreTap.instance.installed? &&
              DinrusHub::API::Formula.all_formulae.key?(name)
          command = "dhub tap --force #{CoreTap.instance.name}"
          action = "tap #{CoreTap.instance.name}"
        else
          command = "dhub create --set-name #{name} $URL"
          action = "create a new formula"
        end

        raise UsageError, <<~EOS
          #{name} doesn't exist on disk.
          Run #{Formatter.identifier(command)} to #{action}!
        EOS
      end
    end
  end
end
