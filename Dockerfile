ARG version=22.04
# version is passed through by Docker.
# shellcheck disable=SC2154
FROM ubuntu:"${version}"
ARG DEBIAN_FRONTEND=noninteractive

# Deterministic UID (first user). Helps with docker build cache
ENV USER_ID=1000
# Delete the default ubuntu user & group UID=1000 GID=1000 in Ubuntu 23.04+
# that conflicts with the linuxbrew user
RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu; true

# We don't want to manually pin versions, happy to use whatever
# Ubuntu thinks is best.
# hadolint ignore=DL3008

# `gh` installation taken from https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
# /etc/lsb-release is checked inside the container and sets DISTRIB_RELEASE.
# We need `[` instead of `[[` because the shell is `/bin/sh`.
# shellcheck disable=SC1091,SC2154,SC2292
RUN apt-get update \
  && apt-get install -y --no-install-recommends software-properties-common gnupg-agent \
  && add-apt-repository -y ppa:git-core/ppa \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  acl \
  bzip2 \
  ca-certificates \
  curl \
  file \
  fonts-dejavu-core \
  g++ \
  gawk \
  git \
  gpg \
  less \
  locales \
  make \
  netbase \
  openssh-client \
  patch \
  sudo \
  unzip \
  uuid-runtime \
  tzdata \
  jq \
  && if [ "$(. /etc/lsb-release; echo "${DISTRIB_RELEASE}" | cut -d. -f1)" -ge 22 ]; then apt-get install -y --no-install-recommends skopeo; fi \
  && mkdir -p /etc/apt/keyrings \
  && chmod 0755 /etc /etc/apt /etc/apt/keyrings \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null \
  && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
  && apt-get update \
  && apt-get install -y --no-install-recommends gh \
  && apt-get remove --purge -y software-properties-common \
  && apt-get autoremove --purge -y \
  && rm -rf /var/lib/apt/lists/* \
  && sed -i -E 's/^(USERGROUPS_ENAB\s+)yes$/\1no/' /etc/login.defs \
  && localedef -i en_US -f UTF-8 en_US.UTF-8 \
  && useradd -u "${USER_ID}" --create-home --shell /bin/bash --user-group dinrusbrew \
  && echo 'dinrusbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers \
  && su - dinrusbrew -c 'mkdir ~/.drx'

USER linuxbrew
COPY --chown=linuxbrew:linuxbrew . /home/drx/.drx/DinrusHub
ENV PATH="/home/drx/.drx/bin:/home/drx/.drx/sbin:${PATH}" \
  XDG_CACHE_HOME=/home/drx/.cache
WORKDIR /home/linuxbrew


RUN --mount=type=cache,target=/tmp/homebrew-core,uid="${USER_ID}",sharing=locked \
    # Clone the homebre-core repo into /tmp/homebrew-core or pull latest changes if it exists
    git clone https://github.com/homebrew/homebrew-core /tmp/homebrew-core || { cd /tmp/homebrew-core && git pull; } \
    && mkdir -p /home/drx/.drx/DinrusHub/Library/Taps/homebrew/homebrew-core \
    && cp -r /tmp/homebrew-core /home/drx/.drx/DinrusHub/Library/Taps/homebrew/


RUN --mount=type=cache,target=/home/drx/.cache,uid="${USER_ID}" \
   --mount=type=cache,target=/home/drx/.bundle,uid="${USER_ID}" \
   mkdir -p \
  .drx/bin \
  .drx/etc \
  .drx/include \
  .drx/lib \
  .drx/opt \
  .drx/sbin \
  .drx/share \
  .drx/var/dinrusbrew/linked \
  .drx/Cellar \
  && ln -s ../DinrusHub/bin/dhub .drx/bin/dhub \
  && git -C .drx/DinrusHub remote set-url origin https://github.com/Homebrew/brew \
  && git -C .drx/DinrusHub fetch origin \
  && DRXHUB_NO_ANALYTICS=1 DRXHUB_NO_AUTO_UPDATE=1 dhub tap --force dinrusbrew/core \
  && dhub install-bundler-gems --groups=all \
  && dhub cleanup \
  && { git -C .drx/DinrusHub config --unset gc.auto; true; } \
  && { git -C .drx/DinrusHub config --unset homebrew.devcmdrun; true; } \
  && touch .drx/.dinrusbrewdocker
