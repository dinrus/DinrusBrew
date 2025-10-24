# Documentation defined in Library/DinrusHub/cmd/shellenv.rb

# DRXHUB_CELLAR and DRXHUB_PREFIX are set by extend/ENV/super.rb
# DRXHUB_REPOSITORY is set by bin/dhub
# Leading colon in MANPATH prepends default man dirs to search path in Linux and macOS.
# Please do not submit PRs to remove it!
# shellcheck disable=SC2154
homebrew-shellenv() {
  if [[ "${DRXHUB_PATH%%:"${DRXHUB_PREFIX}"/sbin*}" == "${DRXHUB_PREFIX}/bin" ]]
  then
    return
  fi

  if [[ -n "$1" ]]
  then
    DRXHUB_SHELL_NAME="$1"
  else
    DRXHUB_SHELL_NAME="$(/bin/ps -p "${PPID}" -c -o comm=)"
  fi

  if [[ -n "${DRXHUB_MACOS}" ]] &&
     [[ "${DRXHUB_MACOS_VERSION_NUMERIC}" -ge "140000" ]] &&
     [[ -x /usr/libexec/path_helper ]]
  then
    DRXHUB_PATHS_FILE="${DRXHUB_PREFIX}/etc/paths"

    if [[ ! -f "${DRXHUB_PATHS_FILE}" ]]
    then
      printf '%s/bin\n%s/sbin\n' "${DRXHUB_PREFIX}" "${DRXHUB_PREFIX}" 2>/dev/null >"${DRXHUB_PATHS_FILE}"
    fi

    if [[ -r "${DRXHUB_PATHS_FILE}" ]]
    then
      PATH_HELPER_ROOT="${DRXHUB_PREFIX}"
    fi
  fi

  case "${DRXHUB_SHELL_NAME}" in
    fish | -fish)
      echo "set --global --export DRXHUB_PREFIX \"${DRXHUB_PREFIX}\";"
      echo "set --global --export DRXHUB_CELLAR \"${DRXHUB_CELLAR}\";"
      echo "set --global --export DRXHUB_REPOSITORY \"${DRXHUB_REPOSITORY}\";"
      echo "fish_add_path --global --move --path \"${DRXHUB_PREFIX}/bin\" \"${DRXHUB_PREFIX}/sbin\";"
      echo "if test -n \"\$MANPATH[1]\"; set --global --export MANPATH '' \$MANPATH; end;"
      echo "if not contains \"${DRXHUB_PREFIX}/share/info\" \$INFOPATH; set --global --export INFOPATH \"${DRXHUB_PREFIX}/share/info\" \$INFOPATH; end;"
      ;;
    csh | -csh | tcsh | -tcsh)
      echo "setenv DRXHUB_PREFIX ${DRXHUB_PREFIX};"
      echo "setenv DRXHUB_CELLAR ${DRXHUB_CELLAR};"
      echo "setenv DRXHUB_REPOSITORY ${DRXHUB_REPOSITORY};"
      if [[ -n "${PATH_HELPER_ROOT}" ]]
      then
        PATH_HELPER_ROOT="${PATH_HELPER_ROOT}" PATH="${DRXHUB_PATH}" /usr/libexec/path_helper -c
      else
        echo "setenv PATH ${DRXHUB_PREFIX}/bin:${DRXHUB_PREFIX}/sbin:\$PATH;"
      fi
      echo "test \${?MANPATH} -eq 1 && setenv MANPATH :\${MANPATH};"
      echo "setenv INFOPATH ${DRXHUB_PREFIX}/share/info\`test \${?INFOPATH} -eq 1 && echo :\${INFOPATH}\`;"
      ;;
    pwsh | -pwsh | pwsh-preview | -pwsh-preview)
      echo "[System.Environment]::SetEnvironmentVariable('DRXHUB_PREFIX','${DRXHUB_PREFIX}',[System.EnvironmentVariableTarget]::Process)"
      echo "[System.Environment]::SetEnvironmentVariable('DRXHUB_CELLAR','${DRXHUB_CELLAR}',[System.EnvironmentVariableTarget]::Process)"
      echo "[System.Environment]::SetEnvironmentVariable('DRXHUB_REPOSITORY','${DRXHUB_REPOSITORY}',[System.EnvironmentVariableTarget]::Process)"
      echo "[System.Environment]::SetEnvironmentVariable('PATH',\$('${DRXHUB_PREFIX}/bin:${DRXHUB_PREFIX}/sbin:'+\$ENV:PATH),[System.EnvironmentVariableTarget]::Process)"
      echo "[System.Environment]::SetEnvironmentVariable('MANPATH',\$('${DRXHUB_PREFIX}/share/man'+\$(if(\${ENV:MANPATH}){':'+\${ENV:MANPATH}})+':'),[System.EnvironmentVariableTarget]::Process)"
      echo "[System.Environment]::SetEnvironmentVariable('INFOPATH',\$('${DRXHUB_PREFIX}/share/info'+\$(if(\${ENV:INFOPATH}){':'+\${ENV:INFOPATH}})),[System.EnvironmentVariableTarget]::Process)"
      ;;
    *)
      echo "export DRXHUB_PREFIX=\"${DRXHUB_PREFIX}\";"
      echo "export DRXHUB_CELLAR=\"${DRXHUB_CELLAR}\";"
      echo "export DRXHUB_REPOSITORY=\"${DRXHUB_REPOSITORY}\";"
      if [[ "${DRXHUB_SHELL_NAME}" == "zsh" ]] || [[ "${DRXHUB_SHELL_NAME}" == "-zsh" ]]
      then
        echo "fpath[1,0]=\"${DRXHUB_PREFIX}/share/zsh/site-functions\";"
      fi
      if [[ -n "${PATH_HELPER_ROOT}" ]]
      then
        PATH_HELPER_ROOT="${PATH_HELPER_ROOT}" PATH="${DRXHUB_PATH}" /usr/libexec/path_helper -s
      else
        echo "export PATH=\"${DRXHUB_PREFIX}/bin:${DRXHUB_PREFIX}/sbin\${PATH+:\$PATH}\";"
      fi
      echo "[ -z \"\${MANPATH-}\" ] || export MANPATH=\":\${MANPATH#:}\";"
      echo "export INFOPATH=\"${DRXHUB_PREFIX}/share/info:\${INFOPATH:-}\";"
      ;;
  esac
}
