#!/usr/bin/env bash

# Variable Definitions {{{
# Directories
declare THIS_EXEC="$(basename "${BASH_SOURCE[0]}")"
declare DOTFILES_HOME="$HOME/.dotfiles"
declare DOTFILES_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare IMPORT="$DOTFILES_REPO/bash/source"
declare DOTFILES_LINK="$DOTFILES_REPO/link"
declare DOTFILES_COPY="$DOTFILES_REPO/copy"
declare LINK_HOME="$DOTFILES_LINK/home"
declare LINK_CONFIG="$DOTFILES_LINK/config"
declare BACKUP_DIR="$DOTFILES_REPO/backup"
declare -a BACKUP_FILES=($(find "$LINK_HOME" -type f -exec basename '{}' \;))

# Filesystem directories to create

# Main projects directory
declare WS="$HOME/workspace"
# Practice projects directory
declare PRAC="$WS/practice"
# Directory for installed third-party applications
declare APPS="$HOME/applications"
# Third party archives directory
declare ARCHIVES="$APPS/archives"

# Program flags

# Run with extra logging
declare VERBOSE=false
# Force all actions that would otherwise involve answering a prompt
declare FORCE_INSTALL=false
# }}}

# Imports {{{
source "${IMPORT}/colors.bash"
source "${IMPORT}/functions_log.bash"
source "${IMPORT}/functions_os.bash"
# }}}

# Setup and Cleanup Functions {{{
# Move old dotfiles in $HOME to ~/.dotfiles/backup/ for safe keeping.
backup_old_dotfiles() {
  echoe "Backing up old dotfiles..."
  local oldFile
  mkdir -p "$BACKUP_DIR"
  for oldFile in "${BACKUP_FILES[@]}"; do
    if [ -f "$HOME/$oldFile" ]; then
      mv "$HOME/$oldFile" "$BACKUP_DIR/$oldFile"
    fi
  done
}

# Take care of backing up existing ~/.dotfiles directory
backup_existing_installation() {
  # Safe name for backup directory
  local oldDotfiles="$(mktemp -u "${DOTFILES_HOME}.bak.XXXXXXXXXX")"
  if [ -d "$DOTFILES_HOME" ]; then
    log_info "Backing up existing dotfiles installation to $oldDotfiles"
    mv "$DOTFILES_HOME" "$oldDotfiles"
  fi
}

# Figure out what to do if an existing dotfiles installation is found.
check_existing_installation() {
  log_info "Checking for existing dotfiles installation"
  if [ -d "$DOTFILES_HOME" ]; then
    warn "Existing dotfiles installation found at ${DOTFILES_HOME}!"
    echoe "An existing dotfiles installation was found at ${DOTFILES_HOME}."
    echoe "It must be removed before this installation can progress."
    local response=""
    while [[ ! "$response" =~ [YyNn] ]]; do
      echoe "Would you like to remove it and continue with the installation?" \
        "[y/n]"
      read -sn1 response
    done
    [[ "$response" =~ [Nn] ]] && echoe "Exiting." && exit 1
  else
    log_info "No dotfiles installation found."
  fi
}

# Performs initial setup.
setup() {
  log_info "Setting up..."
  if ! $FORCE_INSTALL; then
    check_existing_installation
  fi
  backup_old_dotfiles
  backup_existing_installation
}

# Cleanup after the program finishes.
cleanup() {
  log_info "Cleaning up..."
  # If backup directory is empty, remove it.
  if [[ -d "$BACKUP_DIR" && "$(ls -A "$BACKUP_DIR" &>/dev/null)" ]]; then
    rm -rf "$BACKUP_DIR"
  fi
}
trap cleanup EXIT
# }}}

# Help {{{

