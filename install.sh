#!/usr/bin/env bash

function unlink_profile() {
  if [[ $# -lt 1 ]] ; then
    echo "ERROR: 'unlink_profile' requires 1 argument!"
    echo
    echo "Usage: unlink_profile source_file/folder"
    exit 1
  fi

  [[ -n ${__YADR_USER_UNLINK_DEPTH} ]] && find_args="-maxdepth ${__YADR_USER_UNLINK_DEPTH}" || find_args=""

  profile_files=($(find ~/ -lname "*${__YADR_USER_FOLDER_NAME}/${1}/*" ${find_args} -exec ls -ld {} + | awk '{print $9 ":" $11}'))

  echo "profile_files: ${profile_files[@]}"

  read -p "Unlinking and restoring ${#profile_files[@]} profile files. Continue? [y/N] " response
  if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]] ; then
    exit 0
  fi

  for profile_file in "${profile_files[@]}"; do
    echo "profile_file: ${profile_file}"
    link=$(echo "${profile_file}" | cut -d':' -f1)
    link_target=$(echo "${profile_file}" | cut -d':' -f2)
    if [[ -e "${link_target}" ]]; then
      echo "Unlinking/Restoring '${link}' -> '${link_target}'..."
      if [[ -n "${__YADR_DRY_RUN}" ]]; then
        echo rm -f "${link}"
      else
        rm -f "${link}"
      fi

      if [[ -d "${link_target}" ]]; then
        if [[ -n "${__YADR_DRY_RUN}" ]]; then
          echo cp -Rp "${link_target}" "${link}"
        else
          cp -Rp "${link_target}" "${link}"
        fi
      else
        if [[ -n "${__YADR_DRY_RUN}" ]]; then
          echo cp -p "${link_target}" "${link}"
        else
          cp -p "${link_target}" "${link}"
        fi
      fi
    fi
  done
}

