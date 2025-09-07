#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/.local/git/dotfiles}"

NEED_LINK_DIRS=(
  ".config/zsh"
  ".config/environment.d"
  ".config/nvim"
)

ZDOTDIR_LINE='ZDOTDIR=$HOME/.config/zsh'
SYSTEM_ZSHENV="/etc/zsh/zshenv"
SYSTEM_ZSH_PLUGINS="/usr/share/zsh/plugins"
SYSTEM_P10K_THEME="/usr/share/zsh-theme-powerlevel10k"
SYSTEM_P10K_LINK="$SYSTEM_ZSH_PLUGINS/powerlevel10k"
USER_PLUGINS="$HOME/.local/share/zsh/plugins"

BACKUP_DIR="$REPO_DIR/.backup-$(date +%Y%m%d-%H%M%S)"

have() { command -v "$1" >/dev/null 2>&1; }
sudo_do() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }
msg() { printf "\033[1;36m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m!!\033[0m %s\n" "$*"; }
ask() { local p="${1:-Proceed?} [Y/n] "; read -rp "$p" a || true; case "${a,,}" in y|yes|"") return 0;; *) return 1;; esac; }

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
  if [ ! -d "$REPO_DIR/.git" ]; then
    msg "Cloning dotfiles into $REPO_DIR"
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "${DOTFILES_REMOTE:-https://github.com/USER/dotfiles.git}" "$REPO_DIR"
  else
    msg "Repo exists at $REPO_DIR"
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
  if [ ! -e "$src" ]; then warn "Skip: $rel (missing in repo)"; return; fi
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
  arch_check_updates; state=$?

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

# Chaotic-aur + paru bootstrap (unchanged logic, kept here for convenience)
arch_setup_chaotic_and_paru() {
  if ! command -v pacman >/dev/null 2>&1; then return; fi

  if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null; then
    if ask "Enable chaotic-aur repository?"; then
      sudo_do pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || true
      sudo_do pacman-key --lsign-key 3056513887B78AEB || true
      sudo_do tee -a /etc/pacman.conf >/dev/null <<'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
      if ask "Install chaotic keyring/mirrorlist now?"; then
        sudo_do pacman -Sy --needed --noconfirm chaotic-keyring chaotic-mirrorlist \
          || warn "Could not install chaotic keyring/mirrorlist"
      else
        warn "Skipping keyring/mirrorlist install; syncing later may be required."
      fi
    else
      warn "Skipped chaotic-aur enablement"
    fi
  fi

  if ! command -v paru >/dev/null 2>&1; then
    if grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/div/null; then
      msg "Attempting paru (chaotic-aur)"
      sudo_do pacman -S --needed --noconfirm paru || warn "paru from chaotic failed"
    fi
  fi

  if ! command -v paru >/dev/null 2>&1; then
    if ask "Build paru-bin from AUR?"; then
      sudo_do pacman -S --needed --noconfirm base-devel git
      tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
      ( cd "$tmpdir"
        git clone https://aur.archlinux.org/paru-bin.git
        cd paru-bin
        makepkg -si --noconfirm
      )
      msg "paru installed (AUR)"
    else
      warn "Skipping paru install — will use pacman directly."
    fi
  fi
}

arch_install_base() {
  local pm="pacman"; have paru && pm="paru"
  $pm -S --needed --noconfirm zsh git neovim ripgrep fzf curl bat || true
  $pm -S --needed --noconfirm powerlevel10k zsh-autosuggestions zsh-syntax-highlighting || true
  $pm -S --needed --noconfirm fzf-tab-git || true
}

debian_install_base() {
  sudo_do apt install -y zsh git neovim ripgrep fzf curl bat || true
}

