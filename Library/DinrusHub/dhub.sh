#####
##### First do the essential, fast things to ensure commands like `dhub --prefix` and others that we want
##### to be able to `source` in shell configurations run quickly.
#####

case "${MACHTYPE}" in
  arm64-* | aarch64-*)
    DRXHUB_PROCESSOR="arm64"
    ;;
  x86_64-*)
    DRXHUB_PROCESSOR="x86_64"
    ;;
  *)
    DRXHUB_PROCESSOR="$(uname -m)"
    ;;
esac

case "${OSTYPE}" in
  darwin*)
    DRXHUB_SYSTEM="Darwin"
    DRXHUB_MACOS="1"
    ;;
  linux*)
    DRXHUB_SYSTEM="Linux"
    DRXHUB_LINUX="1"
    ;;
  *)
    DRXHUB_SYSTEM="$(uname -s)"
    ;;
esac
DRXHUB_PHYSICAL_PROCESSOR="${DRXHUB_PROCESSOR}"

DRXHUB_MACOS_ARM_DEFAULT_PREFIX="/opt/homebrew"
DRXHUB_MACOS_ARM_DEFAULT_REPOSITORY="${DRXHUB_MACOS_ARM_DEFAULT_PREFIX}"
DRXHUB_LINUX_DEFAULT_PREFIX="/home/drx/.drx"
DRXHUB_LINUX_DEFAULT_REPOSITORY="${DRXHUB_LINUX_DEFAULT_PREFIX}/DinrusHub"
DRXHUB_GENERIC_DEFAULT_PREFIX="/usr/local"
DRXHUB_GENERIC_DEFAULT_REPOSITORY="${DRXHUB_GENERIC_DEFAULT_PREFIX}/DinrusHub"
if [[ -n "${DRXHUB_MACOS}" && "${DRXHUB_PROCESSOR}" == "arm64" ]]
then
  DRXHUB_DEFAULT_PREFIX="${DRXHUB_MACOS_ARM_DEFAULT_PREFIX}"
  DRXHUB_DEFAULT_REPOSITORY="${DRXHUB_MACOS_ARM_DEFAULT_REPOSITORY}"
elif [[ -n "${DRXHUB_LINUX}" ]]
then
  DRXHUB_DEFAULT_PREFIX="${DRXHUB_LINUX_DEFAULT_PREFIX}"
  DRXHUB_DEFAULT_REPOSITORY="${DRXHUB_LINUX_DEFAULT_REPOSITORY}"
else
  DRXHUB_DEFAULT_PREFIX="${DRXHUB_GENERIC_DEFAULT_PREFIX}"
  DRXHUB_DEFAULT_REPOSITORY="${DRXHUB_GENERIC_DEFAULT_REPOSITORY}"
fi

if [[ -n "${DRXHUB_MACOS}" ]]
then
  DRXHUB_DEFAULT_CACHE="${HOME}/Library/Caches/DinrusHub"
  DRXHUB_DEFAULT_LOGS="${HOME}/Library/Logs/DinrusHub"
  DRXHUB_DEFAULT_TEMP="/private/tmp"

  DRXHUB_MACOS_VERSION="$(/usr/bin/sw_vers -productVersion)"

  IFS=. read -r -a MACOS_VERSION_ARRAY <<<"${DRXHUB_MACOS_VERSION}"
  printf -v DRXHUB_MACOS_VERSION_NUMERIC "%02d%02d%02d" "${MACOS_VERSION_ARRAY[@]}"

  unset MACOS_VERSION_ARRAY
else
  CACHE_HOME="${DRXHUB_XDG_CACHE_HOME:-${HOME}/.cache}"
  DRXHUB_DEFAULT_CACHE="${CACHE_HOME}/DinrusHub"
  DRXHUB_DEFAULT_LOGS="${CACHE_HOME}/DinrusHub/Logs"
  DRXHUB_DEFAULT_TEMP="/tmp"
fi

realpath() {
  (cd "$1" &>/dev/null && pwd -P)
}

# Support systems where DRXHUB_PREFIX is the default,
# but a parent directory is a symlink.
# Example: Fedora Silverblue symlinks /home -> var/home
if [[ "${DRXHUB_PREFIX}" != "${DRXHUB_DEFAULT_PREFIX}" && "$(realpath "${DRXHUB_DEFAULT_PREFIX}")" == "${DRXHUB_PREFIX}" ]]
then
  DRXHUB_PREFIX="${DRXHUB_DEFAULT_PREFIX}"
fi

# Support systems where DRXHUB_REPOSITORY is the default,
# but a parent directory is a symlink.
# Example: Fedora Silverblue symlinks /home -> var/home
if [[ "${DRXHUB_REPOSITORY}" != "${DRXHUB_DEFAULT_REPOSITORY}" && "$(realpath "${DRXHUB_DEFAULT_REPOSITORY}")" == "${DRXHUB_REPOSITORY}" ]]
then
  DRXHUB_REPOSITORY="${DRXHUB_DEFAULT_REPOSITORY}"
fi

# Where we store built products; a Cellar in DRXHUB_PREFIX (often /usr/local
# for bottles) unless there's already a Cellar in DRXHUB_REPOSITORY.
# These variables are set by bin/dhub
# shellcheck disable=SC2154
if [[ -d "${DRXHUB_REPOSITORY}/Cellar" ]]
then
  DRXHUB_CELLAR="${DRXHUB_REPOSITORY}/Cellar"
else
  DRXHUB_CELLAR="${DRXHUB_PREFIX}/Cellar"
fi

DRXHUB_CASKROOM="${DRXHUB_PREFIX}/Caskroom"

DRXHUB_CACHE="${DRXHUB_CACHE:-${DRXHUB_DEFAULT_CACHE}}"
DRXHUB_LOGS="${DRXHUB_LOGS:-${DRXHUB_DEFAULT_LOGS}}"
DRXHUB_TEMP="${DRXHUB_TEMP:-${DRXHUB_DEFAULT_TEMP}}"

