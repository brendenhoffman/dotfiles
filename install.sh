#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/.local/git/dotfiles}"

NEED_LINK_DIRS=(
  ".config/fish"
  ".config/environment.d"
  ".config/starship.toml"
  ".config/yay"
)

SCRIPTS_DIR="$REPO_DIR/scripts"
LOCAL_BIN="$HOME/.local/bin"
BACKUP_DIR="$REPO_DIR/.backup-$(date +%Y%m%d-%H%M%S)"

# Mirror the XDG locations declared in conf.d/00-env.fish
CARGO_HOME="${CARGO_HOME:-$HOME/.local/share/cargo}"
RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.local/share/rustup}"
export CARGO_HOME RUSTUP_HOME

have()    { command -v "$1" >/dev/null 2>&1; }
sudo_do() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }
msg()     { printf "\033[1;36m==>\033[0m %s\n" "$*"; }
warn()    { printf "\033[1;33m!!\033[0m %s\n" "$*"; }
err()     { printf 'ERROR: %s\n' "$*" >&2; }
ask() {
  local p="${1:-Proceed?} [Y/n] "
  read -rp "$p" a || true
  case "${a,,}" in y|yes|"") return 0 ;; *) return 1 ;; esac
}

# ── Git ───────────────────────────────────────────────────────────────
ensure_git_early() {
  have git && return
  if have pacman; then
    msg "Installing git (pacman)"
    sudo_do pacman -S --needed --noconfirm git base-devel
  elif have apt-get; then
    msg "Installing git (apt)"
    sudo_do apt-get update -qq
    sudo_do apt-get install -y git
  elif have dnf; then
    msg "Installing git (dnf)"
    sudo_do dnf install -y git
  elif have apk; then
    msg "Installing git (apk)"
    sudo_do apk add --no-cache git
  else
    warn "No known package manager; please install git manually."
  fi
}

# ── Repo ──────────────────────────────────────────────────────────────
ensure_repo() {
  local remote="${DOTFILES_REMOTE:-https://github.com/brendenhoffman/dotfiles.git}"
  local branch="${DOTFILES_BRANCH:-fish-migration}"

  if [ ! -d "$REPO_DIR/.git" ]; then
    msg "Cloning dotfiles into $REPO_DIR"
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone --branch "$branch" "$remote" "$REPO_DIR" || { err "Clone failed"; exit 1; }
    return
  fi

  msg "Repo exists at $REPO_DIR"
  if [ -n "$(git -C "$REPO_DIR" status --porcelain)" ]; then
    warn "Local changes detected in $REPO_DIR"
    if ask "Stash local changes and update from origin/$branch?"; then
      (cd "$REPO_DIR" && git stash push -u -m "install.sh auto-stash $(date -Iseconds)") || true
    else
      err "Aborting. Resolve local changes, then re-run."
      exit 1
    fi
  fi

  msg "Updating repo (origin/$branch)"
  git -C "$REPO_DIR" fetch --prune --tags || warn "Fetch failed; attempting pull anyway"
  git -C "$REPO_DIR" checkout -q "$branch" 2>/dev/null || git -C "$REPO_DIR" checkout -qb "$branch"
  if ! git -C "$REPO_DIR" pull --ff-only origin "$branch"; then
    err "Non-fast-forward or update failed; resolve manually and re-run."
    exit 1
  fi
}

# ── Symlinks ──────────────────────────────────────────────────────────
backup_if_needed() {
  local path="$1"
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    local rel="${path#$HOME/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$path" "$BACKUP_DIR/$rel"
    msg "Backed up ~/$rel -> $BACKUP_DIR/$rel"
  fi
}

link_into_home() {
  local rel="$1"
  local src="$REPO_DIR/$rel"
  local dest="$HOME/${rel#./}"
  if [ ! -e "$src" ]; then warn "Skip: $rel (missing in repo)"; return; fi
  mkdir -p "$(dirname "$dest")"
  backup_if_needed "$dest"
  ln -sfn "$src" "$dest"
  msg "Linked ~/$rel -> $src"
}

