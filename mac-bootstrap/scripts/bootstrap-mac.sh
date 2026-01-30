\
#!/usr/bin/env bash
set -euo pipefail

# macOS bootstrap for CLI + zsh environment (safe to re-run)
# - Installs Xcode CLT (if missing), Homebrew (if missing)
# - Installs tools: git, fzf, ripgrep, jq, gnupg, pyenv, pipx, fnm, go
# - Installs font: MesloLGS Nerd Font (Nerd Font)
# - Installs latest Python via pyenv, pipenv via pipx
# - Installs Node.js LTS via fnm
# - Installs Oh My Zsh + plugins + Powerlevel10k theme
# - Patches ~/.zshrc (minimal, idempotent)

log() { printf "\n==> %s\n" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script is for macOS only."
    exit 1
  fi
}

ensure_xcode_clt() {
  log "Checking Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools already installed"
    return
  fi

  log "Installing Xcode Command Line Tools"
  xcode-select --install || true

  log "Waiting for installation to finish..."
  until xcode-select -p >/dev/null 2>&1; do
    sleep 10
  done
}

ensure_homebrew() {
  log "Checking Homebrew"
  if have brew; then
    log "Homebrew already installed"
    return
  fi

  log "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  if ! have brew; then
    echo "Homebrew installation failed."
    exit 1
  fi
}

ensure_brew_shellenv() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

brew_install_packages() {
  log "Updating Homebrew"
  brew update

  log "Installing packages"
  brew install \
    git \
    curl \
    wget \
    fzf \
    ripgrep \
    jq \
    gnupg \
    pyenv \
    pipx \
    fnm \
    go

  log "Installing Nerd Font for Powerlevel10k"
  brew tap homebrew/cask-fonts >/dev/null 2>&1 || true
  brew install --cask font-meslo-lg-nerd-font
}

configure_fzf() {
  log "Configuring fzf (bindings + completion)"
  if [[ -x "$(brew --prefix)/opt/fzf/install" ]]; then
    "$(brew --prefix)/opt/fzf/install" \
      --no-bash --no-fish --no-update-rc \
      --key-bindings --completion || true
  fi
}

setup_pyenv_latest_python() {
  log "Setting up pyenv and latest Python"
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  export PATH="$PYENV_ROOT/bin:$PATH"

  if ! have pyenv; then
    echo "pyenv not found."
    exit 1
  fi

  eval "$(pyenv init -)"

  latest_python="$(pyenv install -l | sed 's/^[[:space:]]*//' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -n 1)"
  if [[ -z "${latest_python:-}" ]]; then
    echo "Unable to determine latest Python version from pyenv."
    exit 1
  fi

  if pyenv versions --bare | grep -qx "$latest_python"; then
    log "Python $latest_python already installed"
  else
    log "Installing Python $latest_python"
    pyenv install "$latest_python"
  fi

  log "Setting global Python to $latest_python"
  pyenv global "$latest_python"

  log "Upgrading pip and pipx"
  python -m pip install --upgrade pip
  python -m pip install --upgrade pipx
  pipx ensurepath >/dev/null 2>&1 || true
}

install_pipenv_via_pipx() {
  log "Installing pipenv via pipx"
  if have pipenv; then
    log "pipenv already installed"
    return
  fi
  if ! have pipx; then
    echo "pipx not found."
    exit 1
  fi
  pipx install pipenv || pipx upgrade pipenv
}

setup_fnm_node_lts() {
  log "Installing Node.js LTS via fnm"
  if ! have fnm; then
    echo "fnm not found."
    exit 1
  fi

  eval "$(fnm env --use-on-cd)"

  fnm install --lts || true
  fnm default lts-latest || true

  if have node; then log "Node: $(node -v)"; fi
  if have npm; then log "npm: $(npm -v)"; fi
}