# commands that take a single or no arguments.
# DRXHUB_LIBRARY set by bin/dhub
# shellcheck disable=SC2154
# doesn't need a default case as other arguments handled elsewhere.
# shellcheck disable=SC2249
case "$1" in
  formulae)
    source "${DRXHUB_LIBRARY}/DinrusHub/cmd/formulae.sh"
    homebrew-formulae
    exit 0
    ;;
  casks)
    source "${DRXHUB_LIBRARY}/DinrusHub/cmd/casks.sh"
    homebrew-casks
    exit 0
    ;;
  shellenv)
    source "${DRXHUB_LIBRARY}/DinrusHub/cmd/shellenv.sh"
    shift
    homebrew-shellenv "$1"
    exit 0
    ;;
esac

source "${DRXHUB_LIBRARY}/DinrusHub/help.sh"

# functions that take multiple arguments or handle multiple commands.
# doesn't need a default case as other arguments handled elsewhere.
# shellcheck disable=SC2249
case "$@" in
  --cellar)
    echo "${DRXHUB_CELLAR}"
    exit 0
    ;;
  --repository | --repo)
    echo "${DRXHUB_REPOSITORY}"
    exit 0
    ;;
  --caskroom)
    echo "${DRXHUB_CASKROOM}"
    exit 0
    ;;
  --cache)
    echo "${DRXHUB_CACHE}"
    exit 0
    ;;
  # falls back to cmd/--prefix.rb and cmd/--cellar.rb on a non-zero return
  --prefix* | --cellar*)
    source "${DRXHUB_LIBRARY}/DinrusHub/formula_path.sh"
    homebrew-formula-path "$@" && exit 0
    ;;
  # falls back to cmd/command.rb on a non-zero return
  command*)
    source "${DRXHUB_LIBRARY}/DinrusHub/command_path.sh"
    homebrew-command-path "$@" && exit 0
    ;;
  # falls back to cmd/list.rb on a non-zero return
  list* | ls*)
    source "${DRXHUB_LIBRARY}/DinrusHub/list.sh"
    homebrew-list "$@" && exit 0
    ;;
  # homebrew-tap only handles invocations with no arguments
  tap)
    source "${DRXHUB_LIBRARY}/DinrusHub/tap.sh"
    homebrew-tap "$@"
    exit 0
    ;;
  # falls back to cmd/help.rb on a non-zero return
  help | --help | -h | --usage | "-?" | "")
    homebrew-help "$@" && exit 0
    ;;
esac

# Include some helper functions.
source "${DRXHUB_LIBRARY}/DinrusHub/utils/helpers.sh"

# Require DRXHUB_BREW_WRAPPER to be set if DRXHUB_FORCE_BREW_WRAPPER is set
# (and DRXHUB_NO_FORCE_BREW_WRAPPER is not set) for all non-trivial commands
# (i.e. not defined above this line e.g. formulae or --cellar).
if [[ -z "${DRXHUB_NO_FORCE_BREW_WRAPPER:-}" && -n "${DRXHUB_FORCE_BREW_WRAPPER:-}" ]]
then
  if [[ -z "${DRXHUB_BREW_WRAPPER:-}" ]]
  then
    odie <<EOS
DRXHUB_FORCE_BREW_WRAPPER установлен в
  ${DRXHUB_FORCE_BREW_WRAPPER},
но DRXHUB_BREW_WRAPPER не установлен. Это говорит о том, что выполняется
  ${DRXHUB_BREW_FILE}
непосредственно, но следовало бы выполняться
  ${DRXHUB_FORCE_BREW_WRAPPER}
EOS
  elif [[ "${DRXHUB_FORCE_BREW_WRAPPER}" != "${DRXHUB_BREW_WRAPPER}" ]]
  then
    odie <<EOS
DRXHUB_FORCE_BREW_WRAPPER установлен в
  ${DRXHUB_FORCE_BREW_WRAPPER}
but DRXHUB_BREW_WRAPPER установлен в
  ${DRXHUB_BREW_WRAPPER}
Это говорит о том, что выполняется
  ${DRXHUB_BREW_FILE}
непосредственно, но следовало бы выполняться:
  ${DRXHUB_FORCE_BREW_WRAPPER}
EOS
  fi
fi

# commands that take a single or no arguments and need to write to DRXHUB_PREFIX.
# DRXHUB_LIBRARY set by bin/dhub
# shellcheck disable=SC2154
# doesn't need a default case as other arguments handled elsewhere.
# shellcheck disable=SC2249
case "$1" in
  setup-ruby)
    source "${DRXHUB_LIBRARY}/DinrusHub/cmd/setup-ruby.sh"
    shift
    homebrew-setup-ruby "$1"
    exit 0
    ;;
esac

#####
##### Next, define all other helper functions.
#####

check-run-command-as-root() {
  [[ "${EUID}" == 0 || "${UID}" == 0 ]] || return

  # Allow Azure Pipelines/GitHub Actions/Docker/Podman/Concourse/Kubernetes to do everything as root (as it's normal there)
  [[ -f /.dockerenv ]] && return
  [[ -f /run/.containerenv ]] && return
  [[ -f /proc/1/cgroup ]] && grep -E "azpl_job|actions_job|docker|garden|kubepods" -q /proc/1/cgroup && return

  # DinrusHub Services may need `sudo` for system-wide daemons.
  [[ "${DRXHUB_COMMAND}" == "services" ]] && return

  # It's fine to run this as root as it's not changing anything.
  [[ "${DRXHUB_COMMAND}" == "--prefix" ]] && return

  odie <<EOS
Running DinrusHub as root is extremely dangerous and no longer supported.
As DinrusHub does not drop privileges on installation you would be giving all
build scripts full access to your system.
EOS
}

check-prefix-is-not-tmpdir() {
  [[ -z "${DRXHUB_MACOS}" ]] && return

  if [[ "${DRXHUB_PREFIX}" == "${DRXHUB_TEMP}"* ]]
  then
    odie <<EOS
Your DRXHUB_PREFIX is in the DinrusHub temporary directory, which DinrusHub
uses to store downloads and builds. You can resolve this by installing DinrusHub
to either the standard prefix for your platform or to a non-standard prefix that
is not in the DinrusHub temporary directory.
EOS
  fi
}

# NOTE: The members of the array in the second arg must not have spaces!
check-array-membership() {
  local item=$1
  shift

  if [[ " ${*} " == *" ${item} "* ]]
  then
    return 0
  else
    return 1
  fi
}

