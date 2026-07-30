#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/.local/git/dotfiles}"

NEED_LINK_DIRS=(
  ".config/fish"
  ".config/environment.d"
  ".config/starship.toml"
  ".config/yay"
  ".config/nvim"
  ".config/zed"
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

# ── deny root access ──────────────────────────────────────────────────────
require_non_root() {
  if [ "$(id -u)" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ]; then
      err "You ran this via sudo."
      err "Run it as: su - $SUDO_USER"
      err "Then: ./install.sh"
    else
      err "Run this as a normal user with sudo access."
    fi
    exit 1
  fi
}

# ── sudo access ──────────────────────────────────────────────────────
# Debian (and others) don't always add the first user to sudo by default,
# unlike Arch/RHEL images. Fail fast with a fix instead of dying confusingly
# partway through the first sudo_do call.
ensure_sudo_access() {
  [ "$(id -u)" -eq 0 ] && return 0

  local user fix
  user="$(id -un)"

  if ! have sudo; then
    err "sudo is not installed, and you are not root."
    if have apt-get; then fix="apt-get install -y sudo && usermod -aG sudo $user"
    elif have dnf; then fix="dnf install -y sudo && usermod -aG wheel $user"
    elif have pacman; then fix="pacman -S --noconfirm sudo && usermod -aG wheel $user"
    elif have apk; then fix="apk add sudo && usermod -aG wheel $user"
    else fix="install your distro's sudo package, then usermod -aG <sudo-group> $user"
    fi
    echo "  As root (su -), run:" >&2
    echo "    $fix" >&2
    echo "  Then log out and back in, and re-run this script." >&2
    exit 1
  fi

  if ! sudo -v 2>/dev/null; then
    err "sudo is installed, but $user is not authorized to use it."
    if have apt-get; then fix="usermod -aG sudo $user"
    elif have dnf; then fix="usermod -aG wheel $user"
    elif have pacman; then fix="usermod -aG wheel $user  # then uncomment %wheel in /etc/sudoers via visudo"
    elif have apk; then fix="usermod -aG wheel $user  # then add '%wheel ALL=(ALL) ALL' via visudo if missing"
    else fix="add $user to whatever group your /etc/sudoers grants, or add a direct sudoers entry via visudo"
    fi
    echo "  As root (su -), run:" >&2
    echo "    $fix" >&2
    echo "  Then log out and back in, and re-run this script." >&2
    exit 1
  fi
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

# ── Neovim ──────────────────────────────────────────────────────────
# The nvim config needs vim.pack (native plugin manager), which requires
# Neovim >=0.12 — newer than what any distro but Arch packages. Arch gets
# it from pacman; everywhere else we pull the official release tarball,
# since e.g. Debian 13 only ships 0.10.
NVIM_MIN_MINOR=12

nvim_version_ok() {
  have nvim || return 1
  local ver minor
  ver="$(nvim --version 2>/dev/null | head -1 | grep -oP '(?<=NVIM v)[0-9]+\.[0-9]+' || true)"
  minor="${ver#0.}"
  [ -n "$minor" ] && [ "$minor" -ge "$NVIM_MIN_MINOR" ] 2>/dev/null
}

install_neovim_release() {
  nvim_version_ok && return 0

  local asset
  case "$(uname -m)" in
    x86_64) asset=nvim-linux-x86_64.tar.gz ;;
    aarch64) asset=nvim-linux-arm64.tar.gz ;;
    *) warn "No prebuilt neovim release for arch $(uname -m); skipping"; return 1 ;;
  esac

  msg "Installing neovim >=0.$NVIM_MIN_MINOR from upstream release ($asset)"
  local tmpdir dest
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  if ! curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/$asset" -o "$tmpdir/nvim.tar.gz"; then
    warn "Failed to download neovim release; skipping"
    return 1
  fi
  tar -xzf "$tmpdir/nvim.tar.gz" -C "$tmpdir"

  dest="${XDG_DATA_HOME:-$HOME/.local/share}/nvim-release"
  rm -rf "$dest"
  mv "$tmpdir"/nvim-linux-*/ "$dest"
  mkdir -p "$LOCAL_BIN"
  ln -sfn "$dest/bin/nvim" "$LOCAL_BIN/nvim"
  msg "nvim linked: $LOCAL_BIN/nvim -> $dest/bin/nvim"
}