install_oh_my_zsh() {
  log "Installing Oh My Zsh"
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "Oh My Zsh already installed"
    return
  fi

  RUNZSH=no KEEP_ZSHRC=yes CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_zsh_theme_and_plugins() {
  log "Installing Powerlevel10k + zsh plugins"
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # Powerlevel10k
  if [[ ! -d "$zsh_custom/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$zsh_custom/themes/powerlevel10k"
  fi

  # zsh-autosuggestions
  if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
      "$zsh_custom/plugins/zsh-autosuggestions"
  fi

  # zsh-syntax-highlighting
  if [[ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
      "$zsh_custom/plugins/zsh-syntax-highlighting"
  fi

  # fzf-tab
  if [[ ! -d "$zsh_custom/plugins/fzf-tab" ]]; then
    git clone --depth=1 https://github.com/Aloxaf/fzf-tab \
      "$zsh_custom/plugins/fzf-tab"
  fi

  # Note:
  # - "git" and "z" are built-in Oh My Zsh plugins (no clone needed).
}

patch_zshrc() {
  log "Patching ~/.zshrc"
  local zshrc="$HOME/.zshrc"
  touch "$zshrc"

  # Shell locale
  if ! grep -q 'LC_ALL=en_US.UTF-8' "$zshrc"; then
    cat >>"$zshrc" <<'EOF'

# Shell locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
EOF
  fi

  # Homebrew shellenv
  if ! grep -q 'brew shellenv' "$zshrc"; then
    cat >>"$zshrc" <<'EOF'

# Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
EOF
  fi

  # pyenv init
  if ! grep -q 'pyenv init' "$zshrc"; then
    cat >>"$zshrc" <<'EOF'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
EOF
  fi

  # fnm init
  if ! grep -q 'fnm env' "$zshrc"; then
    cat >>"$zshrc" <<'EOF'

# fnm
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
fi
EOF
  fi

  # pipx path (ensure ~/.local/bin is in PATH)
  if ! grep -q 'HOME/.local/bin' "$zshrc"; then
    cat >>"$zshrc" <<'EOF'

# pipx path
export PATH="$HOME/.local/bin:$PATH"
EOF
  fi

  # Theme
  if grep -q '^ZSH_THEME=' "$zshrc"; then
    sed -i '' 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$zshrc"
  else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >>"$zshrc"
  fi

  # Plugins
  if grep -q '^plugins=' "$zshrc"; then
    sed -i '' 's|^plugins=.*|plugins=(git z zsh-autosuggestions zsh-syntax-highlighting fzf-tab)|' "$zshrc"
  else
    echo 'plugins=(git z zsh-autosuggestions zsh-syntax-highlighting fzf-tab)' >>"$zshrc"
  fi

  # Optional fzf default
  if ! grep -q 'FZF_DEFAULT_COMMAND' "$zshrc"; then
    cat >>"$zshrc" <<'EOF'

# fzf
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
EOF
  fi
}

print_next_steps() {
  log "Finished"
  cat <<'EOF'

Manual steps required:
1) Set terminal font to "MesloLGS Nerd Font" (Terminal.app or iTerm2)
2) Restart zsh:
   exec zsh
3) Run Powerlevel10k wizard:
   p10k configure

Verify:
- python -V
- pipenv --version
- node -v
- npm -v
- go version

EOF
}

configure_git() {
  log "Configuring global git settings"

  git config --global user.name "dada8397"
  git config --global user.email "vincent8397@gmail.com"

  git config --global core.editor vim
  git config --global init.defaultBranch main
  git config --global pull.rebase true
  git config --global push.default current
  git config --global help.autocorrect 20

  git config --global commit.gpgsign true

  # Prefer SSH signing (can be overridden manually)
  git config --global gpg.format ssh
  git config --global user.signingkey ~/.ssh/id_ed25519.pub

  git config --global alias.d diff
  git config --global alias.s status
  git config --global alias.cm "commit -m"
  git config --global alias.cp cherry-pick
  git config --global alias.lo "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

  git config --global alias.sl \
    "stash list --pretty=format:%C(red)%h%C(reset)%x20-%x20(%C(bold magenta)%gd%C(reset))%x20%<(70,trunc)%s%C(green)%x20(%cr)%x20%C(bold blue)<%an>%C(reset)"

  git config --global alias.c "!sh -c 'git checkout \$(git branch -r | fzf)'"

  # SSH signing: allow local verification (git log/show --show-signature)
  if git config --global --get gpg.format | grep -q '^ssh$'; then
    log "Configuring SSH allowed signers for local verification"

    local allowed_dir="$HOME/.config/git"
    local allowed_file="$allowed_dir/allowed_signers"
    local signing_key
    local email

    mkdir -p "$allowed_dir"
    chmod 700 "$allowed_dir"

    email="$(git config --global user.email || true)"
    signing_key="$(git config --global user.signingkey || true)"

    if [[ -n "$email" && -n "$signing_key" && -f "$signing_key" ]]; then
      # Write or update allowed_signers (idempotent)
      grep -q "$email" "$allowed_file" 2>/dev/null || {
        printf "%s %s\n" "$email" "$(cat "$signing_key")" >> "$allowed_file"
        log "Added $email to SSH allowed_signers"
      }

      chmod 600 "$allowed_file"
      git config --global gpg.ssh.allowedSignersFile "$allowed_file"
    else
      log "Skipping SSH allowed signers setup (missing email or signing key)"
    fi
  fi

  log "Git configuration complete"
}

main() {
  configure_git
  require_macos
  ensure_xcode_clt
  ensure_homebrew
  ensure_brew_shellenv
  brew_install_packages
  configure_fzf
  setup_pyenv_latest_python
  install_pipenv_via_pipx
  setup_fnm_node_lts
  install_oh_my_zsh
  install_zsh_theme_and_plugins
  patch_zshrc
  print_next_steps
}

main "$@"