# These variables are set from various DinrusHub scripts.
# shellcheck disable=SC2154
auto-update() {
  [[ -z "${DRXHUB_HELP}" ]] || return
  [[ -z "${DRXHUB_NO_AUTO_UPDATE}" ]] || return
  [[ -z "${DRXHUB_AUTO_UPDATING}" ]] || return
  [[ -z "${DRXHUB_UPDATE_AUTO}" ]] || return
  [[ -z "${DRXHUB_AUTO_UPDATE_CHECKED}" ]] || return

  # If we've checked for updates, we don't need to check again.
  export DRXHUB_AUTO_UPDATE_CHECKED="1"

  if [[ -n "${DRXHUB_AUTO_UPDATE_COMMAND}" ]]
  then
    export DRXHUB_AUTO_UPDATING="1"

    # Look for commands that may be referring to a formula/cask in a specific
    # 3rd-party tap so they can be auto-updated more often (as they do not get
    # their data from the API).
    AUTO_UPDATE_TAP_COMMANDS=(
      install
      outdated
      upgrade
    )
    if check-array-membership "${DRXHUB_COMMAND}" "${AUTO_UPDATE_TAP_COMMANDS[@]}"
    then
      for arg in "$@"
      do
        if [[ "${arg}" == */*/* ]] && [[ "${arg}" != DinrusHub/* ]] && [[ "${arg}" != homebrew/* ]]
        then

          DRXHUB_AUTO_UPDATE_TAP="1"
          break
        fi
      done
    fi

    if [[ -z "${DRXHUB_AUTO_UPDATE_SECS}" ]]
    then
      if [[ -n "${DRXHUB_NO_INSTALL_FROM_API}" || -n "${DRXHUB_AUTO_UPDATE_TAP}" ]]
      then
        # 5 minutes
        DRXHUB_AUTO_UPDATE_SECS="300"
      elif [[ -n "${DRXHUB_DEV_CMD_RUN}" ]]
      then
        # 1 hour
        DRXHUB_AUTO_UPDATE_SECS="3600"
      else
        # 24 hours
        DRXHUB_AUTO_UPDATE_SECS="86400"
      fi
    fi

    repo_fetch_heads=("${DRXHUB_REPOSITORY}/.git/FETCH_HEAD")
    # We might have done an auto-update recently, but not a core/cask clone auto-update.
    # So we check the core/cask clone FETCH_HEAD too.
    if [[ -n "${DRXHUB_AUTO_UPDATE_CORE_TAP}" && -d "${DRXHUB_CORE_REPOSITORY}/.git" ]]
    then
      repo_fetch_heads+=("${DRXHUB_CORE_REPOSITORY}/.git/FETCH_HEAD")
    fi
    if [[ -n "${DRXHUB_AUTO_UPDATE_CASK_TAP}" && -d "${DRXHUB_CASK_REPOSITORY}/.git" ]]
    then
      repo_fetch_heads+=("${DRXHUB_CASK_REPOSITORY}/.git/FETCH_HEAD")
    fi

    # Skip auto-update if all of the selected repositories have been checked in the
    # last $DRXHUB_AUTO_UPDATE_SECS.
    needs_auto_update=
    for repo_fetch_head in "${repo_fetch_heads[@]}"
    do
      if [[ ! -f "${repo_fetch_head}" ]] ||
         [[ -z "$(find "${repo_fetch_head}" -type f -newermt "-${DRXHUB_AUTO_UPDATE_SECS} seconds" 2>/dev/null)" ]]
      then
        needs_auto_update=1
        break
      fi
    done
    if [[ -z "${needs_auto_update}" ]]
    then
      return
    fi

    dhub update --auto-update

    unset DRXHUB_AUTO_UPDATING
    unset DRXHUB_AUTO_UPDATE_TAP

    # exec a new process to set any new environment variables.
    exec "${DRXHUB_BREW_FILE}" "$@"
  fi

  unset AUTO_UPDATE_COMMANDS
  unset AUTO_UPDATE_CORE_TAP_COMMANDS
  unset AUTO_UPDATE_CASK_TAP_COMMANDS
  unset DRXHUB_AUTO_UPDATE_CORE_TAP
  unset DRXHUB_AUTO_UPDATE_CASK_TAP
}

#####
##### Setup output so e.g. odie looks as nice as possible.
#####

# Colorize output on GitHub Actions.
# This is set by the user environment.
# shellcheck disable=SC2154
if [[ -n "${GITHUB_ACTIONS}" ]]
then
  export DRXHUB_COLOR="1"
fi

# Force UTF-8 to avoid encoding issues for users with broken locale settings.
if [[ -n "${DRXHUB_MACOS}" ]]
then
  if [[ "$(locale charmap)" != "UTF-8" ]]
  then
    export LC_ALL="ru_RU.UTF-8"
  fi
else
  if ! command -v locale >/dev/null
  then
    export LC_ALL=C
  elif [[ "$(locale charmap)" != "UTF-8" ]]
  then
    locales="$(locale -a)"
    c_utf_regex='\bC\.(utf8|UTF-8)\b'
    en_us_regex='\bru_RU\.(utf8|UTF-8)\b'
    utf_regex='\b[a-z][a-z]_[A-Z][A-Z]\.(utf8|UTF-8)\b'
    if [[ ${locales} =~ ${c_utf_regex} || ${locales} =~ ${en_us_regex} || ${locales} =~ ${utf_regex} ]]
    then
      export LC_ALL="${BASH_REMATCH[0]}"
    else
      export LC_ALL=C
    fi
  fi
fi

#####
##### odie as quickly as possible.
#####

if [[ "${DRXHUB_PREFIX}" == "/" || "${DRXHUB_PREFIX}" == "/usr" ]]
then
  # it may work, but I only see pain this route and don't want to support it
  odie "Cowardly refusing to continue at this prefix: ${DRXHUB_PREFIX}"
fi

#####
##### Now, do everything else (that may be a bit slower).
#####

# Docker image deprecation
if [[ -f "${DRXHUB_REPOSITORY}/.docker-deprecate" ]]
then
  read -r DOCKER_DEPRECATION_MESSAGE <"${DRXHUB_REPOSITORY}/.docker-deprecate"
  if [[ -n "${GITHUB_ACTIONS}" ]]
  then
    echo "::warning::${DOCKER_DEPRECATION_MESSAGE}" >&2
  else
    opoo "${DOCKER_DEPRECATION_MESSAGE}"
  fi
fi

# USER isn't always set so provide a fall back for `dhub` and subprocesses.
export USER="${USER:-$(id -un)}"

# A depth of 1 means this command was directly invoked by a user.
# Higher depths mean this command was invoked by another DinrusHub command.
export DRXHUB_COMMAND_DEPTH="$((DRXHUB_COMMAND_DEPTH + 1))"

setup_curl() {
  # This is set by the user environment.
  # shellcheck disable=SC2154
  DRXHUB_BREWED_CURL_PATH="${DRXHUB_PREFIX}/opt/curl/bin/curl"
  if [[ -n "${DRXHUB_FORCE_BREWED_CURL}" && -x "${DRXHUB_BREWED_CURL_PATH}" ]] &&
     "${DRXHUB_BREWED_CURL_PATH}" --version &>/dev/null
  then
    DRXHUB_CURL="${DRXHUB_BREWED_CURL_PATH}"
  elif [[ -n "${DRXHUB_CURL_PATH}" ]]
  then
    DRXHUB_CURL="${DRXHUB_CURL_PATH}"
  else
    DRXHUB_CURL="curl"
  fi
}

setup_git() {
  # This is set by the user environment.
  # shellcheck disable=SC2154
  if [[ -n "${DRXHUB_FORCE_BREWED_GIT}" && -x "${DRXHUB_PREFIX}/opt/git/bin/git" ]] &&
     "${DRXHUB_PREFIX}/opt/git/bin/git" --version &>/dev/null
  then
    DRXHUB_GIT="${DRXHUB_PREFIX}/opt/git/bin/git"
  elif [[ -n "${DRXHUB_GIT_PATH}" ]]
  then
    DRXHUB_GIT="${DRXHUB_GIT_PATH}"
  else
    DRXHUB_GIT="git"
  fi
}

setup_curl
setup_git

GIT_DESCRIBE_CACHE="${DRXHUB_REPOSITORY}/.git/describe-cache"
GIT_REVISION=$("${DRXHUB_GIT}" -C "${DRXHUB_REPOSITORY}" rev-parse HEAD 2>/dev/null)

# safe fallback in case git rev-parse fails e.g. if this is not considered a safe git directory
if [[ -z "${GIT_REVISION}" ]]
then
  read -r GIT_HEAD 2>/dev/null <"${DRXHUB_REPOSITORY}/.git/HEAD"
  if [[ "${GIT_HEAD}" == "ref: refs/heads/master" ]]
  then
    read -r GIT_REVISION 2>/dev/null <"${DRXHUB_REPOSITORY}/.git/refs/heads/master"
  elif [[ "${GIT_HEAD}" == "ref: refs/heads/stable" ]]
  then
    read -r GIT_REVISION 2>/dev/null <"${DRXHUB_REPOSITORY}/.git/refs/heads/stable"
  fi
  unset GIT_HEAD
fi

if [[ -n "${GIT_REVISION}" ]]
then
  GIT_DESCRIBE_CACHE_FILE="${GIT_DESCRIBE_CACHE}/${GIT_REVISION}"
  if [[ -r "${GIT_DESCRIBE_CACHE_FILE}" ]] && "${DRXHUB_GIT}" -C "${DRXHUB_REPOSITORY}" diff --quiet --no-ext-diff 2>/dev/null
  then
    read -r GIT_DESCRIBE_CACHE_DRXHUB_VERSION <"${GIT_DESCRIBE_CACHE_FILE}"
    if [[ -n "${GIT_DESCRIBE_CACHE_DRXHUB_VERSION}" && "${GIT_DESCRIBE_CACHE_DRXHUB_VERSION}" != *"-dirty" ]]
    then
      DRXHUB_VERSION="${GIT_DESCRIBE_CACHE_DRXHUB_VERSION}"
    fi
    unset GIT_DESCRIBE_CACHE_DRXHUB_VERSION
  fi

  if [[ -z "${DRXHUB_VERSION}" ]]
  then
    DRXHUB_VERSION="$("${DRXHUB_GIT}" -C "${DRXHUB_REPOSITORY}" describe --tags --dirty --abbrev=7 2>/dev/null)"
    # Don't output any permissions errors here. The user may not have write
    # permissions to the cache but we don't care because it's an optional
    # performance improvement.
    rm -rf "${GIT_DESCRIBE_CACHE}" 2>/dev/null
    mkdir -p "${GIT_DESCRIBE_CACHE}" 2>/dev/null
    echo "${DRXHUB_VERSION}" | tee "${GIT_DESCRIBE_CACHE_FILE}" &>/dev/null
  fi
  unset GIT_DESCRIBE_CACHE_FILE
else
  # Don't care about permission errors here either.
  rm -rf "${GIT_DESCRIBE_CACHE}" 2>/dev/null
fi
unset GIT_REVISION
unset GIT_DESCRIBE_CACHE

DRXHUB_USER_AGENT_VERSION="${DRXHUB_VERSION}"
if [[ -z "${DRXHUB_VERSION}" ]]
then
  DRXHUB_VERSION=">=4.3.0 (shallow or no git repository)"
  DRXHUB_USER_AGENT_VERSION="4.X.Y"
fi

DRXHUB_CORE_REPOSITORY="${DRXHUB_LIBRARY}/Taps/homebrew/homebrew-core"
# Used in --version.sh
# shellcheck disable=SC2034
DRXHUB_CASK_REPOSITORY="${DRXHUB_LIBRARY}/Taps/homebrew/homebrew-cask"

# Shift the -v to the end of the parameter list
if [[ "$1" == "-v" ]]
then
  shift
  set -- "$@" -v
fi

# commands that take a single or no arguments.
# doesn't need a default case as other arguments handled elsewhere.
# shellcheck disable=SC2249
case "$1" in
  --version | -v)
    source "${DRXHUB_LIBRARY}/DinrusHub/cmd/--version.sh"
    homebrew-version
    exit 0
    ;;
esac

# TODO: bump version when new macOS is released or announced and update references in:
# - docs/Installation.md
# - https://github.com/Homebrew/install/blob/HEAD/install.sh
# - Library/DinrusHub/os/mac.rb (latest_sdk_version)
# and, if needed:
# - MacOSVersion::SYMBOLS
DRXHUB_MACOS_NEWEST_UNSUPPORTED="16"
# TODO: bump version when new macOS is released and update references in:
# - docs/Installation.md
# - DRXHUB_MACOS_OLDEST_SUPPORTED in .github/workflows/pkg-installer.yml
# - `os-version min` in package/Distribution.xml
# - https://github.com/Homebrew/install/blob/HEAD/install.sh
DRXHUB_MACOS_OLDEST_SUPPORTED="13"
DRXHUB_MACOS_OLDEST_ALLOWED="10.11"

if [[ -n "${DRXHUB_MACOS}" ]]
then
  DRXHUB_PRODUCT="DinrusHub"
  DRXHUB_SYSTEM="Macintosh"
  [[ "${DRXHUB_PROCESSOR}" == "x86_64" ]] && DRXHUB_PROCESSOR="Intel"
  # Don't change this from Mac OS X to match what macOS itself does in Safari on 10.12
  DRXHUB_OS_USER_AGENT_VERSION="Mac OS X ${DRXHUB_MACOS_VERSION}"

  if [[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" == "1" ]]
  then
    # used in vendor-install.sh
    # shellcheck disable=SC2034
    DRXHUB_PHYSICAL_PROCESSOR="arm64"
  fi

  IFS=. read -r -a MACOS_VERSION_ARRAY <<<"${DRXHUB_MACOS_OLDEST_ALLOWED}"
  printf -v DRXHUB_MACOS_OLDEST_ALLOWED_NUMERIC "%02d%02d%02d" "${MACOS_VERSION_ARRAY[@]}"

  unset MACOS_VERSION_ARRAY

  # Don't include minor versions for Big Sur and later.
  if [[ "${DRXHUB_MACOS_VERSION_NUMERIC}" -gt "110000" ]]
  then
    DRXHUB_OS_VERSION="macOS ${DRXHUB_MACOS_VERSION%.*}"
  else
    DRXHUB_OS_VERSION="macOS ${DRXHUB_MACOS_VERSION}"
  fi

  # Refuse to run on pre-El Capitan
  if [[ "${DRXHUB_MACOS_VERSION_NUMERIC}" -lt "${DRXHUB_MACOS_OLDEST_ALLOWED_NUMERIC}" ]]
  then
    printf "ERROR: Your version of macOS (%s) is too old to run DinrusHub!\\n" "${DRXHUB_MACOS_VERSION}" >&2
    if [[ "${DRXHUB_MACOS_VERSION_NUMERIC}" -lt "100700" ]]
    then
      printf "         For 10.4 - 10.6 support see: https://github.com/mistydemeo/tigerbrew\\n" >&2
    fi
    printf "\\n" >&2
  fi

  # Versions before Sierra don't handle custom cert files correctly, so need a full brewed curl.
  if [[ "${DRXHUB_MACOS_VERSION_NUMERIC}" -lt "101200" ]]
  then
    DRXHUB_SYSTEM_CURL_TOO_OLD="1"
    DRXHUB_FORCE_BREWED_CURL="1"
  fi

  # The system libressl has a bug before macOS 10.15.6 where it incorrectly handles expired roots.
  if [[ -z "${DRXHUB_SYSTEM_CURL_TOO_OLD}" && "${DRXHUB_MACOS_VERSION_NUMERIC}" -lt "101506" ]]
  then
    DRXHUB_SYSTEM_CA_CERTIFICATES_TOO_OLD="1"
    DRXHUB_FORCE_BREWED_CA_CERTIFICATES="1"
  fi

  # TEMP: backwards compatiblity with existing 10.11-cross image
  # Can (probably) be removed in March 2024.
  if [[ -n "${DRXHUB_FAKE_EL_CAPITAN}" ]]
  then
    export DRXHUB_FAKE_MACOS="10.11.6"
  fi

  if [[ "${DRXHUB_FAKE_MACOS}" =~ ^10\.11(\.|$) ]]
  then
    # We only need this to work enough to update dhub and build the set portable formulae, so relax the requirement.
    DRXHUB_MINIMUM_GIT_VERSION="2.7.4"
  else
    # The system Git on macOS versions before Sierra is too old for some DinrusHub functionality we rely on.
    DRXHUB_MINIMUM_GIT_VERSION="2.14.3"
    if [[ "${DRXHUB_MACOS_VERSION_NUMERIC}" -lt "101200" ]]
    then
      DRXHUB_FORCE_BREWED_GIT="1"
    fi
  fi
else
  DRXHUB_PRODUCT="${DRXHUB_SYSTEM}dhub"
  # Don't try to follow /etc/os-release
  # shellcheck disable=SC1091,SC2154
  [[ -n "${DRXHUB_LINUX}" ]] && DRXHUB_OS_VERSION="$(source /etc/os-release && echo "${PRETTY_NAME}")"
  : "${DRXHUB_OS_VERSION:=$(uname -r)}"
  DRXHUB_OS_USER_AGENT_VERSION="${DRXHUB_OS_VERSION}"

  # Ensure the system Curl is a version that supports modern HTTPS certificates.
  DRXHUB_MINIMUM_CURL_VERSION="7.41.0"

  curl_version_output="$(${DRXHUB_CURL} --version 2>/dev/null)"
  curl_name_and_version="${curl_version_output%% (*}"
  if [[ "$(numeric "${curl_name_and_version##* }")" -lt "$(numeric "${DRXHUB_MINIMUM_CURL_VERSION}")" ]]
  then
    message="Please update your system curl or set DRXHUB_CURL_PATH to a newer version.
Minimum required version: ${DRXHUB_MINIMUM_CURL_VERSION}
Your curl version: ${curl_name_and_version##* }
Your curl executable: $(type -p "${DRXHUB_CURL}")"

    if [[ -z ${DRXHUB_CURL_PATH} ]]
    then
      DRXHUB_SYSTEM_CURL_TOO_OLD=1
      DRXHUB_FORCE_BREWED_CURL=1
      if [[ -z ${DRXHUB_CURL_WARNING} ]]
      then
        onoe "${message}"
        DRXHUB_CURL_WARNING=1
      fi
    else
      odie "${message}"
    fi
  fi

  # Ensure the system Git is at or newer than the minimum required version.
  # Git 2.7.4 is the version of git on Ubuntu 16.04 LTS (Xenial Xerus).
  DRXHUB_MINIMUM_GIT_VERSION="2.7.0"
  git_version_output="$(${DRXHUB_GIT} --version 2>/dev/null)"
  # $extra is intentionally discarded.
  # shellcheck disable=SC2034
  DRXHUB_FORCE_BREWED_GIT="1"

  DRXHUB_LINUX_MINIMUM_GLIBC_VERSION="2.13"

  DRXHUB_CORE_REPOSITORY_ORIGIN="$("${DRXHUB_GIT}" -C "${DRXHUB_CORE_REPOSITORY}" remote get-url origin 2>/dev/null)"
  if [[ "${DRXHUB_CORE_REPOSITORY_ORIGIN}" =~ (/linuxbrew|Linuxbrew/homebrew)-core(\.git)?$ ]]
  then
    # triggers migration code in update.sh
    # shellcheck disable=SC2034
    DRXHUB_LINUXBREW_CORE_MIGRATION=1
  fi
fi

setup_ca_certificates() {
  if [[ -n "${DRXHUB_FORCE_BREWED_CA_CERTIFICATES}" && -f "${DRXHUB_PREFIX}/etc/ca-certificates/cert.pem" ]]
  then
    export SSL_CERT_FILE="${DRXHUB_PREFIX}/etc/ca-certificates/cert.pem"
    export GIT_SSL_CAINFO="${DRXHUB_PREFIX}/etc/ca-certificates/cert.pem"
    export GIT_SSL_CAPATH="${DRXHUB_PREFIX}/etc/ca-certificates"
  fi
}
setup_ca_certificates

# Redetermine curl and git paths as we may have forced some options above.
setup_curl
setup_git

# A bug in the auto-update process prior to 3.1.2 means $DRXHUB_BOTTLE_DOMAIN
# could be passed down with the default domain.
# This is problematic as this is will be the old bottle domain.
# This workaround is necessary for many CI images starting on old version,
# and will only be unnecessary when updating from <3.1.2 is not a concern.
# That will be when macOS 12 is the minimum required version.
# DRXHUB_BOTTLE_DOMAIN is set from the user environment
# shellcheck disable=SC2154
if [[ -n "${DRXHUB_BOTTLE_DEFAULT_DOMAIN}" ]] &&
   [[ "${DRXHUB_BOTTLE_DOMAIN}" == "${DRXHUB_BOTTLE_DEFAULT_DOMAIN}" ]]
then
  unset DRXHUB_BOTTLE_DOMAIN
fi

DRXHUB_API_DEFAULT_DOMAIN="https://formulae.brew.sh/api"
DRXHUB_BOTTLE_DEFAULT_DOMAIN="https://ghcr.io/v2/homebrew/core"

DRXHUB_USER_AGENT="${DRXHUB_PRODUCT}/${DRXHUB_USER_AGENT_VERSION} (${DRXHUB_SYSTEM}; ${DRXHUB_PROCESSOR} ${DRXHUB_OS_USER_AGENT_VERSION})"
curl_version_output="$(curl --version 2>/dev/null)"
curl_name_and_version="${curl_version_output%% (*}"
DRXHUB_USER_AGENT_CURL="${DRXHUB_USER_AGENT} ${curl_name_and_version// //}"

# Timeout values to check for dead connections
# We don't use --max-time to support slow connections
DRXHUB_CURL_SPEED_LIMIT=100
DRXHUB_CURL_SPEED_TIME=5

export DRXHUB_HELP_MESSAGE
export DRXHUB_VERSION
export DRXHUB_MACOS_ARM_DEFAULT_PREFIX
export DRXHUB_LINUX_DEFAULT_PREFIX
export DRXHUB_GENERIC_DEFAULT_PREFIX
export DRXHUB_DEFAULT_PREFIX
export DRXHUB_MACOS_ARM_DEFAULT_REPOSITORY
export DRXHUB_LINUX_DEFAULT_REPOSITORY
export DRXHUB_GENERIC_DEFAULT_REPOSITORY
export DRXHUB_DEFAULT_REPOSITORY
export DRXHUB_DEFAULT_CACHE
export DRXHUB_CACHE
export DRXHUB_DEFAULT_LOGS
export DRXHUB_LOGS
export DRXHUB_DEFAULT_TEMP
export DRXHUB_TEMP
export DRXHUB_CELLAR
export DRXHUB_CASKROOM
export DRXHUB_SYSTEM
export DRXHUB_SYSTEM_CA_CERTIFICATES_TOO_OLD
export DRXHUB_CURL
export DRXHUB_BREWED_CURL_PATH
export DRXHUB_CURL_WARNING
export DRXHUB_SYSTEM_CURL_TOO_OLD
export DRXHUB_GIT
export DRXHUB_GIT_WARNING
export DRXHUB_MINIMUM_GIT_VERSION
export DRXHUB_LINUX_MINIMUM_GLIBC_VERSION
export DRXHUB_PHYSICAL_PROCESSOR
export DRXHUB_PROCESSOR
export DRXHUB_PRODUCT
export DRXHUB_OS_VERSION
export DRXHUB_MACOS_VERSION
export DRXHUB_MACOS_VERSION_NUMERIC
export DRXHUB_MACOS_NEWEST_UNSUPPORTED
export DRXHUB_MACOS_OLDEST_SUPPORTED
export DRXHUB_MACOS_OLDEST_ALLOWED
export DRXHUB_USER_AGENT
export DRXHUB_USER_AGENT_CURL
export DRXHUB_API_DEFAULT_DOMAIN
export DRXHUB_BOTTLE_DEFAULT_DOMAIN
export DRXHUB_CURL_SPEED_LIMIT
export DRXHUB_CURL_SPEED_TIME

if [[ -n "${DRXHUB_MACOS}" && -x "/usr/bin/xcode-select" ]]
then
  XCODE_SELECT_PATH="$('/usr/bin/xcode-select' --print-path 2>/dev/null)"
  if [[ "${XCODE_SELECT_PATH}" == "/" ]]
  then
    odie <<EOS
Your xcode-select path is currently set to '/'.
This causes the 'xcrun' tool to hang, and can render DinrusHub unusable.
If you are using Xcode, you should:
  sudo xcode-select --switch /Applications/Xcode.app
Otherwise, you should:
  sudo rm -rf /usr/share/xcode-select
EOS
  fi

  # Don't check xcrun if Xcode and the CLT aren't installed, as that opens
  # a popup window asking the user to install the CLT
  if [[ -n "${XCODE_SELECT_PATH}" ]]
  then
    # TODO: this is fairly slow, figure out if there's a faster way.
    XCRUN_OUTPUT="$(/usr/bin/xcrun clang 2>&1)"
    XCRUN_STATUS="$?"

    if [[ "${XCRUN_STATUS}" -ne 0 && "${XCRUN_OUTPUT}" == *license* ]]
    then
      odie <<EOS
You have not agreed to the Xcode license. Please resolve this by running:
  sudo xcodebuild -license accept
EOS
    fi
  fi
fi

for arg in "$@"
do
  [[ "${arg}" == "--" ]] && break

  if [[ "${arg}" == "--help" || "${arg}" == "-h" || "${arg}" == "--usage" || "${arg}" == "-?" ]]
  then
    export DRXHUB_HELP="1"
    break
  fi
done

DRXHUB_ARG_COUNT="$#"
DRXHUB_COMMAND="$1"
shift
# If you are going to change anything in below case statement,
# be sure to also update DRXHUB_INTERNAL_COMMAND_ALIASES hash in commands.rb
# doesn't need a default case as other arguments handled elsewhere.
# shellcheck disable=SC2249
case "${DRXHUB_COMMAND}" in
  ls) DRXHUB_COMMAND="list" ;;
  homepage) DRXHUB_COMMAND="home" ;;
  -S) DRXHUB_COMMAND="search" ;;
  up) DRXHUB_COMMAND="update" ;;
  ln) DRXHUB_COMMAND="link" ;;
  instal) DRXHUB_COMMAND="install" ;; # gem does the same
  uninstal) DRXHUB_COMMAND="uninstall" ;;
  post_install) DRXHUB_COMMAND="postinstall" ;;
  rm) DRXHUB_COMMAND="uninstall" ;;
  remove) DRXHUB_COMMAND="uninstall" ;;
  abv) DRXHUB_COMMAND="info" ;;
  dr) DRXHUB_COMMAND="doctor" ;;
  --repo) DRXHUB_COMMAND="--repository" ;;
  environment) DRXHUB_COMMAND="--env" ;;
  --config) DRXHUB_COMMAND="config" ;;
  -v) DRXHUB_COMMAND="--version" ;;
  lc) DRXHUB_COMMAND="livecheck" ;;
  tc) DRXHUB_COMMAND="typecheck" ;;
esac

# Set DRXHUB_DEV_CMD_RUN for users who have run a development command.
# This makes them behave like DRXHUB_DEVELOPERs for dhub update.
if [[ -z "${DRXHUB_DEVELOPER}" ]]
then
  export DRXHUB_GIT_CONFIG_FILE="${DRXHUB_REPOSITORY}/.git/config"
  DRXHUB_GIT_CONFIG_DEVELOPERMODE="$(git config --file="${DRXHUB_GIT_CONFIG_FILE}" --get homebrew.devcmdrun 2>/dev/null)"
  if [[ "${DRXHUB_GIT_CONFIG_DEVELOPERMODE}" == "true" ]]
  then
    export DRXHUB_DEV_CMD_RUN="1"
  fi

  # Don't allow non-developers to customise Ruby warnings.
  unset DRXHUB_RUBY_WARNINGS
fi

unset DRXHUB_AUTO_UPDATE_COMMAND

# Check for commands that should call `dhub update --auto-update` first.
AUTO_UPDATE_COMMANDS=(
  install
  outdated
  upgrade
  bundle
  release
)
if check-array-membership "${DRXHUB_COMMAND}" "${AUTO_UPDATE_COMMANDS[@]}" ||
   [[ "${DRXHUB_COMMAND}" == "tap" && "${DRXHUB_ARG_COUNT}" -gt 1 ]]
then
  export DRXHUB_AUTO_UPDATE_COMMAND="1"
fi

# Check for commands that should auto-update the homebrew-core tap.
AUTO_UPDATE_CORE_TAP_COMMANDS=(
  bump
  bump-formula-pr
)
if check-array-membership "${DRXHUB_COMMAND}" "${AUTO_UPDATE_CORE_TAP_COMMANDS[@]}"
then
  export DRXHUB_AUTO_UPDATE_COMMAND="1"
  export DRXHUB_AUTO_UPDATE_CORE_TAP="1"
elif [[ -z "${DRXHUB_AUTO_UPDATING}" ]]
then
  unset DRXHUB_AUTO_UPDATE_CORE_TAP
fi

# Check for commands that should auto-update the homebrew-cask tap.
AUTO_UPDATE_CASK_TAP_COMMANDS=(
  bump
  bump-cask-pr
  bump-unversioned-casks
)
if check-array-membership "${DRXHUB_COMMAND}" "${AUTO_UPDATE_CASK_TAP_COMMANDS[@]}"
then
  export DRXHUB_AUTO_UPDATE_COMMAND="1"
  export DRXHUB_AUTO_UPDATE_CASK_TAP="1"
elif [[ -z "${DRXHUB_AUTO_UPDATING}" ]]
then
  unset DRXHUB_AUTO_UPDATE_CASK_TAP
fi

if [[ -z "${DRXHUB_RUBY_WARNINGS}" ]]
then
  export DRXHUB_RUBY_WARNINGS="-W1"
fi

export DRXHUB_BREW_DEFAULT_GIT_REMOTE="https://github.com/Homebrew/brew"
if [[ -z "${DRXHUB_BREW_GIT_REMOTE}" ]]
then
  DRXHUB_BREW_GIT_REMOTE="${DRXHUB_BREW_DEFAULT_GIT_REMOTE}"
fi
export DRXHUB_BREW_GIT_REMOTE

export DRXHUB_CORE_DEFAULT_GIT_REMOTE="https://github.com/Homebrew/homebrew-core"
if [[ -z "${DRXHUB_CORE_GIT_REMOTE}" ]]
then
  DRXHUB_CORE_GIT_REMOTE="${DRXHUB_CORE_DEFAULT_GIT_REMOTE}"
fi
export DRXHUB_CORE_GIT_REMOTE

# Set DRXHUB_DEVELOPER_COMMAND if the command being run is a developer command
unset DRXHUB_DEVELOPER_COMMAND
if [[ -f "${DRXHUB_LIBRARY}/DinrusHub/dev-cmd/${DRXHUB_COMMAND}.sh" ]] ||
   [[ -f "${DRXHUB_LIBRARY}/DinrusHub/dev-cmd/${DRXHUB_COMMAND}.rb" ]]
then
  export DRXHUB_DEVELOPER_COMMAND="1"
fi

# Provide a (temporary, undocumented) way to disable Sorbet globally if needed
# to avoid reverting the above.
if [[ -n "${DRXHUB_NO_SORBET_RUNTIME}" ]]
then
  unset DRXHUB_SORBET_RUNTIME
fi

if [[ -n "${DRXHUB_DEVELOPER_COMMAND}" && -z "${DRXHUB_DEVELOPER}" ]]
then
  if [[ -z "${DRXHUB_DEV_CMD_RUN}" ]]
  then
    opoo <<EOS
$(bold "${DRXHUB_COMMAND}") is a developer command, so DinrusHub's
developer mode has been automatically turned on.
To turn developer mode off, run:
  dhub developer off

EOS
  fi

  git config --file="${DRXHUB_GIT_CONFIG_FILE}" --replace-all homebrew.devcmdrun true 2>/dev/null
  export DRXHUB_DEV_CMD_RUN="1"
fi

if [[ -n "${DRXHUB_DEVELOPER}" || -n "${DRXHUB_DEV_CMD_RUN}" ]]
then
  # Always run with Sorbet for DinrusHub developers or when a DinrusHub developer command has been run.
  export DRXHUB_SORBET_RUNTIME="1"
fi

if [[ -f "${DRXHUB_LIBRARY}/DinrusHub/cmd/${DRXHUB_COMMAND}.sh" ]]
then
  DRXHUB_BASH_COMMAND="${DRXHUB_LIBRARY}/DinrusHub/cmd/${DRXHUB_COMMAND}.sh"
elif [[ -f "${DRXHUB_LIBRARY}/DinrusHub/dev-cmd/${DRXHUB_COMMAND}.sh" ]]
then
  DRXHUB_BASH_COMMAND="${DRXHUB_LIBRARY}/DinrusHub/dev-cmd/${DRXHUB_COMMAND}.sh"
fi

check-run-command-as-root

check-prefix-is-not-tmpdir

if [[ "${DRXHUB_PREFIX}" == "/usr/local" ]] &&
   [[ "${DRXHUB_PREFIX}" != "${DRXHUB_REPOSITORY}" ]] &&
   [[ "${DRXHUB_CELLAR}" == "${DRXHUB_REPOSITORY}/Cellar" ]]
then
  cat >&2 <<EOS
Warning: your DRXHUB_PREFIX is set to /usr/local but DRXHUB_CELLAR is set
to ${DRXHUB_CELLAR}. Your current DRXHUB_CELLAR location will stop
you being able to use all the binary packages (bottles) DinrusHub provides. We
recommend you move your DRXHUB_CELLAR to /usr/local/Cellar which will get you
access to all bottles.
EOS
fi

source "${DRXHUB_LIBRARY}/DinrusHub/utils/analytics.sh"
setup-analytics

# Use this configuration file instead of ~/.ssh/config when fetching git over SSH.
if [[ -n "${DRXHUB_SSH_CONFIG_PATH}" ]]
then
  export GIT_SSH_COMMAND="ssh -F${DRXHUB_SSH_CONFIG_PATH}"
fi

if [[ -n "${DRXHUB_DOCKER_REGISTRY_TOKEN}" ]]
then
  export DRXHUB_GITHUB_PACKAGES_AUTH="Bearer ${DRXHUB_DOCKER_REGISTRY_TOKEN}"
elif [[ -n "${DRXHUB_DOCKER_REGISTRY_BASIC_AUTH_TOKEN}" ]]
then
  export DRXHUB_GITHUB_PACKAGES_AUTH="Basic ${DRXHUB_DOCKER_REGISTRY_BASIC_AUTH_TOKEN}"
else
  export DRXHUB_GITHUB_PACKAGES_AUTH="Bearer QQ=="
fi

if [[ -n "${DRXHUB_BASH_COMMAND}" ]]
then
  # source rather than executing directly to ensure the entire file is read into
  # memory before it is run. This makes running a Bash script behave more like
  # a Ruby script and avoids hard-to-debug issues if the Bash script is updated
  # at the same time as being run.
  #
  # Shellcheck can't follow this dynamic `source`.
  # shellcheck disable=SC1090
  source "${DRXHUB_BASH_COMMAND}"

  {
    auto-update "$@"
    "homebrew-${DRXHUB_COMMAND}" "$@"
    exit $?
  }

else
  source "${DRXHUB_LIBRARY}/DinrusHub/utils/ruby.sh"
  setup-ruby-path

  # Unshift command back into argument list (unless argument list was empty).
  [[ "${DRXHUB_ARG_COUNT}" -gt 0 ]] && set -- "${DRXHUB_COMMAND}" "$@"
  # DRXHUB_RUBY_PATH set by utils/ruby.sh
  # shellcheck disable=SC2154
  {
    auto-update "$@"
    exec "${DRXHUB_RUBY_PATH}" "${DRXHUB_RUBY_WARNINGS}" "${DRXHUB_RUBY_DISABLE_OPTIONS}" \
      "${DRXHUB_LIBRARY}/DinrusHub/dhub.rb" "$@"
  }
fi
