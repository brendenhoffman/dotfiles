#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/.local/git/dotfiles}"

NEED_LINK_DIRS=(
  ".config/zsh"
  ".config/environment.d"
  ".config/nvim"
)

ZDOTDIR_LINE='ZDOTDIR=$HOME/.config/zsh' # don't expand this
SYSTEM_ZSHENV="/etc/zsh/zshenv"
SYSTEM_ZSH_PLUGINS="/usr/share/zsh/plugins"
SYSTEM_P10K_THEME="/usr/share/zsh-theme-powerlevel10k"
SYSTEM_P10K_LINK="$SYSTEM_ZSH_PLUGINS/powerlevel10k"
USER_PLUGINS="$HOME/.local/share/zsh/plugins"
SCRIPTS_DIR="$REPO_DIR/scripts"
LOCAL_BIN="$HOME/.local/bin"

BACKUP_DIR="$REPO_DIR/.backup-$(date +%Y%m%d-%H%M%S)"

have() { command -v "$1" >/dev/null 2>&1; }
sudo_do() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }
msg() { printf "\033[1;36m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m!!\033[0m %s\n" "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }
ask() {
  local p="${1:-Proceed?} [Y/n] "
  read -rp "$p" a || true
  case "${a,,}" in y | yes | "") return 0 ;; *) return 1 ;; esac
}

ensure_git_early() {
  if have git; then return; fi
  if have pacman; then
    msg "Installing git (pacman)"
    sudo_do pacman -S --needed --noconfirm git base-devel
  elif have apt; then
    msg "Installing git (apt)"
    sudo_do apt update
    sudo_do apt install -y git
  else
    warn "No known package manager to install git; please install git first."
  fi
}

ensure_repo() {
  local remote="${DOTFILES_REMOTE:-https://github.com/brendenhoffman/dotfiles.git}"
  local branch="${DOTFILES_BRANCH:-main}"

  if [ ! -d "$REPO_DIR/.git" ]; then
    msg "Cloning dotfiles into $REPO_DIR"
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone --branch "$branch" "$remote" "$REPO_DIR" ||
      {
        err "Clone failed"
        exit 1
      }
    return
  fi

  msg "Repo exists at $REPO_DIR"

  # Detect uncommitted changes and force a choice
  if [ -n "$(git -C "$REPO_DIR" status --porcelain)" ]; then
    warn "Local changes detected in $REPO_DIR"
    if ask "Proceed and temporarily stash your local changes to update from origin/$branch?"; then
      (cd "$REPO_DIR" && git stash push -u -m "install.sh auto-stash $(date -Iseconds)") || true
    else
      err "Aborting per your choice. Resolve local changes, then re-run."
      exit 1
    fi
  fi

  # Update (fast-forward only)
  msg "Updating repo (origin/$branch)"
  git -C "$REPO_DIR" fetch --prune --tags || warn "Fetch failed; attempting pull anyway"
  git -C "$REPO_DIR" checkout -q "$branch" 2>/dev/null || git -C "$REPO_DIR" checkout -qb "$branch"
  if ! git -C "$REPO_DIR" pull --ff-only origin "$branch"; then
    err "Non-fast-forward or update failed; resolve manually and re-run."
    exit 1
  fi
}

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
  if [ ! -e "$src" ]; then
    warn "Skip: $rel (missing in repo)"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  backup_if_needed "$dest"
  ln -sfn "$src" "$dest"
  msg "Linked ~/${rel} -> $src"
}

# Returns: 0 = no updates, 1 = updates exist, 2 = unknown (no checkupdates)
arch_check_updates() {
  if command -v checkupdates >/dev/null 2>&1; then
    if updates="$(checkupdates 2>/dev/null)"; then
      if [ -z "$updates" ]; then
        return 0
      else
        echo "$updates" | sed 's/^/  /'
        return 1
      fi
    fi
  fi
  # checkupdates not present or failed -> unknown
  return 2
}

