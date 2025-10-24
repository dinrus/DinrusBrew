# typed: strict
# frozen_string_literal: true

require "abstract_command"
require "cask/config"
require "cask/installer"
require "cask_dependent"
require "missing_formula"
require "formula_installer"
require "development_tools"
require "install"
require "cleanup"
require "upgrade"

module DinrusHub
  module Cmd
    class InstallCmd < AbstractCommand
      cmd_args do
        description <<~EOS
          Устанавливает <формула> или <каск>. В команду можно добавить дополнительные опции, касающиеся
          <формула>.

          Если не установлена `$DRXHUB_NO_INSTALLED_DEPENDENTS_CHECK`, то `dhub upgrade` или `dhub reinstall`
          будут выполнены для просроченных (устаревших) зависимостей и зависимостей со сломанной линковкой,
          соответственно.

          Если не установлена `$DRXHUB_NO_INSTALL_CLEANUP`, `dhub cleanup` будет выполнен для
          установленных формул, либо, каждые 30 дней, для всех формул.

          Если не установлена `$DRXHUB_NO_INSTALL_UPGRADE`, `dhub install` <формула> сделает апгрейд
          <формула>, если она уже установлена, но не свежая.
        EOS
        switch "-d", "--debug",
               description: "Если брюинг не удался, открывает интерактивную отладочную сессию с доступом к IRB, " \
                            "либо оболочку внутри временной директории построения."
        switch "--display-times",
               env:         :display_install_times,
               description: "Выводить сроки установки для каждого пакета в итоге выполнения."
        switch "-f", "--force",
               description: "Устанавливать формулы, не проверяя ранее установленных версии keg-only или " \
                            "non-migrated. При установке касков, пеереписываются существующие файлы " \
                            "(бинарники и симв. ссылки исключаются, если не происходят из этого же каска)."
        switch "-v", "--verbose",
               description: "Выводит шаги верификации и послеустановочные."
        switch "-n", "--dry-run",
               description: "Показать, что будет установлено, но на самом деле не устанавливать ничего."
        [
          [:switch, "--formula", "--formulae", {
            description: "Все именованные аргументы принимать за формулы.",
          }],
          [:flag, "--env=", {
            description: "Отключено для любого иного использования, кроме как внутри DinrusHub.",
            hidden:      true,
          }],
          [:switch, "--ignore-dependencies", {
            description: "Неподдерживаемая опция разработки DinrusHub, позволяющая избежать установки любого " \
                         "рода зависимостей. Если зависимостей ещё нет, то у формулы будут проблемы. Если вы " \
                         "не разрабатываете DinrusHub, то лучше настройте свой PATH, а не используйте эту " \
                         "опцию.",
          }],
          [:switch, "--only-dependencies", {
            description: "Установить зависимости с указанными опциями, но не устанавливать саму " \
                         "формулу.",
          }],
          [:flag, "--cc=", {
            description: "Попытаться компилировать, используя <компилятор>, то есть имя исполнимого файла  " \
                         "компилятора, например, `drux`. Для использования clang от LLVM, нужно указать " \
                         "`llvm_clang`. Для использования clang от Apple, укажите `clang`. Опция принимает только " \
                         "компиляторы, предоставленные DinrusHub или в связке с macOS.",
          }],
          [:switch, "-s", "--build-from-source", {
            description: "Компилировать <формула> из исходников, даже если есть готовая бутыль. " \
                         "Если есть зависимости, они всё же будут установлены из бутылей.",
          }],
          [:switch, "--force-bottle", {
            description: "Установить из бутыли, если она есть, для текущей или более новой версии " \
                         "macOS, даже если она обычно не используется для установки.",
          }],
          [:switch, "--include-test", {
            description: "Установить тестирующие зависимости, требуемые для выполнения `dhub test` <формула>.",
          }],
          [:switch, "--HEAD", {
            description: "If <formula> defines it, install the HEAD version, aka. main, trunk, unstable, master.",
          }],
          [:switch, "--fetch-HEAD", {
            description: "Fetch the upstream repository to detect if the HEAD installation of the " \
                         "formula is outdated. Otherwise, the repository's HEAD will only be checked for " \
                         "updates when a new stable or development version has been released.",
          }],
          [:switch, "--keep-tmp", {
            description: "Оставить целыми временные файлы, созданные при установке.",
          }],
          [:switch, "--debug-symbols", {
            depends_on:  "--build-from-source",
            description: "Генерировать при построении отладочные символы. Исходник останется в директории кэша.",
          }],
          [:switch, "--build-bottle", {
            description: "Подготовить формулу к вероятному бытылированию при установке, пропустив все " \
                         "послеустановочные шаги.",
          }],
          [:switch, "--skip-post-install", {
            description: "Установить, но не выполнять никаких послеустановочных шагов.",
          }],
          [:switch, "--skip-link", {
            description: "Установить, но не компоновать кег в префикс.",
          }],
          [:flag, "--bottle-arch=", {
            depends_on:  "--build-bottle",
            description: "Оптимизировать бутыли для указанной архитектуры, а не для самой старой, поддерживаемой " \
                         "версией macOS, на которой они были построены.",
          }],
          [:switch, "-i", "--interactive", {
            description: "Загрузить и пропатчить <формула>, затем открыть оболочку. Это позволяет пользователю " \
                         "выполнить `./configure --help` и определить, как сделать пакет ПО " \
                         "пакеетом DinrusHub.",
          }],
          [:switch, "-g", "--git", {
            description: "Создать репозиторию Git, используемую для создания патчей для ПО.",
          }],
          [:switch, "--overwrite", {
            description: "Удалять из префикса уже существующие файлы при компоновке.",
          }],
        ].each do |args|
          options = args.pop
          send(*args, **options)
          conflicts "--cask", args.last
        end
        formula_options
        [
          [:switch, "--cask", "--casks", { description: "Считать все именованные аргументы касками." }],
          [:switch, "--[no-]binaries", {
            description: "Отключить/включить компоновку вспомогательных исполнимых (дефолт: включено).",
            env:         :cask_opts_binaries,
          }],
          [:switch, "--require-sha",  {
            description: "У всех касков обязательно должна быть контрольная сумма.",
            env:         :cask_opts_require_sha,
          }],
          [:switch, "--[no-]quarantine", {
            description: "Отключить/включить отправку загрузок в карантин (дефолт: включено).",
            env:         :cask_opts_quarantine,
          }],
          [:switch, "--adopt", {
            description: "Adopt existing artifacts in the destination that are identical to those being installed. " \
                         "Cannot be combined with `--force`.",
          }],
          [:switch, "--skip-cask-deps", {
            description: "Не устанавливать зависимости каска.",
          }],
          [:switch, "--zap", {
            description: "For use with `dhub reinstall --cask`. Remove all files associated with a cask. " \
                         "*May remove files which are shared between applications.*",
          }],
        ].each do |args|
          options = args.pop
          send(*args, **options)
          conflicts "--formula", args.last
        end
        cask_options

        conflicts "--ignore-dependencies", "--only-dependencies"
        conflicts "--build-from-source", "--build-bottle", "--force-bottle"
        conflicts "--adopt", "--force"

        named_args [:formula, :cask], min: 1
      end

      sig { override.void }
      def run
        if args.env.present?
          # Can't use `replacement: false` because `install_args` are used by
          # `build.rb`. Instead, `hide_from_man_page` and don't do anything with
          # this argument here.
          # This odisabled should stick around indefinitely.
          odisabled "dhub install --env", "`env :std` in specific formula files"
        end

        args.named.each do |name|
          if (tap_with_name = Tap.with_formula_name(name))
            tap, = tap_with_name
          elsif (tap_with_token = Tap.with_cask_token(name))
            tap, = tap_with_token
          end

          tap&.ensure_installed!
        end

        if args.ignore_dependencies?
          opoo <<~EOS
            #{Tty.bold}`--ignore-dependencies` is an unsupported DinrusHub developer option!#{Tty.reset}
            Adjust your PATH to put any preferred versions of applications earlier in the
            PATH rather than using this unsupported option!

          EOS
        end

        begin
          formulae, casks = T.cast(
            args.named.to_formulae_and_casks(warn: false).partition { _1.is_a?(Formula) },
            [T::Array[Formula], T::Array[Cask::Cask]],
          )
        rescue FormulaOrCaskUnavailableError, Cask::CaskUnavailableError
          cask_tap = CoreCaskTap.instance
          if !cask_tap.installed? && (args.cask? || Tap.untapped_official_taps.exclude?(cask_tap.name))
            cask_tap.ensure_installed!
            retry if cask_tap.installed?
          end

          raise
        end

        if casks.any?
          if args.dry_run?
            if (casks_to_install = casks.reject(&:installed?).presence)
              ohai "Would install #{::Utils.pluralize("cask", casks_to_install.count, include_count: true)}:"
              puts casks_to_install.map(&:full_name).join(" ")
            end
            casks.each do |cask|
              dep_names = CaskDependent.new(cask)
                                       .runtime_dependencies
                                       .reject(&:installed?)
                                       .map(&:to_formula)
                                       .map(&:name)
              next if dep_names.blank?

              ohai "Would install #{::Utils.pluralize("dependenc", dep_names.count, plural: "ies", singular: "y",
                                                  include_count: true)} for #{cask.full_name}:"
              puts dep_names.join(" ")
            end
            return
          end

          require "cask/installer"

          installed_casks, new_casks = casks.partition(&:installed?)

          new_casks.each do |cask|
            Cask::Installer.new(
              cask,
              binaries:       args.binaries?,
              verbose:        args.verbose?,
              force:          args.force?,
              adopt:          args.adopt?,
              require_sha:    args.require_sha?,
              skip_cask_deps: args.skip_cask_deps?,
              quarantine:     args.quarantine?,
              quiet:          args.quiet?,
            ).install
          end

          if !DinrusHub::EnvConfig.no_install_upgrade? && installed_casks.any?
            require "cask/upgrade"

            Cask::Upgrade.upgrade_casks(
              *installed_casks,
              force:          args.force?,
              dry_run:        args.dry_run?,
              binaries:       args.binaries?,
              quarantine:     args.quarantine?,
              require_sha:    args.require_sha?,
              skip_cask_deps: args.skip_cask_deps?,
              verbose:        args.verbose?,
              quiet:          args.quiet?,
              args:,
            )
          end
        end

        formulae = DinrusHub::Attestation.sort_formulae_for_install(formulae) if DinrusHub::Attestation.enabled?

        # if the user's flags will prevent bottle only-installations when no
        # developer tools are available, we need to stop them early on
        build_flags = []
        unless DevelopmentTools.installed?
          build_flags << "--HEAD" if args.HEAD?
          build_flags << "--build-bottle" if args.build_bottle?
          build_flags << "--build-from-source" if args.build_from_source?

          raise BuildFlagsError.new(build_flags, bottled: formulae.all?(&:bottled?)) if build_flags.present?
        end

        if build_flags.present? && !DinrusHub::EnvConfig.developer?
          opoo "построение из исходников не поддерживается!"
          puts "Действуйте, как знаете. Ожидаются сбои, но не жалуйтесь потом ни на какие проблемы!"
        end

        installed_formulae = formulae.select do |f|
          Install.install_formula?(
            f,
            head:              args.HEAD?,
            fetch_head:        args.fetch_HEAD?,
            only_dependencies: args.only_dependencies?,
            force:             args.force?,
            quiet:             args.quiet?,
            skip_link:         args.skip_link?,
            overwrite:         args.overwrite?,
          )
        end

        return if formulae.any? && installed_formulae.empty?

        Install.perform_preinstall_checks_once
        Install.check_cc_argv(args.cc)

        Install.install_formulae(
          installed_formulae,
          build_bottle:               args.build_bottle?,
          force_bottle:               args.force_bottle?,
          bottle_arch:                args.bottle_arch,
          ignore_deps:                args.ignore_dependencies?,
          only_deps:                  args.only_dependencies?,
          include_test_formulae:      args.include_test_formulae,
          build_from_source_formulae: args.build_from_source_formulae,
          cc:                         args.cc,
          git:                        args.git?,
          interactive:                args.interactive?,
          keep_tmp:                   args.keep_tmp?,
          debug_symbols:              args.debug_symbols?,
          force:                      args.force?,
          overwrite:                  args.overwrite?,
          debug:                      args.debug?,
          quiet:                      args.quiet?,
          verbose:                    args.verbose?,
          dry_run:                    args.dry_run?,
          skip_post_install:          args.skip_post_install?,
          skip_link:                  args.skip_link?,
        )

        Upgrade.check_installed_dependents(
          installed_formulae,
          flags:                      args.flags_only,
          installed_on_request:       args.named.present?,
          force_bottle:               args.force_bottle?,
          build_from_source_formulae: args.build_from_source_formulae,
          interactive:                args.interactive?,
          keep_tmp:                   args.keep_tmp?,
          debug_symbols:              args.debug_symbols?,
          force:                      args.force?,
          debug:                      args.debug?,
          quiet:                      args.quiet?,
          verbose:                    args.verbose?,
          dry_run:                    args.dry_run?,
        )

        Cleanup.periodic_clean!(dry_run: args.dry_run?)

        DinrusHub.messages.display_messages(display_times: args.display_times?)
      rescue FormulaUnreadableError, FormulaClassUnavailableError,
             TapFormulaUnreadableError, TapFormulaClassUnavailableError => e
        require "utils/backtrace"

        # Need to rescue before `FormulaUnavailableError` (superclass of this)
        # is handled, as searching for a formula doesn't make sense here (the
        # formula was found, but there's a problem with its implementation).
        $stderr.puts Utils::Backtrace.clean(e) if DinrusHub::EnvConfig.developer?
        ofail e.message
      rescue FormulaOrCaskUnavailableError, Cask::CaskUnavailableError => e
        DinrusHub.failed = true

        # formula name or cask token
        name = case e
        when FormulaOrCaskUnavailableError then e.name
        when Cask::CaskUnavailableError then e.token
        else T.absurd(e)
        end

        if name == "updog"
          ofail "What's updog?"
          return
        end

        opoo e

        reason = MissingFormula.reason(name, silent: true)
        if !args.cask? && reason
          $stderr.puts reason
          return
        end

        # We don't seem to get good search results when the tap is specified
        # so we might as well return early.
        return if name.include?("/")

        require "search"

        package_types = []
        package_types << "формулы" unless args.cask?
        package_types << "каска" unless args.formula?

        ohai "Поиск #{package_types.join(" и ")} с похожим названием..."

        # Don't treat formula/cask name as a regex
        string_or_regex = name
        all_formulae, all_casks = Search.search_names(string_or_regex, args)

        if all_formulae.any?
          ohai "Формулы", Formatter.columns(all_formulae)
          first_formula = all_formulae.first.to_s
          puts <<~EOS

            Чтобы установить #{first_formula}, выполните:
              dhub install #{first_formula}
          EOS
        end
        puts if all_formulae.any? && all_casks.any?
        if all_casks.any?
          ohai "Каски", Formatter.columns(all_casks)
          first_cask = all_casks.first.to_s
          puts <<~EOS

            Чтобы установить #{first_cask}, выполните:
              dhub install --cask #{first_cask}
          EOS
        end
        return if all_formulae.any? || all_casks.any?

        odie "Не найден #{package_types.join(" или ")} для #{name}."
      end
    end
  end
end
