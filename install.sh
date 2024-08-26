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


[[ $(uname) =~ (MSYS) ]] && export MSYS=winsymlinks:nativestict

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

function link_it() {
  if [[ $# -lt 2 ]] ; then
    echo "ERROR: 'link_it' requires 2 arguments!"
    echo
    echo "Usage: link_it home_rel_source rel_folder"
    exit 1
  fi

  source=$1
  dest=$2

  [[ ! -e "${__YADR_USER_PATH}" ]] && echo "ERROR: ${__YADR_USER_PATH} does NOT exist!" && exit 1

  [[ -z "$(command -v rsync)" ]] && echo "ERROR: rsync is NOT installed!" && exit 1

  mkdir -p "${__YADR_USER_PATH}/${dest}"

  dest=${__YADR_USER_PATH}/${dest}/${source}
  source=${HOME}/${source}

  if [[ -L ${source} ]] && [[ ! -e ${source} ]] && [[ -e ${dest} ]] ; then
    echo "ERROR: '${source}' is a broken symlink!"
    rm -f ${source}
  fi

  [[ -L ${source} ]] && [[ -e ${source} ]] && return

  mkdir -p "$(dirname "${dest}")"

  if [[ ! -L ${source} ]] && [[ -e ${source} ]] ; then
    echo "-> '${source}' is not a symlink..."
    if [[ ! -e ${dest} ]] ; then
      if [[ -d ${source} ]] ; then
        echo "-> Backing up folder ${source} ${dest}..."
        mkdir -p "$(dirname ${dest})"
        if [[ $(uname) =~ (MSYS) ]] ; then
          echo "Running: rsync -a --update /cygdrive${source} /cygdrive${dest}"
          rsync -a --update /cygdrive${source} /cygdrive${dest} || exit 1
        else
          echo "Running: rsync -a --update ${source} ${dest}"
          rsync -a --update ${source} ${dest} || exit 1
        fi
      elif [[ -f ${source} ]] ; then
        echo "-> Backing up file ${source} ${dest}..."
        if [[ $(uname) =~ (MSYS) ]] ; then
          echo "Running: rsync --update /cygdrive${source} /cygdrive${dest}"
          rsync --update /cygdrive${source} /cygdrive${dest} || exit 1
        else
          echo "Running: rsync --update ${source} ${dest}"
          rsync --update ${source} ${dest} || exit 1
        fi
      fi
    fi
  elif [[ ! -e "${dest}" ]] ; then
    echo "ERROR: NOT linking ${dest}->${source}..."
    echo "ERROR: '${dest}' does NOT exist!"
  fi

  if [[ -e "${dest}" ]] ; then
    [[ -e ${source} ]] && rm -rf ${source}

    echo "Linking ${dest}->${source}..."

    mkdir -p "$(dirname "${source}")"
    ln -nsf ${dest} ${source}
    result=$?

    echo "Link Result: ${result}"
    return ${result}
  fi
}

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

    echo git clone -b ${git_branch} --depth=1 ${git_repo} "${__YADR_USER_PATH}"
    git clone -b ${git_branch} --depth=1 ${git_repo} "${__YADR_USER_PATH}"
else
    pushd "${__YADR_USER_PATH}"
    git pull --rebase
    popd >/dev/null 2>&1
    echo "YADR User files are up to date."
fi

if [[ ! $(uname) =~ (MSYS) ]] ; then
  if [[ ! -d ${__YADR_PATH} ]]; then
      echo "Installing YADR..."
      git clone ${__YADR_REPO_URL} $HOME/src/dotfiles
      pushd $HOME/src/dotfiles
      git checkout ${__YADR_REPO_BRANCH}
      ./install.sh
      popd
  else
      pushd ${__YADR_PATH} >>/dev/null 2>&1
      echo "Updating YADR..."
      git pull --rebase
      rake update
      echo "YADR update is complete!."
      popd >>/dev/null 2>&1
  fi
fi

echo "__YADR_USER_DOTFILES: ${__YADR_USER_DOTFILES[@]}"

for dotfile in "${__YADR_USER_DOTFILES[@]}"; do
  echo "Running: link_it $dotfile ${__YADR_USER_DOTFILES_FOLDER}"
  link_it $dotfile ${__YADR_USER_DOTFILES_FOLDER}
done

