#:  * `help`
#:
#:  Outputs the usage instructions for `dhub`.
#:

# NOTE: Keep the length of vanilla `--help` less than 25 lines!
#       This is because the default Terminal height is 25 lines. Scrolling sucks
#       and concision is important. If more help is needed we should start
#       specialising help like the gem command does.
# NOTE: Keep lines less than 80 characters! Wrapping is just not cricket.
DRXHUB_HELP_MESSAGE=$(
  cat <<'EOS'
Пример использования:
  dhub search TEXT|/REGEX/
  dhub info [FORMULA|CASK...]
  dhub install FORMULA|CASK...
  dhub update
  dhub upgrade [FORMULA|CASK...]
  dhub uninstall FORMULA|CASK...
  dhub list [FORMULA|CASK...]

Решение проблем:
  dhub config
  dhub doctor
  dhub install --verbose --debug FORMULA|CASK

Внесение вклада:
  dhub create URL [--no-fetch]
  dhub edit [FORMULA|CASK...]

Дальнейшая помощь:
  dhub commands
  dhub help [COMMAND]
  man dhub
  https://docs.brew.sh
EOS
)

homebrew-help() {
  if [[ -z "$*" ]]
  then
    echo "${DRXHUB_HELP_MESSAGE}" >&2
    exit 1
  fi

  echo "${DRXHUB_HELP_MESSAGE}"
  return 0
}
