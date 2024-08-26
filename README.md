# Overview of `yadr.user`

`yadr.user` is an add-on/installer for YADR(https://github.com/daxgames/dotfiles) that contains a mechanism to backup and 
version control user-specific dotfiles and apply them to the user's home directory on a new machine.

This repo contains a default configuration that can be used as is or customized in the `home.conf` file.

You can make a copy of the `home.conf` file and customize it to your needs.

`install.sh` takes a single argument, the name of the configuration file to use (without the `.conf` extension).

Running `install.sh home` will:

1. Back-up the user dotfiles specified in `home.conf` to the `home` folder in this repository.
    - Defaults are user specific files that YADR supports for user config adds and overrides.
2. Installs YADR if it's not already installed.
    - If YADR is installed it will run a YADR update.
3. Links the user dotfiles from the `home` folder in this repo to the user's `${HOME}` folder.

The result is a Git repo companion to YADR that contains user-specific dotfiles.

This allows the user to keep personalized dotfiles that may contain additional config
or even override settings in YADR with settings the user prefers in version control
and sync them across different machines.

## Installation

Fork the repository and clone it from your fork.

```bash
git clone https://github.com/[your org]/yadr.user` ~/.yadr.user"
cd ~/.yadr.user
./install.sh home
```

## Git setup

Setup `gh` as a git credential helper.

```
git config --global credential.helper '!gh auth git-credential'
```

# Login

Login to GitHub using `gh` as each account.

```
gh auth login --hostname github.com -p https
? How would you like to authenticate GitHub CLI?  [Use arrows to move, type to filter]
  Login with a web browser
> Paste an authentication token
? How would you like to authenticate GitHub CLI? Paste an authentication token
Tip: you can generate a Personal Access Token here https://github.com/settings/tokens
The minimum required scopes are 'repo', 'read:org', 'workflow'.
? Paste your authentication token: ********************************
- gh config set -h github.com git_protocol https
✓ Configured git protocol
✓ Logged in as 296951
! You were already logged in to this account
```

Switch between personal and work accounts.

```
gh auth switch -h github.com -u 296951
gh auth switch -h github.com -u personal
```