# On Arch, avoid partial upgrades:
# - If we KNOW there are no updates, proceed.
# - If updates exist, ask to upgrade; on decline -> abort package installs.
# - If unknown (no pacman-contrib), require upgrade; on decline -> abort.
# When upgrading: refresh keyring first, then do full upgrade.
arch_offer_system_upgrade_or_abort() {
  local state
  arch_check_updates
  state=$?

  if [ $state -eq 0 ]; then
    msg "No system updates pending; continuing."
    return 0
  fi

  if [ $state -eq 1 ]; then
    msg "Updates are available:"
  else
    warn "Cannot verify updates (pacman-contrib/checkupdates not installed)."
    warn "To be safe, a full upgrade is required before proceeding."
  fi

  if ask "Run a full system upgrade now?"; then
    # Keyring first (safe even if already current)
    if command -v paru >/dev/null 2>&1; then
      sudo_do pacman -Sy --noconfirm archlinux-keyring || true
      paru -Syu || return 1
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

debian_offer_system_upgrade_nonfatal() {
  sudo_do apt update
  upg=$(apt list --upgradeable 2>/dev/null | sed -n '1!p' || true)
  if [ -n "$upg" ]; then
    msg "Upgradeable packages:"
    echo "$upg" | sed 's/^/  /'
    if ask "Upgrade now?"; then
      sudo_do apt -y full-upgrade || true
    else
      warn "Continuing without Debian upgrade."
    fi
  else
    msg "No Debian upgrades pending."
  fi
}

# Chaotic-aur + paru bootstrap
arch_setup_chaotic_and_paru() {
  command -v pacman >/dev/null 2>&1 || return

  # If repo already present, nothing to do
  if grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null; then
    msg "chaotic-aur already enabled"
  else
    if ask "Enable chaotic-aur repository?"; then
      # Import & locally sign the Chaotic key
      sudo_do pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || true
      sudo_do pacman-key --lsign-key 3056513887B78AEB || true

      # Install keyring + mirrorlist directly from the CDN (works before repo exists)
      if ! sudo_do pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'; then
        warn "Could not install chaotic keyring/mirrorlist from URL"
      fi

      # Now write the repo block that includes the mirrorlist we just installed
      sudo_do tee -a /etc/pacman.conf >/dev/null <<'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF

      msg "chaotic-aur enabled"
      sudo_do pacman -Sy
    else
      warn "Skipped chaotic-aur enablement"
    fi
  fi

  # Try to install paru from chaotic-aur, else fall back to AUR
  if ! command -v paru >/dev/null 2>&1; then
    if sudo_do pacman -S --needed --noconfirm paru; then
      msg "paru installed (chaotic-aur)"
    else
      warn "paru from chaotic failed; attempting AUR paru-bin"
      if ask "Build paru-bin from AUR?"; then
        sudo_do pacman -S --needed --noconfirm base-devel git
        tmpdir="$(mktemp -d)"
        trap 'rm -rf "$tmpdir"' EXIT
        (cd "$tmpdir" && git clone https://aur.archlinux.org/paru-bin.git && cd paru-bin && makepkg -si --noconfirm)
        msg "paru installed (AUR)"
      else
        warn "Skipping paru install — will use pacman directly."
      fi
    fi
  fi
}

arch_install_base() {
  local pm="pacman"
  have paru && pm="paru"
  $pm -S --needed --noconfirm zsh zoxide git neovim ripgrep fzf curl bat cmake nodejs || true
  $pm -S --needed --noconfirm ttf-meslo-nerd-font-powerlevel10k zsh-theme-powerlevel10k zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search-git || true
  $pm -S --needed --noconfirm fzf-tab-git || true
}

debian_install_base() {
  sudo_do apt install -y zsh git ripgrep fzf curl bat build-essential cmake || true
}

deb_codename() {
  # returns "bookworm", "bullseye", etc.
  . /etc/os-release 2>/dev/null || return 1
  [ -n "$VERSION_CODENAME" ] && {
    echo "$VERSION_CODENAME"
    return 0
  }
  command -v lsb_release >/dev/null && {
    lsb_release -sc
    return 0
  }
  return 1
}

ensure_backports_enabled() {
  local codename="$(deb_codename)" || {
    echo "Cannot detect Debian codename"
    return 1
  }
  local file="/etc/apt/sources.list.d/backports.list"
  if ! grep -qs "^deb .* ${codename}-backports " "$file" 2>/dev/null; then
    echo "Enabling ${codename}-backports"
    echo "deb http://deb.debian.org/debian ${codename}-backports main" | sudo tee "$file" >/dev/null
    sudo apt update
  fi
}

apt_install_from_backports() {
  local codename="$(deb_codename)" || return 1
  sudo apt -t "${codename}-backports" install -y nodejs golang
}

ensure_p10k_fonts() {
  local dest="$HOME/.local/share/fonts"
  mkdir -p "$dest"
  msg "Installing MesloLGS Nerd Fonts (P10k)"
  for f in "MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf"; do
    curl -fsSL -o "$dest/$f" \
      "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/$f" || {
      warn "Failed to fetch $f"
    }
  done
  fc-cache -f "$dest" >/dev/null 2>&1 || true
  msg "Fonts installed. Set your terminal font to 'MesloLGS NF'"
}

debian_install_or_clone_zsh_plugins() {
  local need_clone=()
  sudo_do apt install -y zsh-autosuggestions zsh-syntax-highlighting || true
  [ -d "$SYSTEM_ZSH_PLUGINS/zsh-autosuggestions" ] || need_clone+=("https://github.com/zsh-users/zsh-autosuggestions.git|zsh-autosuggestions")
  [ -d "$SYSTEM_ZSH_PLUGINS/zsh-syntax-highlighting" ] || need_clone+=("https://github.com/zsh-users/zsh-syntax-highlighting.git|zsh-syntax-highlighting")
  if [ ! -d "$SYSTEM_P10K_THEME" ] && [ ! -d "$SYSTEM_ZSH_PLUGINS/powerlevel10k" ]; then
    need_clone+=("https://github.com/romkatv/powerlevel10k.git|powerlevel10k")
  fi
  need_clone+=("https://github.com/Aloxaf/fzf-tab.git|fzf-tab")
  need_clone+=("https://github.com/zsh-users/zsh-history-substring-search.git|zsh-history-substring-search")
  if [ "${#need_clone[@]}" -gt 0 ]; then
    mkdir -p "$USER_PLUGINS"
    for entry in "${need_clone[@]}"; do
      url="${entry%%|*}"
      name="${entry##*|}"
      dest="$USER_PLUGINS/$name"
      if [ ! -d "$dest" ]; then
        msg "Cloning $name into $dest"
        git clone --depth=1 "$url" "$dest"
      fi
    done
  fi
}

setup_plugin_links() {
  if [ ! -d "$SYSTEM_ZSH_PLUGINS" ]; then
    msg "Creating $SYSTEM_ZSH_PLUGINS"
    sudo_do mkdir -p "$SYSTEM_ZSH_PLUGINS"
  fi
  if [ -d "$SYSTEM_P10K_THEME" ] && [ ! -e "$SYSTEM_P10K_LINK" ]; then
    msg "Linking powerlevel10k into $SYSTEM_ZSH_PLUGINS"
    sudo_do ln -sfn "$SYSTEM_P10K_THEME" "$SYSTEM_P10K_LINK"
  fi
  mkdir -p "$(dirname "$USER_PLUGINS")"
  if [ -e "$USER_PLUGINS" ] && [ ! -L "$USER_PLUGINS" ]; then backup_if_needed "$USER_PLUGINS"; fi
  ln -sfn "$SYSTEM_ZSH_PLUGINS" "$USER_PLUGINS"
  mkdir -p "$HOME/.config/zsh"
  ln -sfn "$USER_PLUGINS" "$HOME/.config/zsh/plugins"
  msg "Zsh plugin paths linked"
}

ensure_system_zshenv() {
  local need=1
  if [ -f "$SYSTEM_ZSHENV" ] && grep -Fxq "$ZDOTDIR_LINE" "$SYSTEM_ZSHENV"; then
    need=0
  fi

  if [ "$need" -eq 1 ]; then
    msg "Writing $SYSTEM_ZSHENV (root)"
    tmp="$(mktemp)"
    [ -f "$SYSTEM_ZSHENV" ] && sudo_do cp "$SYSTEM_ZSHENV" "$tmp" || true
    if [ -f "$tmp" ]; then
      sed -i "\|^$ZDOTDIR_LINE\$|d" "$tmp"
    fi
    printf "%s\n" "$ZDOTDIR_LINE" >>"$tmp"

    # ensure /etc/zsh exists, then write the file
    sudo_do install -D -m 0644 "$tmp" "$SYSTEM_ZSHENV"

    rm -f "$tmp"
  else
    msg "$SYSTEM_ZSHENV already sets ZDOTDIR"
  fi
}

maybe_chsh_to_zsh() {
  local z="$(command -v zsh || true)"
  if [ -z "$z" ]; then
    warn "zsh not found; cannot chsh"
    return
  fi
  if [ "$SHELL" = "$z" ]; then
    msg "Default shell already zsh"
    return
  fi
  if ask "Change default shell to zsh now?"; then
    chsh -s "$z" "$USER" && msg "Shell changed to zsh. Please log out and back in."
  else
    warn "Skipped chsh; you can run: chsh -s $(command -v zsh)"
  fi
}

ensure_vim_plug() {
  # standard XDG install path for vim-plug
  local plug="$HOME/.local/share/nvim/site/autoload/plug.vim"
  if [ -f "$plug" ]; then
    msg "vim-plug already present"
    return
  fi
  msg "Installing vim-plug to $plug"
  mkdir -p "$(dirname "$plug")"
  curl -fsSL https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim -o "$plug"
}

bootstrap_nvim() {
  if ! have nvim; then
    warn "Neovim not installed; skipping bootstrap"
    return
  fi

  ensure_vim_plug

  msg "Running PlugInstall (headless)"
  nvim --headless +'silent! PlugInstall --sync' +qa || true

  msg "Running BootstrapAll (if defined)"
  nvim --headless +':lua if vim.fn.exists(":BootstrapAll")==2 then vim.cmd("silent! BootstrapAll") end' +qa || true
}

arch_install_dev_tools() {
  local pm="pacman"
  have paru && pm="paru"
  msg "Installing developer tools (Arch, packages only)"
  $pm -S --needed --noconfirm stylua shfmt jq taplo sqlfluff prettier php-codesniffer clang ripgrep bat yamlfmt python-black python-isort || true
}

debian_dev_tools_notify_and_yamlfmt() {
  msg "Developer tools (Debian): notifying only (yamlfmt is required and will be installed)"
  echo " - stylua: apt install stylua (or build)"
  echo " - shfmt:  apt install shfmt"
  echo " - isort:  apt install python3-isort or pipx/pip"
  echo " - black:  apt install black or pipx/pip"
  echo " - prettier: optional; requires nodejs+npm"
  echo " - jq: apt install jq"
  echo " - taplo: cargo install taplo-cli (or binary release)"
  echo " - sqlfluff: pipx/pip install sqlfluff"
  echo " - phpcbf: apt install php-codesniffer"
  echo " - clang: apt install clang"
  echo " - rustfmt: rustup component add rustfmt"
  echo " - ripgrep: apt install ripgrep"
  echo " - bat: apt install bat"

  # yamlfmt is required, always install/update
  msg "Installing yamlfmt (Go)"
  if ! have go; then
    sudo_do apt install -y golang || {
      err "Failed to install Go; yamlfmt cannot be installed"
      return 1
    }
  fi

  mkdir -p "$HOME/.local/bin"
  export GOPATH="$HOME/.local/share/go"
  GOBIN="$HOME/.local/bin" go install github.com/google/yamlfmt/cmd/yamlfmt@latest ||
    {
      err "yamlfmt install failed"
      return 1
    }

  if ! printf '%s' "$PATH" | grep -q "$HOME/.local/bin"; then
    warn "~/.local/bin is not on PATH. Add this to your zsh profile (e.g. ~/.config/zsh/.zprofile):"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
  fi

  msg "yamlfmt installed to ~/.local/bin"
}

ensure_rustfmt() {
  if ! command -v rustup >/dev/null 2>&1; then
    warn "rustup not installed; skipping rustfmt setup"
    return
  fi

  export RUSTUP_HOME="$HOME/.local/share/rustup"
  export CARGO_HOME="$HOME/.local/share/cargo"

  # if no default toolchain yet, install/set stable
  if ! rustup show active-toolchain >/dev/null 2>&1; then
    msg "No active Rust toolchain; installing & setting stable"
    rustup default stable || rustup toolchain install stable
  fi

  # add rustfmt on the stable toolchain
  if ! command -v rustfmt >/dev/null 2>&1; then
    msg "Installing rustfmt component"
    rustup component add rustfmt --toolchain stable || warn "Failed to add rustfmt"
  fi
}

deploy_scripts() {
  [ -d "$SCRIPTS_DIR" ] || {
    msg "No scripts/ dir; skipping"
    return
  }
  mkdir -p "$LOCAL_BIN"

  # link every executable file under scripts/, by basename
  while IFS= read -r rel; do
    src="$SCRIPTS_DIR/$rel"
    base="$(basename "$rel")"
    dest="$LOCAL_BIN/$base"

    # skip non-executables
    [ -x "$src" ] || {
      warn "not executable: $rel (chmod +x if needed)"
      continue
    }

    # backup any existing non-symlink
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
      backup_if_needed_file "$dest"
    fi

    ln -sfn "$src" "$dest"
    msg "linked $dest -> $src"
  done < <(cd "$SCRIPTS_DIR" && find . -type f -perm -111 -printf '%P\n' | sort)

  # remove stale links in ~/.local/bin that point into repo but whose source disappeared
  while IFS= read -r lnk; do
    tgt="$(readlink -f "$lnk" 2>/dev/null || true)"
    if [ -n "$tgt" ] && printf '%s' "$tgt" | grep -q "^$SCRIPTS_DIR/"; then
      [ -e "$tgt" ] || {
        rm -f "$lnk"
        msg "removed stale link: $lnk"
      }
    fi
  done < <(find "$LOCAL_BIN" -maxdepth 1 -type l -print)
}

mirror_system_zsh_plugins() {
  mkdir -p "$HOME/.local/share/zsh/plugins"

  link_if_exists() {
    local src="$1" dst="$2"
    [ -e "$src" ] || return 0
    sudo_do ln -sfn "$src" "$dst"
  }

  link_if_exists /usr/share/zsh-autosuggestions \
    "$HOME/.local/share/zsh/plugins/zsh-autosuggestions"
  link_if_exists /usr/share/zsh-syntax-highlighting \
    "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting"
}

ensure_neovim_portable() {
  # need >= 0.9
  if command -v nvim >/dev/null 2>&1; then
    set -- $(nvim --version | sed -n '1s/.* v\([0-9]\+\)\.\([0-9]\+\).*/\1 \2/p')
    if [ -n "$1" ] && { [ "$1" -gt 0 ] || { [ "$1" -eq 0 ] && [ "$2" -ge 9 ]; }; }; then
      msg "Neovim OK: $(nvim --version | head -1)"
      return 0
    fi
  fi

  # choose asset by arch
  local asset
  case "$(uname -m)" in
  x86_64) asset="nvim-linux-x86_64.tar.gz" ;;
  aarch64 | arm64) asset="nvim-linux-arm64.tar.gz" ;;
  *)
    err "Unsupported arch $(uname -m)"
    return 1
    ;;
  esac

  local opt="$HOME/.local/opt" bin="$HOME/.local/bin"
  local cache="${TMPDIR:-$HOME/.cache}"
  mkdir -p "$opt" "$bin" "$cache" || {
    err "Cannot create $opt or $bin or $cache"
    return 1
  }

  local tmpdir
  tmpdir="$(mktemp -d -p "$cache")" || {
    err "mktemp failed"
    return 1
  }
  trap 'rm -rf "$tmpdir"' EXIT

  : >"$tmpdir/.writetest" || {
    err "Cannot write to $tmpdir"
    return 1
  }

  # downloader that tries HTTP/2, then forces HTTP/1.1, then wget
  _download() {
    local url="$1" out="$2"
    # try normal (HTTP/2)
    curl -fL --retry 3 --retry-all-errors -C - -o "$out" "$url" && return 0
    # try forcing HTTP/1.1 (fixes some 302/h2 issues)
    curl --http1.1 -fL --retry 3 --retry-all-errors -C - -o "$out" "$url" && return 0
    # try wget if available
    command -v wget >/dev/null 2>&1 && wget -O "$out" "$url" && return 0
    return 1
  }

  local tar="$tmpdir/nvim.tar.gz"
  local url_latest="https://github.com/neovim/neovim/releases/latest/download/${asset}"

  msg "Downloading Neovim (latest)…"
  if ! _download "$url_latest" "$tar"; then
    warn "latest/ download failed; trying tagged release"

    # grab exact tag (we already saw you do this in your script)
    local tag
    tag="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest |
      grep -m1 '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')"
    [ -n "$tag" ] || {
      err "Could not detect latest tag"
      return 1
    }

    local url_tag="https://github.com/neovim/neovim/releases/download/v${tag}/${asset}"
    msg "Downloading Neovim v${tag}…"
    _download "$url_tag" "$tar" || {
      err "Download failed (network/URL write error)"
      return 1
    }
  fi

  # sanity: make sure we didn't get an HTML error page
  if [ ! -s "$tar" ] || file "$tar" | grep -qi html; then
    err "Downloaded file is not a tarball (did we hit a 404 or a proxy error?)"
    return 1
  fi

  tar -xzf "$tar" -C "$tmpdir" || {
    err "Extract failed"
    return 1
  }
  local extracted
  extracted="$(echo "$tmpdir"/nvim-linux-*)"
  [ -d "$extracted" ] || {
    err "Unexpected archive layout"
    return 1
  }

  local ver
  ver="$("$extracted/bin/nvim" --version 2>/dev/null | sed -n '1s/.* v\([0-9.]\+\).*/\1/p')"
  local dest="$opt/nvim-${ver:-portable-$(date +%Y%m%d)}"
  rm -rf "$dest"
  mv "$extracted" "$dest" || {
    err "Move failed"
    return 1
  }

  ln -sfn "$dest/bin/nvim" "$bin/nvim"
  case ":$PATH:" in *":$bin:"*) : ;; *) export PATH="$bin:$PATH" ;; esac

  msg "Neovim installed at $dest; symlinked at $bin/nvim"
}

main() {
  ensure_git_early
  ensure_repo
  mkdir -p "$BACKUP_DIR"

  for rel in "${NEED_LINK_DIRS[@]}"; do link_into_home "$rel"; done

  if have pacman; then
    if ! arch_offer_system_upgrade_or_abort; then
      warn "Aborting Arch package installs due to pending updates."
    else
      arch_setup_chaotic_and_paru
      arch_install_base
      arch_install_dev_tools
      setup_plugin_links
    fi
  elif have apt; then
    debian_offer_system_upgrade_nonfatal
    debian_install_base
    ensure_backports_enabled
    apt_install_from_backports
    ensure_neovim_portable
    debian_install_or_clone_zsh_plugins
    debian_dev_tools_notify_and_yamlfmt
    mirror_system_zsh_plugins
  else
    warn "Unsupported distro: package steps skipped."
  fi

  ensure_system_zshenv
  bootstrap_nvim
  maybe_chsh_to_zsh
  ensure_rustfmt
  deploy_scripts

  msg "Done. Backups (if any): $BACKUP_DIR"
  echo "Please log out and back in to pick up ZDOTDIR and any PATH changes."
}

main "$@"