function link_it() {
  if [[ $# -lt 2 ]] ; then
    echo "ERROR: 'link_it' requires 2 arguments!"
    echo
    echo "Usage: link_it home_rel_source rel_folder"
    exit 1
  fi

  source=$1
  dest=$2
  __YADR_USER_CFG_FOLDER=${dest}

  [[ ! -e "${__YADR_USER_PATH}" ]] && echo "ERROR: ${__YADR_USER_PATH} does NOT exist!" && exit 1

  [[ -z "$(command -v rsync)" ]] && echo "ERROR: rsync is NOT installed!" && exit 1

  mkdir -p "${__YADR_USER_PATH}/${dest}"

  dest=${__YADR_USER_PATH}/${dest}/${source}
  source=${HOME}/${source}

  if [[ ! ${dest} =~ (/${__YADR_USER_CFG_FOLDER}/) ]] ; then
    echo "-> ERROR: '${source}' is a broken symlink!"
    rm -f "${source}"
  elif [[ -L ${source} ]] && [[ ! -e ${source} ]] && [[ -e ${dest} ]] ; then
    echo "-> ERROR: '${source}' is a broken symlink!"
    rm -f "${source}"
  fi

  [[ -L ${source} ]] && [[ -e ${source} ]] && return
  echo "-> Linking ${source} to ${dest}..."

  mkdir -p "$(dirname "${dest}")"

  if [[ ! -L "${source}" ]] && [[ -e "${source}" ]]; then
    echo "-> '${source}' is not a symlink..."
    if [[ ! -e "${dest}" ]]; then
      if [[ -d "${source}" ]]; then
        mkdir -p "$(dirname "${dest}")"
        if [[ ${__YADR_OS} == windows ]]; then
          echo "-> Running: rsync -a --update /cygdrive${source} /cygdrive${dest}"
          rsync -a --update "/cygdrive${source}" "/cygdrive${dest}" || exit 1
        else
          echo "-> Running: rsync -a --update ${source} ${dest}"
          rsync -a --update "${source}" "${dest}" || exit 1
        fi
      elif [[ -f "${source}" ]]; then
        if [[ ${__YADR_OS} == windows ]]; then
          echo "-> Running: rsync --update /cygdrive${source} /cygdrive${dest}"
          rsync --update "/cygdrive${source}" "/cygdrive${dest}" || exit 1
        else
          echo "-> Running: rsync --update ${source} ${dest}"
          rsync --update "${source}" "${dest}" || exit 1
        fi
      fi
    fi
  # elif [[ ! -e "${dest}" ]]; then
  #   echo "-> ERROR: NOT linking ${dest}->${source}..."
  #   echo "-> ERROR: '${dest}' does NOT exist!"
  fi

  dest_dir="$(dirname "${source}")"
  if [[ ! -d "${dest_dir}" ]] ; then
    # if  [[ ${__YADR_OS} == darwin ]] ; then
    #   mkdir "${dest_dir}"
    # else
    #   mkdir -p "${dest_dir}
    # fi

    echo "WARNING: Not linking ${dest} -> ${source} because ${dest_dir} does not exist!"
    return
  fi

  if [[ -e "${dest}" ]]; then
    [[ -e "${source}" ]] && rm -rf "${source}"

    echo "-> Linking ${dest} -> ${source}..."

    mkdir -p "$(dirname "${source}")"
    ln -nsf "${dest}" "${source}"
    result=$?

    return ${result}
  fi
}

function install_zipped_application() {
    local destinationPath=$1
    local name=$2
    local url=$3
    local expectedHash=$4
    local expectedHashAlgorithm=${5:-sha256sum}

    local localZipPath="/tmp/${name}.zip"

    if [[ -z "$(command -v curl)" ]]; then
        echo "ERROR: curl is not installed."
        return 1
    fi

    if [[ -z "$(command -v unzip)" ]]; then
        echo "ERROR: unzip is not installed."
        return 1
    fi

    # Download the file
    curl -o "$localZipPath" "$url"

    # Calculate the hash
    local actualHash
    if [ "$expectedHashAlgorithm" == "sha256sum" ]; then
        actualHash=$(sha256sum "$localZipPath" | awk '{ print $1 }')
    else
        echo "Unsupported hash algorithm: $expectedHashAlgorithm"
        return 1
    fi

    # Verify the hash
    if [ "$actualHash" != "$expectedHash" ]; then
        echo "$name downloaded from $url to $localZipPath has $actualHash hash that does not match the expected $expectedHash"
        return 1
    fi

    # Extract the zip file
    unzip "$localZipPath" -d "$destinationPath"

    # Remove the zip file
    rm "$localZipPath"
}

function install_rsync() {
    # see https://github.com/rgl/rsync-vagrant/releases
    version="${1}"
    rsyncHome="${2}"
    sha256sum="${3}"

    if [[ -z "$version" ]] || [[ -z "$rsyncHome" ]] || [[ -z "$sha256sum" ]]; then
        echo "ERROR: RSYNC_VERSION, RSYNC_HOME, and RSYNC_SHA256SUM must be set in the configuration file."
        return 1
    fi

    if [[ ! -f "$rsyncHome/rsync.exe" ]] || [[ ! -f "~/bin/rsync.exe" ]]; then
        install_zipped_application \
            "$rsyncHome" \
            "rsync" \
            "https://github.com/rgl/rsync-vagrant/releases/download/v$version/rsync-vagrant-$version.zip" \
            "$sha256sum"
        mkdir -p "~/bin"
        ln -nsf "$rsyncHome/rsync.exe" "~/bin/rsync.exe"
    fi
}

# Usage: ./install.sh <profile folder name> [unlink]
#
# Example: ./install.sh personal
#
# - Backup all specified files/folders into the 'personal' profile folder,
# - Link the backed up files in the 'personal' profile folder to the original location user's home folder.

MAIN_NAME=$(basename "$0")
MAIN_PID=$$
MAIN_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )

if [[ $# -gt 1 ]] ; then
  if [[ $# -eq 2 ]] && [[ "$2" == "unlink" ]] ; then
    echo "Unlinking profile '$1'..."
    unlink_profile "$1"
    exit 0
  else
    echo "${MAIN_NAME} ERROR: 'install.sh' requires 1 argument, got $#!"
    echo "Usage: install.sh dotfiles_folder_user [unlink]"
    exit 1
  fi
elif [[ -z "$1" ]] ; then
  echo "${MAIN_NAME} ERROR: 'install.sh' requires 1 argument!"
  echo
  echo "Usage: install.sh dotfiles_folder_user [unlink]"
  exit 1
fi

if [[ ! -f $1.conf ]] ; then
  echo "${MAIN_NAME} ERROR: $1.conf does NOT exist!"
  exit 1
fi

__YADR_USER_DOTFILES_FOLDER=$1
__YADR_USER_CONFIG=$(realpath "$1.conf")

echo "-> Sourcing '${__YADR_USER_CONFIG}'..."
# shellcheck disable=SC1090
source "${__YADR_USER_CONFIG}"

export __YADR_FOLDER_NAME=.yadr
if [[ ${__YADR_OS} == windows ]]; then
  export MSYS=winsymlinks:nativestict
  export CYGWIN=winsymlinks:nativestict

  install_rsync "${__YADR_RSYNC_VERSION}" "${__YADR_USER_RSYNC_HOME}" "${__YADR_RSYNC_SHA256SUM}"
fi

export __YADR_PATH="$HOME/$__YADR_FOLDER_NAME"
export __YADR_USER_PATH="${__YADR_PATH}.user"
export __YADR_USER_FOLDER_NAME=$(basename ${__YADR_USER_PATH})
export __YADR_REPO_URL=https://github.com/${__YADR_GITHUB_ORG}/${__YADR_REPO_NAME}
export __YADR_USER_REPO_URL=https://github.com/${__YADR_USER_GITHUB_ORG}/${__YADR_USER_REPO_NAME}

__YADR_USER_PROFILE=$1

read -rp "This script will install '${__YADR_GITHUB_ORG}' YADR, backup and/or link the '${__YADR_USER_PROFILE}' profiles dotfiles to their proper locations. Continue? [y/N] " response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]] ; then
  exit 0
fi

if [ ! -d "${__YADR_USER_PATH}" ]; then
    echo "Installing YADR User files for the first time"

    git_repo="${__YADR_USER_REPO_URL}"
    git_branch="${__YADR_USER_REPO_BRANCH}"
    if [ -n "${__YADR_DEBUG}" ] ; then
        git_repo=$(git ls-remote --get-url 2>/dev/null)
        git_branch=$(git branch --show-current)
    fi

    [ -n "${__YADR_DEBUG}" ] && env | grep "__YADR_"
    echo "git_repo: ${git_repo}"
    echo "git_branch: ${git_branch}"

    echo git clone -b "${git_branch}" --depth=1 "${git_repo}" "${__YADR_USER_PATH}"
    git clone -b "${git_branch}" --depth=1 "${git_repo}" "${__YADR_USER_PATH}"
else
    pushd "${__YADR_USER_PATH}" >/dev/null 2>&1 || exit 1
    git pull --rebase
    popd >/dev/null 2>&1 || exit 1
    echo "YADR User files are up to date."
fi

if [[ ! ${__YADR_OS} == windows ]] ; then
  if [[ ! -d ${__YADR_PATH} ]]; then
      echo "Installing YADR..."
      git clone "${__YADR_REPO_URL}" "$HOME/src/dotfiles"
      pushd "$HOME/src/dotfiles" >>/dev/null 2>&1 || exit 1
      git checkout "${__YADR_REPO_BRANCH}"
      ./install.sh
      popd >>/dev/null 2>&1 || exit 1
  else
      pushd "${__YADR_PATH}" >>/dev/null 2>&1 || exit 1
      echo "Updating YADR..."
      git pull --rebase
      rake update
      echo "YADR update is complete!."
      popd >>/dev/null 2>&1 || exit 1
  fi
fi

# echo "__YADR_USER_DOTFILES: ${__YADR_USER_DOTFILES[@]}"
for dotfile in "${__YADR_USER_DOTFILES[@]}"; do
  echo "Linking '${dotfile}'..."
  link_it "$dotfile" "${__YADR_USER_DOTFILES_FOLDER}"
done
