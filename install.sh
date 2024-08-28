#!/usr/bin/env bash

# Usage: ./install.sh [relative folder name]
#
# Example: ./install.sh personal
#
# This will backup all specified files into 'personal', if not done so already,
# and then link the backed up files in the 'personal' folder to the original
# location user's home folder.

MAIN_NAME=$(basename "$0")
MAIN_PID=$$
MAIN_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )

function unstow() {
  if [[ $# -lt 1 ]] ; then
    echo "ERROR: 'unstow' requires 1 argument!"
    echo
    echo "Usage: unstow source_file/folder"
    exit 1
  fi

  stowed_files=($(find ~/ -lname '*.yadr.user*' -exec ls -ld {} + | awk '{print $9 ":" $11}'))

  for stowed_file in "${stowed_files[@]}" ; do
    echo "stowed_file: ${stowed_file}"
    link=$(echo $stowed_file | cut -d':' -f1)
    link_target=$(echo $stowed_file | cut -d':' -f2)
    if [[ -e ${link_target} ]] ; then
      echo "Unlinking/Restoring '${link}' -> '${link_target}'..."
      if [[ -n "${__YADR_DRY_RUN}" ]] ; then
        echo rm -f ${link}
      else
        rm -f ${link}
      fi

      if [[ -d ${link_target} ]] ; then
        if [[ -n "${__YADR_DRY_RUN}" ]] ; then
          echo cp -Rp ${link_target} ${link}
        else
          cp -Rp ${link_target} ${link}
        fi
      else
        if [[ -n "${__YADR_DRY_RUN}" ]] ; then
          echo cp -p ${link_target} ${link}
        else
          cp -p ${link_target} ${link}
        fi
      fi
    fi
  done
}

function stow_it() {
  if [[ $# -lt 2 ]] ; then
    echo "ERROR: 'stow_it' requires 2 arguments!"
    echo
    echo "Usage: stow_it <package>:<source_file/folder> <stow_folder>"
    exit 1
  fi

  [[ -z "$(command -v stow)" ]] && echo "ERROR stow_it: stow is NOT installed!" && exit 1
  [[ -z "$(command -v rsync)" ]] && echo "ERROR stow_it: rsync is NOT installed!" && exit 1
  [[ ! -e "${__YADR_USER_PATH}" ]] && echo "ERROR stow_it: ${__YADR_USER_PATH} does NOT exist!" && exit 1
  [[ ${1} =~ ^[a-zA-Z0-9]+:.+$ ]] || echo "ERROR stow_it: Invalid argument format!  Must use <package>:<source_file/folder>." && exit 1

  package=$(echo $1 | cut -d: -f1)
  source=$(echo $1 | cut -d: -f2)

  [[ -z "${package}" ]] && echo "ERROR stow_it: 'package' is empty!" && exit 1
  [[ -z "${source}" ]] && echo "ERROR stow_it: 'source' is empty!" && exit 1

  dest=$2

  if [[ -n "${__YADR_DRY_RUN}" ]] ; then
    echo mkdir -p "${__YADR_USER_PATH}/${dest}"
  else
    mkdir -p "${__YADR_USER_PATH}/${dest}"
  fi

  dest=${__YADR_USER_PATH}/${package}/${dest}

  source=${HOME}/${source}

  if [[ -L ${source} ]] && [[ ! -e ${source} ]] && [[ -e ${dest} ]] ; then
    echo "ERROR: '${source}' is a broken symlink!"
    if [[ -n "${__YADR_DRY_RUN}" ]] ; then
      echo rm -f ${source}
    else
      rm -f ${source}
    fi
  fi

  [[ -L ${source} ]] && [[ -e ${source} ]] && return

  mkdir -p "$(dirname "${dest}")"

  if [[ ! -L ${source} ]] && [[ -e ${source} ]] ; then
    echo "-> '${source}' is not a symlink..."
    if [[ ! -e ${dest} ]] ; then
      if [[ -d ${source} ]] ; then
        echo "-> Backing up folder ${source} ${dest}..."
        if [[ -n "${__YADR_DRY_RUN}" ]] ; then
            echo mkdir -p "$(dirname ${dest})"
        else
            mkdir -p "$(dirname ${dest})"
        fi

        if [[ $(uname) =~ (MSYS) ]] ; then
          echo "Running: rsync -a --update /cygdrive${source} /cygdrive${dest}"
          if [[ -n "${__YADR_DRY_RUN}" ]] ; then
            echo rsync -a --update /cygdrive${source} /cygdrive${dest}
          else
            rsync -a --update /cygdrive${source} /cygdrive${dest} || exit 1
          fi
        else
          echo "Running: rsync -a --update ${source} ${dest}"
          if [[ -n "${__YADR_DRY_RUN}" ]] ; then
            echo rsync -a --update ${source} ${dest}
          else
            rsync -a --update ${source} ${dest} || exit 1
          fi
        fi
      elif [[ -f ${source} ]] ; then
        echo "-> Backing up file ${source} ${dest}..."
        if [[ $(uname) =~ (MSYS) ]] ; then
          echo "Running: rsync --update /cygdrive${source} /cygdrive${dest}"
          if [[ -n "${__YADR_DRY_RUN}" ]] ; then
            echo rsync --update /cygdrive${source} /cygdrive${dest}
          else
            rsync --update /cygdrive${source} /cygdrive${dest} || exit 1
          fi
        else
          echo "Running: rsync --update ${source} ${dest}"
          if [[ -n "${__YADR_DRY_RUN}" ]] ; then
            echo rsync --update ${source} ${dest}
          else
            rsync --update ${source} ${dest} || exit 1
          fi
        fi
      fi
    fi
  fi

  if [[ -e "${dest}" ]] && [[ -e ${source} ]] ; then
    echo "Removing ${source}..."
    if [[ -n "${__YADR_DRY_RUN}" ]] ; then
      echo rm -rf ${source}
    else
      rm -rf ${source}
    fi
  fi

    # echo "Linking ${dest}->${source}..."

    # mkdir -p "$(dirname "${source}")"
    # ln -nsf ${dest} ${source}
    # result=$?

    # echo "Link Result: ${result}"
    # return ${result}
  # fi
}

function main() {
  [[ $(uname) =~ (MSYS) ]] && export MSYS=winsymlinks:nativestict

  if [[ $# -eq 2 ]] && [[ $1 == unstow ]] ; then
    unstow $@
    exit 0
  fi

  if [[ -z "$1" ]] ; then
    echo "${MAIN_NAME} ERROR: 'install.sh' requires 1 argument!"
    echo
    echo "Usage: install.sh dotfiles_folder_user"
    exit 1
  fi

  if [[ ! -f $1.conf ]] ; then
    touch $1.conf
    echo "#!/usr/bin/env bash" > $1.conf
    echo "source ${MAIN_DIR}/.yadr.user.conf" >> $1.conf
    echo "source ${MAIN_DIR}/.yadr.user.files.conf" >> $1.conf
    mkdir -p "${MAIN_DIR}/$1"
  fi

  __YADR_USER_DOTFILES_FOLDER=$1
  __YADR_USER_CONFIG=$(realpath $1.conf)
  source ${__YADR_USER_CONFIG}

  echo "Sourcing '${__YADR_USER_CONFIG}'..."


  if [ ! -d "${__YADR_USER_PATH}" ]; then
      echo "Installing YADR User files for the first time"

      git_repo=$(echo ${__YADR_USER_REPO_URL})
      git_branch=$(echo ${__YADR_USER_REPO_BRANCH})

      if [ -n "${__YADR_DEBUG}" ] ; then
          git_repo=$(git ls-remote --get-url 2>/dev/null)
          git_branch=$(git branch --show-current)
      fi

      [ -n "${__YADR_DEBUG}" ] && env | grep "__YADR_"
      echo "git_repo: ${git_repo}"
      echo "git_branch: ${git_branch}"

      echo "Cloning ${git_repo} into ${__YADR_USER_PATH}"

      if [[ -n "${__YADR_DRY_RUN}" ]] ; then
        echo git clone -b ${git_branch} --depth=1 ${git_repo} "${__YADR_USER_PATH}"
      else
        git clone -b ${git_branch} --depth=1 ${git_repo} "${__YADR_USER_PATH}"
      fi
  else
      echo "YADR User files are already installed.  Updating to the latest version..."
      if [[ -n "${__YADR_DRY_RUN}" ]] ; then
        echo git -C "${__YADR_USER_PATH}" pull --rebase
      else
        git -C "${__YADR_USER_PATH}" pull --rebase
      fi
      echo "YADR User files are up to date."
  fi

  if [[ ! $(uname) =~ (MSYS) ]] ; then
    if [[ ! -d ${__YADR_PATH} ]]; then
      echo "Installing YADR..."
      if [[ -n "${__YADR_DRY_RUN}" ]] ; then
        echo git clone ${__YADR_REPO_URL} $HOME/src/dotfiles
        echo pushd $HOME/src/dotfiles
        echo git checkout ${__YADR_REPO_BRANCH}
        echo ./install.sh
        echo popd
      else
        git clone ${__YADR_REPO_URL} $HOME/src/dotfiles
        pushd $HOME/src/dotfiles >>/dev/null 2>&1
        git checkout ${__YADR_REPO_BRANCH}
        ./install.sh
        popd >>/dev/null 2>&1
      fi
    else
      echo "Updating YADR..."

      if [[ -n "${__YADR_DRY_RUN}" ]] ; then
        echo pushd ${__YADR_PATH}
        echo git pull --rebase
        echo rake update
        echo popd
      else
        pushd ${__YADR_PATH} >>/dev/null 2>&1
        git pull --rebase
        rake update
        popd >>/dev/null 2>&1
      fi
      echo "YADR update is complete!."
    fi
  fi

  echo "__YADR_USER_DOTFILES: ${__YADR_USER_DOTFILES[@]}"

  for dotfile in "${__YADR_USER_DOTFILES[@]}"; do
    echo "Running: stow_it $dotfile ${__YADR_USER_DOTFILES_FOLDER}"
    stow_it $dotfile ${__YADR_USER_DOTFILES_FOLDER}
  done

  if [[ -n "${__YADR_DRY_RUN}" ]] ; then
    echo stow -d ${__YADR_USER_DOTFILES_FOLDER} -t ${HOME} -v --simulate --restow
  else
    stow -d ${__YADR_USER_DOTFILES_FOLDER} -t ${HOME} -v --restow
  fi
}

main $@
