#!/bin/sh

# Functions for interacting with the asdf version manager.

# Load the asdf version manager into the current shell session.
src_asdf_for_profile() {
  local asdfDir="${ASDF_DIR:-${HOME}/.asdf}"

  if [ -d "${asdfDir}" ]; then
    __src_asdf
  else
    warn "asdf dir not found."
  fi
}

# Clone the asdf Git repository to ~/.asdf
clone_asdf() {
  local asdfDir="${ASDF_DIR:-${HOME}/.asdf}"
  local asdfGitRepoUrl="https://github.com/asdf-vm/asdf.git"

  if [ ! -d "${asdfDir}" ]; then
    log_info "Cloning asdf Git repository"
    git clone "${asdfGitRepoUrl}" "${asdfDir}"
  else
    warn "asdf directory ${asdfDir} already exists!"
  fi
}

# Add all asdf language plugins configured for this repository.
add_asdf_plugins() {
  local plugin

  echoe "${ASDF_PLUGINS_FILE}"
  if [ ! -f "${ASDF_PLUGINS_FILE}" ]; then
    err "No asdf plugins file defined"
    return 1
  fi

  log_info "Adding asdf plugins..."
  while read -r plugin || [ -n "${plugin}" ]; do
    log_info "Adding asdf plugin: ${plugin}"
    asdf plugin add "${plugin}"
  done <"${ASDF_PLUGINS_FILE}"
}

# Wrapper function for updating all installed asdf plugins.
update_asdf_plugins() {
  asdf plugin update --all
}

# Takes care of the nitty gritty sourcing logic for asdf.
__src_asdf() {
  local currentShell="$(currentshell)"
  local asdfDir="${ASDF_DIR:-${HOME}/.asdf}"
  local asdfSourceFile="${asdfDir}/asdf.sh"
  local asdfSourceFileFish="${asdfDir}/asdf.fish"

  log_info "Sourcing asdf for shell: ${currentShell}"

  case "${currentShell}" in
  "bash")
    . "${asdfSourceFile}"
    ;;
  "zsh")
    . "${asdfSourceFile}"
    ;;
  "fish")
    source "${asdfSourceFileFish}"
    ;;
  *)
    err "Shell ${currentShell} not supported by asdf."
    return 1
    ;;
  esac
}

# vim:foldenable:foldmethod=indent:foldnestmax=1
