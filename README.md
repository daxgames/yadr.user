# Overview of `yadr.user`

**NOTE: Please verify you are not version controlling any sensitive information in your dotfiles before pushing them to a public repository.**

`yadr.user` is an add-on/installer for YADR(https://github.com/daxgames/dotfiles) that contains a mechanism to backup and
version control user-specific dotfiles and apply them to the user's home directory on a new machine.

`yadr.user` uses the concept of dotfile profiles to allow the user to have multiple configurations for different machines or different configurations.

The user creates a configuration file in the root folder of this repository that contains a list of user-specific dotfiles to backup and link to the user's home directory.

Example:

`personal_linux.conf`, `personal_macos.conf`, `personal_windows.conf`.

Each configuration file contains a list of user-specific dotfiles that are backed up from the users `home` folder into a profile folder in this repository and then linked back to the user's home directory.

The user can then version control these dotfiles and sync them across different machines.

Running `install.sh personal_linux` will:

1. Back-up the users dotfiles specified in `personal_linux.conf` to the `personal_linux` folder in this repository.
2. Install YADR from the configured location, if it's not already installed.
    - If YADR is already installed it will run a YADR update.
3. Link the user dotfiles from the `personal_linux` folder in this repo to the user's `${HOME}` folder.

`./install.sh personal_linux`, `./install.sh personal_macos`, or `./install.sh personal_windows` would result in the following profile folders being created in this repository:

```
personal_linux
personal_macos
personal_windows
```

The user can then version control these dotfiles and sync them across different machines.

## Features

- Overide default settings using the `.yadr.user.conf.local` file. _Note: This file is not version controlled!_
    - Override the location and/or branch of the YADR repository if .yadr is forked.
    - Override the location and/or branch of the YADR user repository if .yadr.user is forked.
    - Override the rsync version/sha256sum to use on Windows machines.
- Install YADR if it's not already installed.
- Run YADR update if YADR is already installed.
- Backup user-specific dotfiles to a profile folder in this repository.
    - Create multiple configuration files for different machines or different configurations.
- Link user-specific dotfiles from the profile folder to the user's home directory.

### Usage

1. Make a copy of this repository in your GitHub user account. This step is REQUIRED!
    - _Note: Do not fork this repository directly!_
    - Clone it, change the remote an push it to a repository you create in GitHub.
    - Run the following commands, changing `[your user]` to your GitHub user account.:

        ```bash
        # Authenticate to Github using GH CLI and follow the prompts.
        gh auth login

        # Clone the repository.
        git clone https://github.com/daxgames/yadr.user.git ~/.yadr.user

        # Change the remote.
        git remote set-url origin https://github.com/[your user]/yadr.user.git

        # Create the repository in Github and push the content.
        gh repo create --private --push [your user]/yadr.user
        ```

2. Create a copy of `.yadr.user.conf.local.default` called `.yadr.user.conf.local` in the root folder of this repository and modify it to suit your needs.
3. Create a configuration file, for example `personal_linux.conf`, in the root folder of this repository.

    ```bash
    source ${MAIN_DIR}/.yadr.user.conf
    source ${MAIN_DIR}/.yadr.user.files.conf

    # Additional user-specific dotfiles relative to the user's home directory.
    __YADR_USER_DOTFILES+=(.config/gh/config.yml \
      .config/bat \
      .config/gh/hosts.yml \
      .config/nvim/lua/settings/userplugin-copilot-chat.lua \
      .config/nvim/plugins/userplugin-copilot-chat.vim \
      .config/nvim/settings/userplugin-copilot-chat.vim
    )
    ```

4. Run `./install.sh personal_linux` to backup and/or link the user-specific dotfiles.
5. Verify the following:
    - There is no sensitive information in the user-specific dotfiles.
    - The user-specific dotfiles are backed up to the profile folder in this repository.
    - The user-specific dotfiles are linked to the user's home directory.
        - Run the following command to verify the user-specific dotfiles are linked to the user's home directory.

        ```bash
        find $HOME -lname "*.yadr.user*" -maxdepth 5 -exec ls -ld {} + | awk '{print $9 ":" $11}'
        ```

        - If the command does not return everything you can change the `-maxdepth [n]` value to a higher number or remove it to search the entire home directory.

6. Commit and push the changes to your forked repository.

You can create multiple configuration files for different machines or different configurations.

### Contributing

1. Fork this repository.
2. Create a feature branch.
3. Make your changes.
4. Create a pull request.

### License

This project is licensed under the MIT License - see the [MIT-LICENSE.txt](MIT-LICENSE.txt) file for details.
