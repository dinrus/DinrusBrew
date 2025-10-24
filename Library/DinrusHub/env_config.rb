# typed: strict
# frozen_string_literal: true

module DinrusHub
  # Helper module for querying DinrusHub-specific environment variables.
  #
  # @api internal
  module EnvConfig
    module_function

    ENVS = T.let({
      DRXHUB_ALLOWED_TAPS:                     {
        description: "Список тапов, разделённый пробелами. DinrusHub откажется установить " \
                     "формулу, если её и всех её зависимостей нет в официальном тапе " \
                     "или в тапе в этом списке.",
      },
      DRXHUB_API_AUTO_UPDATE_SECS:             {
        description: "Проверять API DinrusHub на новые формулы или данные о касках каждые " \
                     "`$DRXHUB_API_AUTO_UPDATE_SECS` секунд. Альтернативно можно полностью отключить все  " \
                     "автоматические проверки API посредством`$DRXHUB_NO_AUTO_UPDATE`.",
        default:     450,
      },
      DRXHUB_API_DOMAIN:                       {
        description:  "Использовать этот УРЛ в качестве зеркала загрузки для DinrusHub JSON API. " \
                      "Если файлы метаданных по этому УРЛ временно недоступны, " \
                      "в качестве откатного зеркала будет использован дефолтный домен API.",
        default_text: "`https://formulae.brew.sh/api`.",
        default:      DRXHUB_API_DEFAULT_DOMAIN,
      },
      DRXHUB_ARCH:                             {
        description: "Только Linux: Передать это значение в имя типа, представляющего опцию компилятора `-march`.",
        default:     "native",
      },
      DRXHUB_ARTIFACT_DOMAIN:                  {
        description: "Префиксовать все УРЛы загрузок, включая для бутылей, этим значением. " \
                     "Например, `export DRXHUB_ARTIFACT_DOMAIN=http://localhost:8080` заставит " \
                     "формулу с УРЛ `https://example.com/foo.tar.gz` загружаться с " \
                     "`http://localhost:8080/https://example.com/foo.tar.gz`. " \
                     "Однако у УРЛов бутылей этим префиксом заменяется домен. " \
                     "Например, в итоге " \
                     "`https://ghcr.io/v2/homebrew/core/gettext/manifests/0.21` " \
                     "будет загружаться с " \
                     "`http://localhost:8080/v2/homebrew/core/gettext/manifests/0.21`",
      },
      DRXHUB_ARTIFACT_DOMAIN_NO_FALLBACK:      {
        description: "Если одновременно установлены `$DRXHUB_ARTIFACT_DOMAIN` и `$DRXHUB_ARTIFACT_DOMAIN_NO_FALLBACK`, " \
                     "при неудачном запрросе к `$DRXHUB_ARTIFACT_DOMAIN`, DinrusHub выводит ошибку, а не " \
                     "пробует использовать другой/дефолтный УРЛ.",
        boolean:     true,
      },
      DRXHUB_AUTO_UPDATE_SECS:                 {
        description:  "Выполнять `dhub update` каждые `$DRXHUB_AUTO_UPDATE_SECS` секунд перед некоторыми командами, " \
                      "например, `dhub install`, `dhub upgrade` и `dhub tap`. Альтернативно можно " \
                      "полностью отключить автообновление посредством `$DRXHUB_NO_AUTO_UPDATE`.",
        default_text: "`86400` (24 часа), `3600` (1 час), если запущена команда разработчика, " \
                      "или `300` (5 минут), если установлена `$DRXHUB_NO_INSTALL_FROM_API`.",
      },
      DRXHUB_BAT:                              {
        description: "Если установлена, используется `bat` для команды `dhub cat`.",
        boolean:     true,
      },
      DRXHUB_BAT_CONFIG_PATH:                  {
        description:  "Use this as the `bat` configuration file.",
        default_text: "`$BAT_CONFIG_PATH`.",
      },
      DRXHUB_BAT_THEME:                        {
        description:  "Use this as the `bat` theme for syntax highlighting.",
        default_text: "`$BAT_THEME`.",
      },
      DRXHUB_BOOTSNAP:                         {
        description: "If set, use Bootsnap to speed up repeated `dhub` calls. " \
                     "A no-op on Linux when not using DinrusHub's vendored, relocatable Ruby.",
        boolean:     true,
      },
      DRXHUB_BOTTLE_DOMAIN:                    {
        description:  "Use this URL as the download mirror for bottles. " \
                      "If bottles at that URL are temporarily unavailable, " \
                      "the default bottle domain will be used as a fallback mirror. " \
                      "For example, `export DRXHUB_BOTTLE_DOMAIN=http://localhost:8080` will cause all bottles " \
                      "to download from the prefix `http://localhost:8080/`. " \
                      "If bottles are not available at `$DRXHUB_BOTTLE_DOMAIN` " \
                      "they will be downloaded from the default bottle domain.",
        default_text: "`https://ghcr.io/v2/homebrew/core`.",
        default:      DRXHUB_BOTTLE_DEFAULT_DOMAIN,
      },
      DRXHUB_BREW_GIT_REMOTE:                  {
        description: "Use this URL as the Homebrew/brew `git`(1) remote.",
        default:     DRXHUB_BREW_DEFAULT_GIT_REMOTE,
      },
      DRXHUB_BREW_WRAPPER:                     {
        description: "If set, use wrapper to call `dhub` rather than auto-detecting it.",
      },
      DRXHUB_BROWSER:                          {
        description:  "Use this as the browser when opening project homepages.",
        default_text: "`$BROWSER` or the OS's default browser.",
      },
      DRXHUB_BUNDLE_USER_CACHE:                {
        description: "If set, use this directory as the `bundle`(1) user cache.",
      },
      DRXHUB_CACHE:                            {
        description:  "Use this directory as the download cache.",
        default_text: "macOS: `~/Library/Caches/DinrusHub`, " \
                      "Linux: `$XDG_CACHE_HOME/DinrusHub` or `~/.cache/DinrusHub`.",
        default:      DRXHUB_DEFAULT_CACHE,
      },
      DRXHUB_CASK_OPTS:                        {
        description: "Append these options to all `cask` commands. All `--*dir` options, " \
                     "`--language`, `--require-sha`, `--no-quarantine` and `--no-binaries` are supported. " \
                     "For example, you might add something like the following to your " \
                     "`~/.profile`, `~/.bash_profile`, or `~/.zshenv`:" \
                     "\n\n    `export DRXHUB_CASK_OPTS=\"--appdir=${HOME}/Applications --fontdir=/Library/Fonts\"`",
      },
      DRXHUB_CLEANUP_MAX_AGE_DAYS:             {
        description: "Cleanup all cached files older than this many days.",
        default:     120,
      },
      DRXHUB_CLEANUP_PERIODIC_FULL_DAYS:       {
        description: "If set, `dhub install`, `dhub upgrade` and `dhub reinstall` will cleanup all formulae " \
                     "when this number of days has passed.",
        default:     30,
      },
      DRXHUB_COLOR:                            {
        description: "If set, force colour output on non-TTY outputs.",
        boolean:     true,
      },
      DRXHUB_CORE_GIT_REMOTE:                  {
        description:  "Use this URL as the Homebrew/homebrew-core `git`(1) remote.",
        default_text: "`https://github.com/Homebrew/homebrew-core`.",
        default:      DRXHUB_CORE_DEFAULT_GIT_REMOTE,
      },
      DRXHUB_CURLRC:                           {
        description: "If set to an absolute path (i.e. beginning with `/`), pass it with `--config` when invoking " \
                     "`curl`(1). " \
                     "If set but _not_ a valid path, do not pass `--disable`, which disables the " \
                     "use of `.curlrc`.",
      },
      DRXHUB_CURL_PATH:                        {
        description: "Linux only: Set this value to a new enough `curl` executable for DinrusHub to use.",
        default:     "curl",
      },
      DRXHUB_CURL_RETRIES:                     {
        description: "Pass the given retry count to `--retry` when invoking `curl`(1).",
        default:     3,
      },
      DRXHUB_CURL_VERBOSE:                     {
        description: "If set, pass `--verbose` when invoking `curl`(1).",
        boolean:     true,
      },
      DRXHUB_DEBUG:                            {
        description: "If set, always assume `--debug` when running commands.",
        boolean:     true,
      },
      DRXHUB_DEVELOPER:                        {
        description: "If set, tweak behaviour to be more relevant for DinrusHub developers (active or " \
                     "budding) by e.g. turning warnings into errors.",
        boolean:     true,
      },
      DRXHUB_DISABLE_DEBREW:                   {
        description: "If set, the interactive formula debugger available via `--debug` will be disabled.",
        boolean:     true,
      },
      DRXHUB_DISABLE_LOAD_FORMULA:             {
        description: "If set, refuse to load formulae. This is useful when formulae are not trusted (such " \
                     "as in pull requests).",
        boolean:     true,
      },
      DRXHUB_DISPLAY:                          {
        description:  "Use this X11 display when opening a page in a browser, for example with " \
                      "`dhub home`. Primarily useful on Linux.",
        default_text: "`$DISPLAY`.",
      },
      DRXHUB_DISPLAY_INSTALL_TIMES:            {
        description: "If set, print install times for each formula at the end of the run.",
        boolean:     true,
      },
      DRXHUB_DOCKER_REGISTRY_BASIC_AUTH_TOKEN: {
        description: "Use this base64 encoded username and password for authenticating with a Docker registry " \
                     "proxying GitHub Packages. " \
                     "If `$DRXHUB_DOCKER_REGISTRY_TOKEN` is set, it will be used instead.",
      },
      DRXHUB_DOCKER_REGISTRY_TOKEN:            {
        description: "Use this bearer token for authenticating with a Docker registry proxying GitHub Packages. " \
                     "Preferred over `$DRXHUB_DOCKER_REGISTRY_BASIC_AUTH_TOKEN`.",
      },
      DRXHUB_EDITOR:                           {
        description:  "Use this editor when editing a single formula, or several formulae in the " \
                      "same directory." \
                      "\n\n    *Note:* `dhub edit` will open all of DinrusHub as discontinuous files " \
                      "and directories. Visual Studio Code can handle this correctly in project mode, but many " \
                      "editors will do strange things in this case.",
        default_text: "`$EDITOR` or `$VISUAL`.",
      },
      DRXHUB_EVAL_ALL:                         {
        description: "If set, `dhub` commands evaluate all formulae and casks, executing their arbitrary code, by " \
                     "default without requiring `--eval-all`. Required to cache formula and cask descriptions.",
        boolean:     true,
      },
      DRXHUB_FAIL_LOG_LINES:                   {
        description: "Output this many lines of output on formula `system` failures.",
        default:     15,
      },
      DRXHUB_FORBIDDEN_CASKS:                  {
        description: "A space-separated list of casks. DinrusHub will refuse to install a " \
                     "cask if it or any of its dependencies is on this list.",
      },
      DRXHUB_FORBIDDEN_FORMULAE:               {
        description: "A space-separated list of formulae. DinrusHub will refuse to install a " \
                     "formula or cask if it or any of its dependencies is on this list.",
      },
      DRXHUB_FORBIDDEN_LICENSES:               {
        description: "A space-separated list of SPDX license identifiers. DinrusHub will refuse to install a " \
                     "formula if it or any of its dependencies has a license on this list.",
      },
      DRXHUB_FORBIDDEN_OWNER:                  {
        description: "The person who has set any `$DRXHUB_FORBIDDEN_*` variables.",
        default:     "you",
      },
      DRXHUB_FORBIDDEN_OWNER_CONTACT:          {
        description: "How to contact the `$DRXHUB_FORBIDDEN_OWNER`, if set and necessary.",
      },
      DRXHUB_FORBIDDEN_TAPS:                   {
        description: "A space-separated list of taps. DinrusHub will refuse to install a " \
                     "formula if it or any of its dependencies is in a tap on this list.",
      },
      DRXHUB_FORBID_PACKAGES_FROM_PATHS:       {
        description: "If set, DinrusHub will refuse to read formulae or casks provided from file paths, " \
                     "e.g. `dhub install ./package.rb`.",
        boolean:     true,
      },
      DRXHUB_FORCE_API_AUTO_UPDATE:            {
        description: "If set, update the DinrusHub API formula or cask data even if " \
                     "`$DRXHUB_NO_AUTO_UPDATE` is set.",
        boolean:     true,
      },
      DRXHUB_FORCE_BREWED_CA_CERTIFICATES:     {
        description: "If set, always use a DinrusHub-installed `ca-certificates` rather than the system version. " \
                     "Automatically set if the system version is too old.",
        boolean:     true,
      },
      DRXHUB_FORCE_BREWED_CURL:                {
        description: "If set, always use a DinrusHub-installed `curl`(1) rather than the system version. " \
                     "Automatically set if the system version of `curl` is too old.",
        boolean:     true,
      },
      DRXHUB_FORCE_BREWED_GIT:                 {
        description: "If set, always use a DinrusHub-installed `git`(1) rather than the system version. " \
                     "Automatically set if the system version of `git` is too old.",
        boolean:     true,
      },
      DRXHUB_FORCE_BREW_WRAPPER:               {
        description: "If set, require `$DRXHUB_BREW_WRAPPER` to be set to the same value as " \
                     "`$DRXHUB_FORCE_BREW_WRAPPER` for non-trivial `dhub` commands.",
      },
      DRXHUB_FORCE_VENDOR_RUBY:                {
        description: "If set, always use DinrusHub's vendored, relocatable Ruby version even if the system version " \
                     "of Ruby is new enough.",
        boolean:     true,
      },
      DRXHUB_FORMULA_BUILD_NETWORK:            {
        description: "If set, controls network access to the sandbox for formulae builds. Overrides any " \
                     "controls set through DSL usage inside formulae. Must be `allow` or `deny`. If no value is " \
                     "set through this environment variable or DSL usage, the default behavior is `allow`.",
      },
      DRXHUB_FORMULA_POSTINSTALL_NETWORK:      {
        description: "If set, controls network access to the sandbox for formulae postinstall. Overrides any " \
                     "controls set through DSL usage inside formulae. Must be `allow` or `deny`. If no value is " \
                     "set through this environment variable or DSL usage, the default behavior is `allow`.",
      },
      DRXHUB_FORMULA_TEST_NETWORK:             {
        description: "If set, controls network access to the sandbox for formulae test. Overrides any " \
                     "controls set through DSL usage inside formulae. Must be `allow` or `deny`. If no value is " \
                     "set through this environment variable or DSL usage, the default behavior is `allow`.",
      },
      DRXHUB_GITHUB_API_TOKEN:                 {
        description: "Use this personal access token for the GitHub API, for features such as " \
                     "`dhub search`. You can create one at <https://github.com/settings/tokens>. If set, " \
                     "GitHub will allow you a greater number of API requests. For more information, see: " \
                     "<https://docs.github.com/en/rest/overview/rate-limits-for-the-rest-api>" \
                     "\n\n    *Note:* DinrusHub doesn't require permissions for any of the scopes, but some " \
                     "developer commands may require additional permissions.",
      },
      DRXHUB_GITHUB_PACKAGES_TOKEN:            {
        description: "Use this GitHub personal access token when accessing the GitHub Packages Registry " \
                     "(where bottles may be stored).",
      },
      DRXHUB_GITHUB_PACKAGES_USER:             {
        description: "Use this username when accessing the GitHub Packages Registry (where bottles may be stored).",
      },
      DRXHUB_GIT_COMMITTER_EMAIL:              {
        description: "Set the Git committer email to this value.",
      },
      DRXHUB_GIT_COMMITTER_NAME:               {
        description: "Set the Git committer name to this value.",
      },
      DRXHUB_GIT_EMAIL:                        {
        description: "Set the Git author name and, if `$DRXHUB_GIT_COMMITTER_EMAIL` is unset, committer email to " \
                     "this value.",
      },
      DRXHUB_GIT_NAME:                         {
        description: "Set the Git author name and, if `$DRXHUB_GIT_COMMITTER_NAME` is unset, committer name to " \
                     "this value.",
      },
      DRXHUB_GIT_PATH:                         {
        description: "Linux only: Set this value to a new enough `git` executable for DinrusHub to use.",
        default:     "git",
      },
      DRXHUB_INSTALL_BADGE:                    {
        description:  "Print this text before the installation summary of each successful build.",
        default_text: 'The "Beer Mug" emoji.',
        default:      "🍺",
      },
      DRXHUB_LIVECHECK_AUTOBUMP:               {
        description: "If set, `dhub livecheck` will include data for packages that are autobumped by BrewTestBot.",
        boolean:     true,
      },
      DRXHUB_LIVECHECK_WATCHLIST:              {
        description:  "Consult this file for the list of formulae to check by default when no formula argument " \
                      "is passed to `dhub livecheck`.",
        default_text: "`${XDG_CONFIG_HOME}/homebrew/livecheck_watchlist.txt` if `$XDG_CONFIG_HOME` is set " \
                      "or `~/.homebrew/livecheck_watchlist.txt` otherwise.",
        default:      "#{ENV.fetch("DRXHUB_USER_CONFIG_HOME")}/livecheck_watchlist.txt",
      },
      DRXHUB_LOCK_CONTEXT:                     {
        description: "If set, DinrusHub will add this output as additional context for locking errors. " \
                     "This is useful when running `dhub` in the background.",
      },
      DRXHUB_LOGS:                             {
        description:  "Use this directory to store log files.",
        default_text: "macOS: `~/Library/Logs/DinrusHub`, " \
                      "Linux: `${XDG_CACHE_HOME}/Homebrew/Logs` or `~/.cache/Homebrew/Logs`.",
        default:      DRXHUB_DEFAULT_LOGS,
      },
      DRXHUB_MAKE_JOBS:                        {
        description:  "Use this value as the number of parallel jobs to run when building with `make`(1).",
        default_text: "The number of available CPU cores.",
        default:      lambda {
          require "os"
          require "hardware"
          Hardware::CPU.cores
        },
      },
      DRXHUB_NO_ANALYTICS:                     {
        description: "If set, do not send analytics. Google Analytics were destroyed. " \
                     "For more information, see: <https://docs.brew.sh/Analytics>",
        boolean:     true,
      },
      DRXHUB_NO_AUTOREMOVE:                    {
        description: "If set, calls to `dhub cleanup` and `dhub uninstall` will not automatically " \
                     "remove unused formula dependents.",
        boolean:     true,
      },
      DRXHUB_NO_AUTO_UPDATE:                   {
        description: "If set, do not automatically update before running some commands, e.g. " \
                     "`dhub install`, `dhub upgrade` and `dhub tap`. Preferably, " \
                     "run this less often by setting `$DRXHUB_AUTO_UPDATE_SECS` to a value higher than the " \
                     "default. Note that setting this and e.g. tapping new taps may result in a broken  " \
                     "configuration. Please ensure you always run `dhub update` before reporting any issues.",
        boolean:     true,
      },
      DRXHUB_NO_BOOTSNAP:                      {
        description: "If set, do not use Bootsnap to speed up repeated `dhub` calls.",
        boolean:     true,
      },
      DRXHUB_NO_CLEANUP_FORMULAE:              {
        description: "A comma-separated list of formulae. DinrusHub will refuse to clean up " \
                     "or autoremove a formula if it appears on this list.",
      },
      DRXHUB_NO_COLOR:                         {
        description:  "If set, do not print text with colour added.",
        default_text: "`$NO_COLOR`.",
        boolean:      true,
      },
      DRXHUB_NO_EMOJI:                         {
        description: "If set, do not print `$DRXHUB_INSTALL_BADGE` on a successful build.",
        boolean:     true,
      },
      DRXHUB_NO_ENV_HINTS:                     {
        description: "If set, do not print any hints about changing DinrusHub's behaviour with environment variables.",
        boolean:     true,
      },
      DRXHUB_NO_FORCE_BREW_WRAPPER:            {
        description: "If set, disables `$DRXHUB_FORCE_BREW_WRAPPER` behaviour, even if set.",
        boolean:     true,
      },
      DRXHUB_NO_GITHUB_API:                    {
        description: "If set, do not use the GitHub API, e.g. for searches or fetching relevant issues " \
                     "after a failed install.",
        boolean:     true,
      },
      DRXHUB_NO_INSECURE_REDIRECT:             {
        description: "If set, forbid redirects from secure HTTPS to insecure HTTP." \
                     "\n\n    *Note:* while ensuring your downloads are fully secure, this is likely to cause " \
                     "from-source SourceForge, some GNU & GNOME-hosted formulae to fail to download.",
        boolean:     true,
      },
      DRXHUB_NO_INSTALLED_DEPENDENTS_CHECK:    {
        description: "If set, do not check for broken linkage of dependents or outdated dependents after " \
                     "installing, upgrading or reinstalling formulae. This will result in fewer dependents " \
                     "(and their dependencies) being upgraded or reinstalled but may result in more breakage " \
                     "from running `dhub install` <formula> or `dhub upgrade` <formula>.",
        boolean:     true,
      },
      DRXHUB_NO_INSTALL_CLEANUP:               {
        description: "If set, `dhub install`, `dhub upgrade` and `dhub reinstall` will never automatically " \
                     "cleanup installed/upgraded/reinstalled formulae or all formulae every " \
                     "`$DRXHUB_CLEANUP_PERIODIC_FULL_DAYS` days. Alternatively, `$DRXHUB_NO_CLEANUP_FORMULAE` " \
                     "allows specifying specific formulae to not clean up.",
        boolean:     true,
      },
      DRXHUB_NO_INSTALL_FROM_API:              {
        description: "If set, do not install formulae and casks in homebrew/core and homebrew/cask taps using " \
                     "DinrusHub's API and instead use (large, slow) local checkouts of these repositories.",
        boolean:     true,
      },
      DRXHUB_NO_INSTALL_UPGRADE:               {
        description: "If set, `dhub install` <formula|cask> will not upgrade <formula|cask> if it is installed but " \
                     "outdated.",
        boolean:     true,
      },
      DRXHUB_NO_UPDATE_REPORT_NEW:             {
        description: "If set, `dhub update` will not show the list of newly added formulae/casks.",
        boolean:     true,
      },
      DRXHUB_NO_VERIFY_ATTESTATIONS:           {
        description: "If set, DinrusHub not verify cryptographic attestations of build provenance for bottles " \
                     "from homebrew-core.",
        boolean:     true,
      },
      DRXHUB_PIP_INDEX_URL:                    {
        description:  "If set, `dhub install` <formula> will use this URL to download PyPI package resources.",
        default_text: "`https://pypi.org/simple`.",
      },
      DRXHUB_PRY:                              {
        description: "If set, use Pry for the `dhub irb` command.",
        boolean:     true,
      },
      DRXHUB_SIMULATE_MACOS_ON_LINUX:          {
        description: "If set, running DinrusHub on Linux will simulate certain macOS code paths. This is useful " \
                     "when auditing macOS formulae while on Linux.",
        boolean:     true,
      },
      DRXHUB_SKIP_OR_LATER_BOTTLES:            {
        description: "If set along with `$DRXHUB_DEVELOPER`, do not use bottles from older versions " \
                     "of macOS. This is useful in development on new macOS versions.",
        boolean:     true,
      },
      DRXHUB_SORBET_RUNTIME:                   {
        description: "If set, enable runtime typechecking using Sorbet. " \
                     "Set by default for `$DRXHUB_DEVELOPER` or when running some developer commands.",
        boolean:     true,
      },
      DRXHUB_SSH_CONFIG_PATH:                  {
        description:  "If set, DinrusHub will use the given config file instead of `~/.ssh/config` when " \
                      "fetching Git repositories over SSH.",
        default_text: "`~/.ssh/config`",
      },
      DRXHUB_SUDO_THROUGH_SUDO_USER:           {
        description: "If set, DinrusHub will use the `SUDO_USER` environment variable to define the user to " \
                     "`sudo`(8) through when running `sudo`(8).",
        boolean:     true,
      },
      DRXHUB_SVN:                              {
        description:  "Use this as the `svn`(1) binary.",
        default_text: "A DinrusHub-built Subversion (if installed), or the system-provided binary.",
      },
      DRXHUB_SYSTEM_ENV_TAKES_PRIORITY:        {
        description: "If set in DinrusHub's system-wide environment file (`/etc/dhub/dhub.env`), " \
                     "the system-wide environment file will be loaded last to override any prefix or user settings.",
        boolean:     true,
      },
      DRXHUB_TEMP:                             {
        description:  "Use this path as the temporary directory for building packages. Changing " \
                      "this may be needed if your system temporary directory and DinrusHub prefix are on " \
                      "different volumes, as macOS has trouble moving symlinks across volumes when the target " \
                      "does not yet exist. This issue typically occurs when using FileVault or custom SSD " \
                      "configurations.",
        default_text: "macOS: `/private/tmp`, Linux: `/tmp`.",
        default:      DRXHUB_DEFAULT_TEMP,
      },
      DRXHUB_UPDATE_TO_TAG:                    {
        description: "If set, always use the latest stable tag (even if developer commands " \
                     "have been run).",
        boolean:     true,
      },
      DRXHUB_UPGRADE_GREEDY:                   {
        description: "If set, pass `--greedy` to all cask upgrade commands.",
        boolean:     true,
      },
      DRXHUB_VERBOSE:                          {
        description: "If set, always assume `--verbose` when running commands.",
        boolean:     true,
      },
      DRXHUB_VERBOSE_USING_DOTS:               {
        description: "If set, verbose output will print a `.` no more than once a minute. This can be " \
                     "useful to avoid long-running DinrusHub commands being killed due to no output.",
        boolean:     true,
      },
      DRXHUB_VERIFY_ATTESTATIONS:              {
        description: "If set, DinrusHub will use the `gh` tool to verify cryptographic attestations " \
                     "of build provenance for bottles from homebrew-core.",
        boolean:     true,
      },
      SUDO_ASKPASS:                              {
        description: "If set, pass the `-A` option when calling `sudo`(8).",
      },
      all_proxy:                                 {
        description: "Use this SOCKS5 proxy for `curl`(1), `git`(1) and `svn`(1) when downloading through DinrusHub.",
      },
      ftp_proxy:                                 {
        description: "Use this FTP proxy for `curl`(1), `git`(1) and `svn`(1) when downloading through DinrusHub.",
      },
      http_proxy:                                {
        description: "Use this HTTP proxy for `curl`(1), `git`(1) and `svn`(1) when downloading through DinrusHub.",
      },
      https_proxy:                               {
        description: "Use this HTTPS proxy for `curl`(1), `git`(1) and `svn`(1) when downloading through DinrusHub.",
      },
      no_proxy:                                  {
        description: "A comma-separated list of hostnames and domain names excluded " \
                     "from proxying by `curl`(1), `git`(1) and `svn`(1) when downloading through DinrusHub.",
      },
    }.freeze, T::Hash[Symbol, T::Hash[Symbol, T.untyped]])

    sig { params(env: Symbol, hash: T::Hash[Symbol, T.untyped]).returns(String) }
    def env_method_name(env, hash)
      method_name = env.to_s
                       .sub(/^DRXHUB_/, "")
                       .downcase
      method_name = "#{method_name}?" if hash[:boolean]
      method_name
    end

    CUSTOM_IMPLEMENTATIONS = T.let(Set.new([
      :DRXHUB_MAKE_JOBS,
      :DRXHUB_CASK_OPTS,
    ]).freeze, T::Set[Symbol])

    ENVS.each do |env, hash|
      # Needs a custom implementation.
      next if CUSTOM_IMPLEMENTATIONS.include?(env)

      method_name = env_method_name(env, hash)
      env = env.to_s

      if hash[:boolean]
        define_method(method_name) do
          env_value = ENV.fetch(env, nil)

          falsy_values = %w[false no off nil 0]
          if falsy_values.include?(env_value&.downcase)
            odeprecated "#{env}=#{env_value}", <<~EOS.chomp
              #{env}=1 to enable and #{env}= (an empty value) to disable
            EOS
          end

          # TODO: Uncomment the remaining part of the line below after the deprecation/disable cycle.
          env_value.present? # && !falsy_values.include(env_value.downcase)
        end
      elsif hash[:default].present?
        define_method(method_name) do
          ENV[env].presence || hash.fetch(:default).to_s
        end
      else
        define_method(method_name) do
          ENV[env].presence
        end
      end
    end

    # Needs a custom implementation.
    sig { returns(String) }
    def make_jobs
      jobs = ENV["DRXHUB_MAKE_JOBS"].to_i
      return jobs.to_s if jobs.positive?

      ENVS.fetch(:DRXHUB_MAKE_JOBS)
          .fetch(:default)
          .call
          .to_s
    end

    sig { returns(T::Array[String]) }
    def cask_opts
      Shellwords.shellsplit(ENV.fetch("DRXHUB_CASK_OPTS", ""))
    end

    sig { returns(T::Boolean) }
    def cask_opts_binaries?
      cask_opts.reverse_each do |opt|
        return true if opt == "--binaries"
        return false if opt == "--no-binaries"
      end

      true
    end

    sig { returns(T::Boolean) }
    def cask_opts_quarantine?
      cask_opts.reverse_each do |opt|
        return true if opt == "--quarantine"
        return false if opt == "--no-quarantine"
      end

      true
    end

    sig { returns(T::Boolean) }
    def cask_opts_require_sha?
      cask_opts.include?("--require-sha")
    end

    sig { returns(T::Boolean) }
    def automatically_set_no_install_from_api?
      ENV["DRXHUB_AUTOMATICALLY_SET_NO_INSTALL_FROM_API"].present?
    end

    sig { returns(T::Boolean) }
    def devcmdrun?
      DinrusHub::Settings.read("devcmdrun") == "true"
    end
  end
end
