#!/usr/bin/env bash

# Make sure that file creation occurs with the normal permissions.
umask 022

# Where the magic happens:
export DOTFILES_HOME="${HOME}/.dotfiles"

# Additional $PATH settings {{{
# Add sbin to PATH if it exists
[ -d "/usr/local/sbin" ] && export PATH="/usr/local/sbin:$PATH"
[ -d "/usr/sbin" ] && export PATH="/usr/sbin:$PATH"
# Add dotfiles binaries to the path:
export PATH="$DOTFILES_HOME/bash/bin:$PATH"
# No need to export all additional directories here because `spath` takes care
# of that by exporting all directories listed in ~/.path
# }}}

# Completion {{{
# Add Bash completion if the file has been installed.
if [ -f "/etc/bash_completion" ]; then
  . "/etc/bash_completion"
fi
# }}}

# Source additional files {{{
src_one_time_transfers() {
  local file

  for file in "$HOME"/.{dirs,vars}; do
    . "$file"
  done
}

# Source all files in a given directory
src_in_dir() {
  local dir="$1"
  local file

  if [ ! -d "$dir" ]; then
    echo "ERROR: No directory provided to function ${FUNCNAME[0]}" 1>&2
    return 1
  fi

  for file in $(find "$dir" -maxdepth 1 -mindepth 1 -type f); do
    . "$file"
  done
}

# Source additional OS-specific files
src_os() {
  local bashSrcDir="${DOTFILES_HOME}/bash/source"
  local linuxSrcDir="${bashSrcDir}/linux"
  local archSrcDir="${linuxSrcDir}/arch"

  # Make sure to get reference to "getosinfo" function
  . "$bashSrcDir/functions_os.bash"
  local os="$(getosinfo | head -1 | sed 's/Distribution:\s*//')"

  case "$os" in
  "Arch Linux")
    src_in_dir "$archSrcDir"
    ;;

  *)
    echo "ERROR: Unknown OS for sourcing: ${os}" 1>&2
    return 1
    ;;
  esac
}

# Main source function. This is the one that you will be frequently calling from
# the command line.
src() {
  local bashSrcDir="${DOTFILES_HOME}/bash/source"
  local file

  # Source one-time transfer files
  src_one_time_transfers
  # Source all alias and function files
  src_in_dir "$bashSrcDir"
  # Re-read the ~/.inputrc file.
  [ -f "${HOME}/.inputrc" ] && bind -f "${HOME}/.inputrc"
  src_os
  # Also source the path file
  spath "${PATH_FILE:-${HOME}/.path}" "PATH"
  # Make sure LuaRocks are discoverable.
  src_lua_path
}
src
# }}}

# Change ls colors (dircolors) {{{
dircolorsFile="$DIRCOLORS_DIR/tomorrow-night-eighties.dircolors"
if [ -f "$dircolorsFile" ]; then
  eval "$(dircolors "$dircolorsFile")"
fi
unset dircolorsFile
# }}}

# Special Prompts {{{
POWERLINE_BASH_BINDINGS="$(find "${HOME}/.local/lib/" -type f \
  -regextype 'posix-extended' \
  -regex '.*python3.[0-9]+.*bindings/bash/powerline.sh' |
  sort -V |
  tail -1)"

if [ -x "$(command -v starship)" ]; then
  # The starship prompt is a beautiful, informative, cross-shell prompt
  eval "$(starship init bash)"
elif [ -f "${POWERLINE_BASH_BINDINGS}" ]; then
  # Default to powerline if no other prompt installed
  powerline-daemon -q
  export POWERLINE_BASH_CONTINUATION=1
  export POWERLINE_BASH_SELECT=1
  . "${POWERLINE_BASH_BINDINGS}"
fi
# }}}

# Make sure to set prompt to something simple for Emacs TRAMP {{{
if [ "$TERM" == "dumb" ]; then
  PS1="tramp $ "
fi
# }}}

# Set transparency for xterm
if [ -n "$XTERM_VERSION" ] && [ "$(command -v transset-df)" != "" ]; then
  transset-df --id "$WINDOWID" >/dev/null
fi

# Load pyenv if available
if [ "$(command -v pyenv)" != "" ]; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# Initialize fasd if installed
if [ "$(command -v fasd)" != "" ]; then
  fasd_cache="$HOME/.fasd-init-bash"
  if [ "$(command -v fasd)" -nt "$fasd_cache" ] ||
    [ ! -s "$fasd_cache" ]; then
    fasd --init posix-alias bash-hook bash-ccomp bash-ccomp-install >"$fasd_cache"
  fi
  . "$fasd_cache"
  unset fasd_cache
fi

# Load fzf keybindings
[ -f ~/.fzf.bash ] && . ~/.fzf.bash

# These icons are supplied by the icons-in-terminal project
use_icons_in_terminal() {
  local iconScript="$HOME/.local/share/icons-in-terminal/icons_bash.sh"
  [ -f "$iconScript" ] && . "$iconScript"
}
use_icons_in_terminal

# Use jenv to manage installed Java versions (if available)
if [ -n "$(command -v jenv)" ]; then
  eval "$(jenv init -)"
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
# Home directory for sdkman program.
export SDKMAN_DIR="${HOME}/.sdkman"
if [ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]; then
  . "${SDKMAN_DIR}/bin/sdkman-init.sh"
fi

# Print neofetch info when the terminal first opens
[ "$(command -v neofetch)" != "" ] && neofetch 1>&2

# vim:foldenable:foldmethod=marker