# ── Arch ──────────────────────────────────────────────────────────────
# Returns: 0=no updates, 1=updates exist, 2=unknown (no checkupdates)
arch_check_updates() {
  have checkupdates || return 2
  updates=$(checkupdates 2>/dev/null || true)
  [ -z "$updates" ] && return 0
  echo "$updates" | sed 's/^/  /'
  return 1
}

arch_offer_system_upgrade_or_abort() {
  local state
  arch_check_updates; state=$?

  if [ $state -eq 0 ]; then
    msg "No system updates pending; continuing."
    return 0
  fi

  if [ $state -eq 1 ]; then
    msg "Updates are available:"
  else
    warn "Cannot verify updates (pacman-contrib not installed). Full upgrade required."
  fi

  if ask "Run a full system upgrade now?"; then
    if have yay; then
      sudo_do pacman -Sy --noconfirm archlinux-keyring || true
      yay -Syu || return 1
    else
      sudo_do pacman -Sy --noconfirm archlinux-keyring || true
      sudo_do pacman -Syu || return 1
    fi
    return 0
  else
    err "Refusing to continue Arch package installs without a full upgrade."
    return 1
  fi
}

arch_setup_chaotic_and_yay() {
  have pacman || return
  if grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null; then
    msg "chaotic-aur already enabled"
  else
    if ask "Enable chaotic-aur repository?"; then
      sudo_do pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || true
      sudo_do pacman-key --lsign-key 3056513887B78AEB || true
      if ! sudo_do pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'; then
        warn "Could not install chaotic keyring/mirrorlist"
      fi
      sudo_do tee -a /etc/pacman.conf >/dev/null <<'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
      msg "chaotic-aur enabled"
      sudo_do pacman -Sy
    else
      warn "Skipped chaotic-aur"
    fi
  fi

  if ! have yay; then
    if sudo_do pacman -S --needed --noconfirm yay 2>/dev/null; then
      msg "yay installed (chaotic-aur)"
    else
      warn "yay from chaotic failed; attempting AUR yay-bin"
      if ask "Build yay-bin from AUR?"; then
        sudo_do pacman -S --needed --noconfirm base-devel git
        local tmpdir
        tmpdir="$(mktemp -d)"
        trap 'rm -rf "$tmpdir"' EXIT
        (cd "$tmpdir" && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm)
        msg "yay installed (AUR)"
      else
        warn "Skipping yay — will use pacman directly."
      fi
    fi
  fi
}

arch_install_packages() {
  local pm=pacman
  have yay && pm=yay
  # base-devel provides gcc/make needed for rustup to link
  sudo_do pacman -S --needed --noconfirm base-devel curl || true
  $pm -S --needed --noconfirm fish fzf zed micro ttf-jetbrains-mono-nerd \
    less unzip xz zstd pigz pbzip2 || true
  # Desktop-only extras (Arch is the desktop box; other distros are headless)
  $pm -S --needed --noconfirm zathura ksshaskpass gparted fastfetch \
    transmission-cli moc 7zip unrar cabextract ncompress || true
}

configure_yay() {
  have yay || return
  yay --save \
    --removemake \
    --pgpfetch \
    --devel \
    --provides \
    --bottomup \
    --batchinstall \
    --cleanafter \
    --sudoloop \
    --answerdiff None \
    --answeredit None \
    --answerclean None
  msg "yay config saved"
}

# ── Debian ────────────────────────────────────────────────────────────
debian_offer_system_upgrade_nonfatal() {
  sudo_do apt-get update -qq
  local upg
  upg=$(apt list --upgradeable 2>/dev/null | sed -n '1!p' || true)
  if [ -n "$upg" ]; then
    msg "Upgradeable packages:"
    echo "$upg" | sed 's/^/  /'
    if ask "Upgrade now?"; then
      sudo_do apt-get -y full-upgrade || true
    else
      warn "Continuing without upgrade."
    fi
  else
    msg "No Debian upgrades pending."
  fi
}