debian_install_or_clone_zsh_plugins() {
  local need_clone=()
  sudo_do apt install -y zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel10k || true
  [ -d "$SYSTEM_ZSH_PLUGINS/zsh-autosuggestions" ] || need_clone+=("https://github.com/zsh-users/zsh-autosuggestions.git|zsh-autosuggestions")
  [ -d "$SYSTEM_ZSH_PLUGINS/zsh-syntax-highlighting" ] || need_clone+=("https://github.com/zsh-users/zsh-syntax-highlighting.git|zsh-syntax-highlighting")
  if [ ! -d "$SYSTEM_P10K_THEME" ] && [ ! -d "$SYSTEM_ZSH_PLUGINS/powerlevel10k" ]; then
    need_clone+=("https://github.com/romkatv/powerlevel10k.git|powerlevel10k")
  fi
  need_clone+=("https://github.com/Aloxaf/fzf-tab.git|fzf-tab")
  if [ "${#need_clone[@]}" -gt 0 ]; then
    mkdir -p "$USER_PLUGINS"
    for entry in "${need_clone[@]}"; do
      url="${entry%%|*}"; name="${entry##*|}"
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
  if [ -f "$SYSTEM_ZSHENV" ] && grep -Fxq "$ZDOTDIR_LINE" "$SYSTEM_ZSHENV"; then need=0; fi
  if [ "$need" -eq 1 ]; then
    msg "Writing $SYSTEM_ZSHENV (root)"
    tmp="$(mktemp)"
    [ -f "$SYSTEM_ZSHENV" ] && sudo_do cp "$SYSTEM_ZSHENV" "$tmp" || true
    if [ -f "$tmp" ]; then sed -i "\|^$ZDOTDIR_LINE\$|d" "$tmp"; fi
    printf "%s\n" "$ZDOTDIR_LINE" >> "$tmp"
    sudo_do install -m 0644 "$tmp" "$SYSTEM_ZSHENV"
    rm -f "$tmp"
  else
    msg "$SYSTEM_ZSHENV already sets ZDOTDIR"
  fi
}

maybe_chsh_to_zsh() {
  local z="$(command -v zsh || true)"
  if [ -z "$z" ]; then warn "zsh not found; cannot chsh"; return; fi
  if [ "$SHELL" = "$z" ]; then msg "Default shell already zsh"; return; fi
  if ask "Change default shell to zsh now?"; then
    chsh -s "$z" "$USER" && msg "Shell changed to zsh. Please log out and back in."
  else
    warn "Skipped chsh; you can run: chsh -s $(command -v zsh)"
  fi
}

bootstrap_nvim() {
  if ! have nvim; then warn "Neovim not installed; skipping bootstrap"; return; fi
  msg "Running PlugInstall and BootstrapAll (headless)"
  nvim --headless +":silent PlugInstall" +":silent qall" || true
  nvim --headless +":BootstrapAll" +":qall" || true
}

arch_install_dev_tools() {
  local pm="pacman"; have paru && pm="paru"
  msg "Installing developer tools (Arch, packages only)"
  $pm -S --needed --noconfirm stylua shfmt jq taplo sqlfluff prettier php-code-sniffer clang ripgrep bat || true
  if ! have rustup; then
    warn "rustup not found; rustfmt requires rustup component."
    if ask "Install rustup?"; then $pm -S --needed --noconfirm rustup || true; fi
  fi
  if have rustup; then rustup component add rustfmt || warn "Failed to add rustfmt component"; fi
}

debian_dev_tools_notify_and_yamlfmt() {
  msg "Developer tools (Debian): notifying only (except yamlfmt)"
  echo " - stylua: apt install stylua (or build)"
  echo " - shfmt:  apt install shfmt"
  echo " - isort:  apt install python3-isort or pipx/pip"
  echo " - black:  apt install black or pipx/pip"
  echo " - prettier: npm i -g prettier"
  echo " - jq: apt install jq"
  echo " - taplo: cargo install taplo-cli (or binary release)"
  echo " - sqlfluff: pipx/pip install sqlfluff"
  echo " - phpcbf: apt install php-codesniffer"
  echo " - clang: apt install clang"
  echo " - rustfmt: rustup component add rustfmt"
  echo " - ripgrep: apt install ripgrep"
  echo " - bat: apt install bat"
  if ! have yamlfmt; then
    msg "Installing yamlfmt (Go)"
    if ! have go; then sudo_do apt install -y golang || { warn "Go install failed; cannot install yamlfmt"; return; }; fi
    GOBIN="$HOME/.local/bin" go install github.com/google/yamlfmt/cmd/yamlfmt@latest || warn "yamlfmt install failed"
    grep -q '\$HOME/.local/bin' "$HOME/.profile" 2>/dev/null || printf '%s\n' 'export PATH=$HOME/.local/bin:$PATH' >> "$HOME/.profile"
    msg "yamlfmt installed to ~/.local/bin"
  else
    msg "yamlfmt already installed"
  fi
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
    fi
  elif have apt; then
    debian_offer_system_upgrade_nonfatal
    debian_install_base
    debian_install_or_clone_zsh_plugins
    debian_dev_tools_notify_and_yamlfmt
  else
    warn "Unsupported distro: package steps skipped."
  fi

  setup_plugin_links
  ensure_system_zshenv
  bootstrap_nvim
  maybe_chsh_to_zsh

  msg "Done. Backups (if any): $BACKUP_DIR"
  echo "Please log out and back in to pick up ZDOTDIR and any PATH changes."
}

main "$@"
