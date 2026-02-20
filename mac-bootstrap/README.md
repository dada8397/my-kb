# mac-bootstrap (MVP)

本專案用於在新 macOS 機器上快速建立開發環境，包含：
- Homebrew
- GitHub CLI（`gh`）登入流程（選項 A）
- zsh + Oh My Zsh
- Powerlevel10k 主題 + Nerd Font（由腳本安裝）
- 外掛：git、z、zsh-autosuggestions、zsh-syntax-highlighting、fzf-tab
- 工具：pyenv + 最新 Python、pipx + pipenv、fnm + Node.js LTS、Go、fzf、ripgrep、jq

> 注意：
> - 腳本會安裝 Nerd Font，但**仍需手動在終端機中設定字型**（Terminal.app 或 iTerm2）。
> - 腳本設計為可安全重複執行。

---

## 0) 前置需求（新 Mac）

### 安裝 Xcode Command Line Tools（必要）
```sh
xcode-select --install
```

若出現圖形化提示，完成安裝後即可繼續。

---

## 1) 安裝 Homebrew（只需一次）

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

安裝完成後，確認 `brew` 可用：
```sh
brew --version
```

若找不到 `brew`，請開新終端機視窗，或執行其一：
```sh
eval "$(/opt/homebrew/bin/brew shellenv)"     # Apple Silicon
# 或
eval "$(/usr/local/bin/brew shellenv)"        # Intel
```

---

## 2) 選項 A：使用 GitHub CLI（建議用於私人倉庫）

### 安裝 `gh`
```sh
brew install gh
```

### 登入
```sh
gh auth login
```

確認登入狀態：
```sh
gh auth status
```

### 複製本倉庫
```sh
gh repo clone dada8397/my-kb ~/my-kb
cd ~/my-kb
```

## 5) Git 簽章（手動但引導式）

腳本會自動設定大部分 Git 選項。
Commit 簽章需要**你做一次手動決定**。

### SSH 簽章

1. 若尚未有 SSH 金鑰，請產生：
```sh
ssh-keygen -t ed25519 -C "vincent8397@gmail.com"
```

2. 將金鑰加入 ssh-agent：
```sh
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

3. 在 GitHub 上將此金鑰註冊為**簽章金鑰**：
```sh
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing
```

4. 驗證：
```sh
git log --show-signature -1
```

---

## 3) 執行 bootstrap 腳本

```sh
chmod +x scripts/bootstrap-mac.sh
./scripts/bootstrap-mac.sh
```

---

## 4) 手動步驟（必要）

### 4.1 設定終端機字型
腳本會安裝：**MesloLGS Nerd Font**

#### Terminal.app
1. Terminal -> 設定
2. 描述檔 -> （你的描述檔）-> 文字
3. 字型 -> 選擇 **MesloLGS Nerd Font**

#### iTerm2
1. iTerm2 -> Settings
2. Profiles -> Text
3. Font -> 選擇 **MesloLGS Nerd Font**

### 4.2 重新啟動 zsh
關閉並重新開啟終端機，或執行：
```sh
exec zsh
```

### 4.3 設定 Powerlevel10k
執行：
```sh
p10k configure
```

---

## 5) 驗證清單

```sh
brew --version
gh --version
zsh --version
python -V
pipenv --version
node -v
npm -v
go version
fzf --version
rg --version
jq --version
```

---

## 疑難排解

### `p10k` 圖示顯示異常
- 再次確認終端機字型已設為 **MesloLGS Nerd Font**
- 重新啟動終端機

### 找不到 `pipenv`
- 重新啟動終端機
- 或執行：
```sh
export PATH="$HOME/.local/bin:$PATH"
pipenv --version
```

### 找不到 `pyenv`
- 重新啟動終端機
- 或執行：
```sh
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv --version
```

---

## 腳本會變更的項目
- 透過 Homebrew 安裝套件
- 將 Oh My Zsh 安裝至 `~/.oh-my-zsh`（若尚未存在）
- 將外掛安裝至 `~/.oh-my-zsh/custom/`
- 更新 `~/.zshrc`：
  - 載入 Homebrew shellenv
  - 初始化 pyenv 與 fnm
  - 設定主題為 powerlevel10k
  - 啟用外掛