debian_install_packages() {
  sudo_do apt-get install -y build-essential curl fish fzf micro \
    less unzip xz-utils zstd pigz pbzip2
}

# ── Alpine ────────────────────────────────────────────────────────────
alpine_install_packages() {
  sudo_do apk add --no-cache build-base curl fish fzf micro \
    less unzip xz zstd pigz pbzip2
}

# ── RHEL family (Rocky / Alma / CentOS Stream) ────────────────────────
rhel_install_packages() {
  if ! rpm -q epel-release >/dev/null 2>&1; then
    sudo_do dnf install -y epel-release
    # CRB (CodeReady Builder) repo needed for some EPEL deps on RHEL 9
    sudo_do dnf config-manager --set-enabled crb 2>/dev/null || \
      sudo_do dnf config-manager --enable crb 2>/dev/null || true
  fi
  sudo_do dnf groupinstall -y "Development Tools"
  sudo_do dnf install -y curl fish fzf micro \
    less unzip xz zstd pigz pbzip2
}

# ── Shared: rustup + cargo-binstall + tools ───────────────────────────
bootstrap_rust() {
  if have rustup; then
    msg "Updating rustup toolchain"
    rustup update
  elif have pacman; then
    msg "Bootstrapping rustup via pacman"
    sudo_do pacman -S --needed --noconfirm rustup
    rustup toolchain install stable --no-self-update 2>/dev/null || true
  else
    msg "Bootstrapping rustup (stable)"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
      sh -s -- -y --no-modify-path --default-toolchain stable
  fi
  # shellcheck disable=SC1091
  [ -f "$CARGO_HOME/env" ] && . "$CARGO_HOME/env"
  export PATH="$CARGO_HOME/bin:$PATH"
  rustup component add rustfmt 2>/dev/null || true
}

# ── Neovim (Arch only — other distros ship versions too old for nvim 12) ──
maybe_install_neovim() {
  have pacman || return 0
  ask "Install Neovim and tree-sitter-cli?" || return 0
  local pm=pacman
  have yay && pm=yay
  $pm -S --needed --noconfirm neovim tree-sitter-cli || true
}

install_cargo_tools() {
  # shellcheck disable=SC1091
  [ -f "$CARGO_HOME/env" ] && . "$CARGO_HOME/env"
  export PATH="$CARGO_HOME/bin:$PATH"

  if ! have cargo-binstall; then
    msg "Installing cargo-binstall"
    cargo install cargo-binstall
  fi

  msg "Installing Rust tools via cargo-binstall"
  cargo binstall --no-confirm \
    bat fd-find ripgrep zoxide lsd zellij starship cargo-update git-delta
}

# ── SSH server (non-Arch) ─────────────────────────────────────────────
ensure_sshd() {
  ask "Set up SSH server (install, enable, allow root login)?" || return 0
  local svc=sshd
  if have apt-get; then
    sudo_do apt-get install -y openssh-server
    svc=ssh
  elif have dnf; then
    sudo_do dnf install -y openssh-server
  elif have apk; then
    sudo_do apk add --no-cache openssh
  fi

  local cfg=/etc/ssh/sshd_config
  sudo_do sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' "$cfg"
  sudo_do grep -q 'PermitRootLogin' "$cfg" 2>/dev/null || \
    printf 'PermitRootLogin yes\n' | sudo_do tee -a "$cfg" >/dev/null

  if have rc-service; then
    sudo_do rc-update add sshd default
    sudo_do rc-service sshd restart
  else
    sudo_do systemctl enable "$svc"
    sudo_do systemctl restart "$svc"
  fi
  msg "sshd: enabled, started, root login permitted"
}