maybe_install_neovim() {
  local pkgs_ok=true
  local link_ok=true
  local missing_pkgs=()

  if have pacman; then
    for pkg in neovim tree-sitter-cli; do
      pacman -Q "$pkg" &>/dev/null || { pkgs_ok=false; missing_pkgs+=("$pkg"); }
    done
  else
    nvim_version_ok || pkgs_ok=false
  fi

  local nvim_link="$HOME/.config/nvim"
  local nvim_target="$REPO_DIR/.config/nvim"
  if [ ! -L "$nvim_link" ] || [ "$(readlink "$nvim_link")" != "$nvim_target" ]; then
    link_ok=false
  fi

  # All good, nothing to do
  $pkgs_ok && $link_ok && return 0

  # Build a human-readable summary of what's missing
  local missing_desc=""
  if ! $pkgs_ok; then
    if have pacman; then missing_desc="packages: ${missing_pkgs[*]}"
    else missing_desc="nvim missing or older than 0.$NVIM_MIN_MINOR"
    fi
  fi
  if ! $link_ok; then
    [ -n "$missing_desc" ] && missing_desc="$missing_desc, "
    missing_desc="${missing_desc}.config/nvim not linked"
  fi

  ask "Neovim not fully set up ($missing_desc). Install/link now?" || return 0

  if ! $pkgs_ok; then
    if have pacman; then
      local pm=pacman
      have yay && pm=yay
      $pm -S --needed --noconfirm "${missing_pkgs[@]}" || true
    else
      install_neovim_release || true
    fi
  fi

  if ! $link_ok; then
    link_into_home ".config/nvim"
  fi
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

  # Root-owned copies in /usr/local/bin so these resolve under sudo on any
  # machine's default secure_path (which virtually always includes it),
  # without ever trusting the user-writable $CARGO_HOME/bin for root's PATH.
  # The binary list is shared with scripts/update so the two can't drift.
  local bin
  while IFS= read -r bin; do
    [ -x "$CARGO_HOME/bin/$bin" ] || continue
    sudo_do install -o root -g root -m 0755 "$CARGO_HOME/bin/$bin" /usr/local/bin/
  done < "$SCRIPTS_DIR/cargo-system-bins"
}

# ── SSH server (non-Arch) ─────────────────────────────────────────────
ensure_sshd() {
  ask "Set up SSH server (install and enable sshd)?" || return 0
  local svc=sshd
  if have apt-get; then
    sudo_do apt-get install -y openssh-server
    svc=ssh
  elif have dnf; then
    sudo_do dnf install -y openssh-server
  elif have apk; then
    sudo_do apk add --no-cache openssh
  fi

  if have rc-service; then
    sudo_do rc-update add sshd default
    sudo_do rc-service sshd restart
  else
    sudo_do systemctl enable "$svc"
    sudo_do systemctl restart "$svc"
  fi
  msg "sshd: enabled and started"
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

# ── visudo editor ───────────────────────────────────────────────────────
# visudo only honors $EDITOR/$VISUAL if sudoers has env_editor enabled,
# which would let any user run an arbitrary "editor" as root via visudo.
# Defaults editor=... is the safe equivalent: a root-owned path list,
# tried in order, with no influence from the invoking user's environment.
configure_visudo_editor() {
  have visudo || return 0
  local micro_bin nvim_bin list tmp
  micro_bin="$(command -v micro || true)"
  [ -z "$micro_bin" ] && return 0
  nvim_bin="$(command -v nvim || true)"
  if [ -n "$nvim_bin" ]; then
    list="$nvim_bin:$micro_bin"
  else
    list="$micro_bin"
  fi
  tmp="$(mktemp)"
  printf 'Defaults editor="%s"\n' "$list" >"$tmp"
  if sudo_do visudo -cf "$tmp" >/dev/null 2>&1; then
    sudo_do install -o root -g root -m 0440 "$tmp" /etc/sudoers.d/dotfiles-editor
    msg "visudo editor set to: $list"
  else
    warn "Generated sudoers editor snippet failed validation; skipping"
  fi
  rm -f "$tmp"
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
  require_non_root
  ensure_sudo_access
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
  configure_visudo_editor

  maybe_chsh_to_fish
  deploy_scripts

  msg "Done. Backups (if any): $BACKUP_DIR"
  msg "Log out and back in to pick up shell and PATH changes."
}

main "$@"