_help() {
  cat <<EOF
${THIS_EXEC}

Install tjtrabue's dotfiles on the current system.  For the most part, this
script just creates a bunch of symlinks, so it is highly non-destructive.  As
opposed to overwriting the user's existing dotfiles, this script backs up all
of the existing files before creating any symlinks. Nothing should be lost in
the process. Check the 'backup' directory created by this script if you wish to
restore your old dotfiles.

USAGE:
  ./${THIS_EXEC} [OPTIONS]

OPTIONS:
  -h | --help
    Print the help message (this message) and exit.

  -v | --verbose
    Run with extra logging.

  -f | --force
    Force dotfiles to install, assuming "yes" for all prompts.
    This option should be used with caution, as it may overwrite some of your
    files, even though this script tries hard not to do that.
EOF

  exit 0
}

# }}}

# Test Functions {{{
print_vars() {
  echoe "DOTFILES_REPO: ${DOTFILES_REPO}"
  echoe "DOTFILES_HOME: ${DOTFILES_HOME}"
}
# }}}

# Primary Functions {{{
# Link the ~/.config directory
init_config() {
  log_info "Initializing ~/.config directory."

  local homeConfig="$HOME/.config"
  [ -d "$homeConfig" ] && rm -rf "$homeConfig"
  ln -sf "$LINK_CONFIG" "$homeConfig"
  succ "Done."
}

# Create symlinks
link_dotfiles() {
  log_info "Linking dotfiles"
  # Link the repository to ~/.dotfiles
  ln -s "$DOTFILES_REPO" "$DOTFILES_HOME"
  # Link $HOME files
  find "$LINK_HOME" -type f -exec ln -sf '{}' "$HOME/" \;
  succ "Linking complete."
}

# Copy one-time transfer files
copy_dotfiles() {
  log_info "Copying dotfiles"
  find "$DOTFILES_COPY" -maxdepth 1 -mindepth 1 -type f -exec cp -f '{}' "$HOME/" \;
  succ "Copying complete"
}

add_extra_os_vars() {
  log_info "Injecting additional OS variables into $HOME/.vars"
  local os="$(getosinfo | head -1 | sed 's/Distribution:\s*//')"
  local extraVarsDir="$DOTFILES_REPO/copy/var_files"
  local extraVarsLinuxDir="$extraVarsDir/linux"
  local markerString="#<additional-vars-insert>"
  local extraVarsFile

  case "$os" in
  "Arch Linux")
    extraVarsFile="$extraVarsLinuxDir/arch_vars.bash"
    ;;

  *)
    warn "No extra vars to add for OS: $os"
    ;;
  esac

  if [ -f "$extraVarsFile" ]; then
    sed -i -e "/$markerString/r $extraVarsFile" "$HOME/.vars"
  fi

  # Get rid of marker string in ~/.vars
  sed -i "/$markerString/d" "$HOME/.vars"
  succ "Done injecting additional variables"
}

ensure_dirs_present() {
  log_info "Creating important directories"

  local dirs=(
    "$WS"
    "$PRAC"
    "$APPS"
    "$ARCHIVES"
  )
  local dir

  for dir in "${dirs[@]}"; do
    mkdir -p "$dir" &>/dev/null
  done
}

# Main that calls all subroutines
main() {
  setup
  copy_dotfiles
  link_dotfiles
  ensure_dirs_present
  init_config
  add_extra_os_vars
}
# }}}

# Parse CLI Options {{{
args=$(getopt -o hvf --long help,verbose,force -n 'init_arch' -- "$@")
eval set -- "$args"

# extract options and their arguments into variables.
while true; do
  case "$1" in
  -v | --verbose)
    VERBOSE=true
    shift
    ;;

  -h | --help)
    _help
    shift
    break
    ;;

  -f | --force)
    FORCE_INSTALL=true
    shift
    ;;

  --)
    shift
    break
    ;;

  *)
    err "Unknown option $1 to ${THIS_EXEC}"
    exit 2
    ;;
  esac
done
# }}}

# Main execution
main

# Modeline for this file (KEEP IT COMMENTED!)
# vim:foldenable:foldmethod=marker