# ── npm XDG ───────────────────────────────────────────────────────────
ensure_npm_xdg() {
  have npm || { msg "npm not found; skipping npm XDG setup"; return 0; }
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/npm"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/npm"
  local npmrc="$cfg/npmrc"
  mkdir -p "$cfg" "$cache" "$LOCAL_BIN" "$HOME/.local/lib"
  if [ -f "$HOME/.npmrc" ] && [ ! -L "$HOME/.npmrc" ]; then
    mv "$HOME/.npmrc" "$HOME/.npmrc.bak.$(date +%s)"
    warn "Backed up legacy ~/.npmrc"
  fi
  local tmp
  tmp="$(mktemp)"
  { printf 'prefix=%s\n' "$HOME/.local"; printf 'cache=%s\n' "$cache"
    echo 'fund=false'; echo 'audit=false'; } >"$tmp"
  mv -f "$tmp" "$npmrc"
  NPM_CONFIG_USERCONFIG="$npmrc" npm config set prefix "$HOME/.local" >/dev/null 2>&1 || true
  NPM_CONFIG_USERCONFIG="$npmrc" npm config set cache "$cache" >/dev/null 2>&1 || true
  case ":$PATH:" in *":$HOME/.local/bin:"*) : ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
  if [ -d "$HOME/.npm" ] && [ ! -e "$cache/_cacache" ]; then
    msg "Migrating ~/.npm -> $cache"; mv "$HOME/.npm" "$cache"
  fi
  msg "npm configured for XDG (prefix=$HOME/.local)"
}

# ── Legacy dotdir migration ────────────────────────────────────────────
# Mirrors every directory/file relocation declared in conf.d/00-env.fish
migrate_legacy_dotdirs() {
  local data="${XDG_DATA_HOME:-$HOME/.local/share}"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}"
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
  local old new
  for pair in \
    "$HOME/.cargo:$data/cargo" \
    "$HOME/.rustup:$data/rustup" \
    "$HOME/go:$data/go" \
    "$HOME/.android:$data/android" \
    "$HOME/.gnupg:$data/gnupg" \
    "$HOME/.gradle:$data/gradle" \
    "$HOME/.wine:$data/wine" \
    "$HOME/.fgfs:$data/flightgear" \
    "$HOME/.net:$cache/dotnet-bundle-extract" \
    "$HOME/texmf:$data/texmf" \
    "$HOME/.java/.userPrefs:$cfg/java/.userPrefs" \
    "$HOME/.lesshst:$cache/.lesshst" \
    "$HOME/.Xauthority:$cache/.Xauthority" \
    "$HOME/.gtkrc-2.0:$cfg/gtk-2.0/gtkrc" \
    "$HOME/.pulse-cookie:$cfg/pulse/cookie"
  do
    old="${pair%%:*}"; new="${pair#*:}"
    if [ -e "$old" ] && [ ! -e "$new" ]; then
      mkdir -p "$(dirname "$new")"
      mv "$old" "$new"
      msg "Migrated $old -> $new"
    fi
  done

  # TeX Live's pre-XDG cache/config dirs are year-versioned (~/.texlive2023/...)
  for d in "$HOME"/.texlive*/texmf-var; do
    [ -d "$d" ] || continue
    [ -e "$cache/texlive/texmf-var" ] && continue
    mkdir -p "$cache/texlive"
    mv "$d" "$cache/texlive/texmf-var"
    msg "Migrated $d -> $cache/texlive/texmf-var"
  done
  for d in "$HOME"/.texlive*/texmf-config; do
    [ -d "$d" ] || continue
    [ -e "$cfg/texlive/texmf-config" ] && continue
    mkdir -p "$cfg/texlive"
    mv "$d" "$cfg/texlive/texmf-config"
    msg "Migrated $d -> $cfg/texlive/texmf-config"
  done
}

