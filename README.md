# Modular Nix Flakes Dotfiles

A reproducible, declarative multi-host configuration powered by **Nix Flakes**, **nix-darwin** (for macOS system settings and launchd daemons), and **Home Manager** (for user dotfiles and CLI packages).

---

## Architecture Overview

```
.
├── bootstrap.sh               # One-step installer for macOS
├── flake.nix                  # Entrypoint for all host profiles
├── flake.lock                 # Pinned dependency locks (Nixpkgs, nix-darwin, Home Manager)
├── config/                    # Native app configs (Neovim, Ghostty, Alacritty, Yabai, Starship)
├── hosts/                     # Host profile definitions
│   ├── personal-mac/          # macOS system defaults, Homebrew, and user profile (smoochii)
│   ├── personal-linux/        # Standalone Home Manager profile for Linux (smoochii)
│   └── cyber-vm/              # Standalone Home Manager profile for Kali Linux VM (kali)
└── modules/                   # Reusable configuration blocks
    ├── darwin/                # macOS system defaults & window manager daemons
    └── shared/                # Zsh, Git, Tmux, Starship, SSH, Neovim, Ghostty
```

---

## 🚀 Installation & Bootstrapping

### 1. macOS (Apple Silicon - `smoochii-mac`)

On a fresh or existing Mac, run the bootstrap script:

```bash
./bootstrap.sh
```

> **What it does:**
> 1. Installs Nix via the Determinate Systems installer if missing.
> 2. Bootstraps `nix-darwin` and applies system defaults (scrollbars, key repeat rates, Xcode/Simulator settings).
> 3. Enables window manager services (`yabai`, `skhd`, `sketchybar`).
> 4. Activates Home Manager to install CLI tools and create symlinks for your configs.

### 2. Personal Linux (`smoochii-linux`)

On any Linux desktop or server:

```bash
nix run github:nix-community/home-manager -- switch --flake .#smoochii@smoochii-linux
```

### 3. Cybersecurity Practice VM (`kali-linux`)

On a Kali Linux or penetration testing VM:

```bash
nix run github:nix-community/home-manager -- switch --flake .#kali@kali-linux
```

---

## 🔄 Updating Your Setup

### Apply Local Configuration Changes
After editing any `.nix` files or changing settings in `hosts/` or `modules/`:

* **macOS**:
  ```bash
  darwin-rebuild switch --flake .#smoochii-mac
  ```
* **Linux / VMs**:
  ```bash
  home-manager switch --flake .#smoochii@smoochii-linux
  ```

### Update Flake Dependencies (Nixpkgs, nix-darwin, Home Manager)
To upgrade all packages and system channels to their latest upstream versions:

```bash
# Update flake.lock
nix flake update

# Apply upgraded packages
darwin-rebuild switch --flake .#smoochii-mac
```

---

## 🛠️ Helpful Nix Commands & Options Cheat Sheet

### 1. Dry-Run Build (Test Without Applying System Changes)
Build the entire macOS system derivation into a local `./result` folder to verify syntax and package evaluation without touching your machine settings:

```bash
nix build .#darwinConfigurations.smoochii-mac.system
```

### 2. Inspect & Diff Generated Home Files Before Applying
Build a standalone Home Manager generation in `./result-home` to inspect or diff generated files (`.zshrc`, `.gitconfig`, `.ssh/config`) against your active `~` files:

```bash
# Build generated home files
nix build .#darwinConfigurations.smoochii-mac.config.home-manager.users.smoochii.home.activationPackage -o result-home

# Diff individual files against active dotfiles
diff -u ~/.zshrc result-home/home-files/.zshrc
diff -u ~/.gitconfig result-home/home-files/.config/git/config
diff -u ~/.ssh/config result-home/home-files/.ssh/config

# Diff all .config folders
diff -ur --color ~/.config result-home/home-files/.config
```

### 3. Detailed Error Tracing
If a build or evaluation fails, pass `--show-trace` to get the full stack trace:

```bash
darwin-rebuild switch --flake .#smoochii-mac --show-trace
```

### 4. Inspect Available Flake Outputs
To view all available system and home configurations in this repository:

```bash
nix flake show
```

### 5. Check Flake File Validity
To run sanity checks against `flake.nix`:

```bash
nix flake check
```

### 6. Clean Old Generations & Reclaim Disk Space
Nix keeps previous builds so you can roll back at any time. To clear old generations and free up disk space:

```bash
# Delete generations older than 7 days and collect garbage
nix-collect-garbage --delete-older-than 7d
```

---

## ✍️ How to Edit & Customize

* **Add CLI Tools / Fonts**: Edit `home.packages` in `hosts/personal-mac/home.nix` (or Linux profiles).
* **Add macOS GUI Apps / Casks**: Edit `homebrew.casks` in `hosts/personal-mac/default.nix`.
* **Edit Neovim / Ghostty / Alacritty**: Edit files directly inside `./config/nvim/`, `./config/ghostty/`, or `./config/alacritty/`. Because these are symlinked, changes take effect **instantly without needing to run `darwin-rebuild`**!
* **Add Shell Aliases / Keybindings**: Edit `modules/shared/zsh.nix`.