# ── wget XDG ──────────────────────────────────────────────────────────
ensure_wget_xdg() {
  have wget || return 0
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/wget"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}"
  mkdir -p "$cfg"
  if [ -f "$HOME/.wget-hsts" ] && [ ! -e "$cache/wget-hsts" ]; then
    mv "$HOME/.wget-hsts" "$cache/wget-hsts"
    msg "Migrated ~/.wget-hsts -> $cache/wget-hsts"
  fi
  printf 'hsts_file = %s/wget-hsts\n' "$cache" >"$cfg/wgetrc"
  msg "wget HSTS database relocated to $cache/wget-hsts"
}

# ── Fish ──────────────────────────────────────────────────────────────
maybe_chsh_to_fish() {
  local f
  f="$(command -v fish || true)"
  if [ -z "$f" ]; then warn "fish not found; cannot chsh"; return; fi
  if [ "$SHELL" = "$f" ]; then msg "Default shell already fish"; return; fi
  if ! grep -qF "$f" /etc/shells 2>/dev/null; then
    msg "Adding $f to /etc/shells"
    sudo_do sh -c "echo '$f' >> /etc/shells"
  fi
  if ask "Change default shell to fish now?"; then
    chsh -s "$f" "${USER:-$(id -un)}" && msg "Shell changed to fish. Log out and back in."
  else
    warn "Skipped chsh; run: chsh -s $f"
  fi
}

# ── Scripts ───────────────────────────────────────────────────────────
deploy_scripts() {
  [ -d "$SCRIPTS_DIR" ] || { msg "No scripts/ dir; skipping"; return; }
  mkdir -p "$LOCAL_BIN"
  local rel src base dest lnk tgt
  while IFS= read -r rel; do
    src="$SCRIPTS_DIR/$rel"
    base="$(basename "$rel")"
    dest="$LOCAL_BIN/$base"
    [ -x "$src" ] || { warn "not executable: $rel (chmod +x if needed)"; continue; }
    [ -f "$dest" ] && [ ! -L "$dest" ] && backup_if_needed "$dest"
    ln -sfn "$src" "$dest"
    msg "linked $dest -> $src"
  done < <(cd "$SCRIPTS_DIR" && find . -type f -perm -111 -printf '%P\n' | sort)
  while IFS= read -r lnk; do
    tgt="$(readlink -f "$lnk" 2>/dev/null || true)"
    if [ -n "$tgt" ] && printf '%s' "$tgt" | grep -q "^$SCRIPTS_DIR/"; then
      [ -e "$tgt" ] || { rm -f "$lnk"; msg "removed stale link: $lnk"; }
    fi
  done < <(find "$LOCAL_BIN" -maxdepth 1 -type l -print)
}

# ── Main ──────────────────────────────────────────────────────────────
main() {
  ensure_git_early
  ensure_repo
  mkdir -p "$BACKUP_DIR"

  for rel in "${NEED_LINK_DIRS[@]}"; do link_into_home "$rel"; done

  if have pacman; then
    if arch_offer_system_upgrade_or_abort; then
      arch_setup_chaotic_and_yay
      arch_install_packages
      configure_yay
    else
      warn "Skipping Arch package installs."
    fi
  elif have apt-get; then
    debian_offer_system_upgrade_nonfatal
    debian_install_packages
    ensure_sshd
  elif have dnf; then
    rhel_install_packages
    ensure_sshd
  elif have apk; then
    alpine_install_packages
    ensure_sshd
  else
    warn "Unsupported distro: native package steps skipped."
  fi

  # Shared across all distros
  ensure_npm_xdg
  ensure_wget_xdg
  migrate_legacy_dotdirs
  bootstrap_rust
  install_cargo_tools
  maybe_install_neovim

  maybe_chsh_to_fish
  deploy_scripts

  msg "Done. Backups (if any): $BACKUP_DIR"
  msg "Log out and back in to pick up shell and PATH changes."
}

main "$@"
