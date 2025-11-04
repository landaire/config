source $HOME/.profile

export PATH=$PATH:"/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/texbin:$HOME/go/bin"
#export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

# filename (if known), line number if known, falling back to percent if known,
# falling back to byte offset, falling back to dash
export LESSPROMPT='?f%f .?ltLine %lt:?pt%pt\%:?btByte %bt:-...'

# i = case-insensitive searches, unless uppercase characters in search string
# F = exit immediately if output fits on one screen
# M = verbose prompt
# R = ANSI color support
# S = chop long lines (rather than wrap them onto next line)
# X = suppress alternate screen
export LESS=iFMRSX

# colour ls listings
export CLICOLOR=true

# Base16 Shell
# BASE16_SHELL="$HOME/.config/base16-shell/base16-ocean.dark.sh"
# [[ -s $BASE16_SHELL ]] && source $BASE16_SHELL

autoload run-help
HELPDIR=/usr/local/share/zsh/help

SAVEHIST=10000
HISTSIZE=10000
HISTFILE=$HOME/.zsh_history
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_NO_STORE
setopt NO_HIST_BEEP
setopt HIST_REDUCE_BLANKS

setopt autocd               # .. is shortcut for cd .. (etc)
setopt autoparamslash       # tab completing directory appends a slash
setopt autopushd            # cd automatically pushes old dir onto dir stack
setopt clobber              # allow clobbering with >, no need to use >!
setopt noflowcontrol        # disable start (C-s) and stop (C-q) characters
setopt nonomatch            # unmatched patterns are left unchanged
setopt histignorealldups    # filter duplicates from history
setopt histignorespace      # don't record commands starting with a space
setopt histverify           # confirm history expansion (!$, !!, !foo)
setopt interactivecomments  # allow comments, even in interactive shells
setopt printexitvalue       # for non-zero exit status
setopt pushdignoredups      # don't push multiple copies of same dir onto stack
setopt pushdsilent          # don't print dir stack after pushing/popping
setopt sharehistory         # share history across shells

autoload -U edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line
#bindkey -v

autoload -U colors && colors
export SPROMPT="Correct $fg[red]%R$reset_color to $fg[green]%r?$reset_color (Yes, No, Abort, Edit) "

# enable vi keybindings
#bindkey -e
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word


# bind UP and DOWN arrow keys -- this is for history substring search
zmodload zsh/terminfo
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

# Skip forward/back a word with opt-arrow
bindkey '[C' forward-word
bindkey '[D' backward-word

# Skip to start/end of line with cmd-arrow
bindkey '[E' beginning-of-line
bindkey '[F' end-of-line

# Delete word with opt-backspace/opt-delete
bindkey '[G' backward-kill-word
bindkey '[H' kill-word

# Delete line with cmd-backspace
bindkey '[I' kill-whole-line

# Make man colorful
man() {
    env \
    LESS_TERMCAP_mb=$(printf "\e[1;31m") \
    LESS_TERMCAP_md=$(printf "\e[1;31m") \
    LESS_TERMCAP_me=$(printf "\e[0m") \
    LESS_TERMCAP_se=$(printf "\e[0m") \
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
    LESS_TERMCAP_ue=$(printf "\e[0m") \
    LESS_TERMCAP_us=$(printf "\e[1;32m") \
    man "$@"
}

if [[ `uname` == 'Linux' ]]
then
        export LINUX=1
        export GNU_USERLAND=1
else
        export LINUX=
fi

if [[ `uname` == 'Darwin' ]]
then
        export OSX=1
else
        export OSX=
fi

#if [[ "$OSX" == "1" ]]
#then
#    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
#fi

#if [[ "$LINUX" == "1" ]]
#then
#	source /usr/share/fzf/key-bindings.zsh
#	source /usr/share/fzf/completion.zsh
#fi


autoload -U add-zsh-hook

function set-tab-and-window-title() {
  emulate -L zsh
  local CMD="${1:gs/$/\\$}"
  print -Pn "\e]0;$CMD:q\a"
}

function update-window-title-precmd() {
  emulate -L zsh
  set-tab-and-window-title `history | tail -1 | cut -b8-`
}
add-zsh-hook precmd update-window-title-precmd

function update-window-title-preexec() {
  emulate -L zsh
  setopt extended_glob

  # skip ENV=settings, sudo, ssh; show first distinctive word of command;
  # mostly stolen from:
  #   https://github.com/robbyrussell/oh-my-zsh/blob/master/lib/termsupport.zsh
  set-tab-and-window-title ${2[(wr)^(*=*|mosh|ssh|sudo)]}
}
add-zsh-hook preexec update-window-title-preexec

function update-window-title-preexec() {
  emulate -L zsh
  setopt extended_glob

  # skip ENV=settings, sudo, ssh; show first distinctive word of command;
  # mostly stolen from:
  #   https://github.com/robbyrussell/oh-my-zsh/blob/master/lib/termsupport.zsh
  set-tab-and-window-title ${2[(wr)^(*=*|mosh|ssh|sudo)]}
}
add-zsh-hook preexec update-window-title-preexec

function tmux() {
  emulate -L zsh

  # Make sure even pre-existing tmux sessions use the latest SSH_AUTH_SOCK.
  # (Inspired by: https://gist.github.com/lann/6771001)
  local SOCK_SYMLINK=~/.ssh/ssh_auth_sock
  if [ -r "$SSH_AUTH_SOCK" -a ! -L "$SSH_AUTH_SOCK" ]; then
    ln -sf "$SSH_AUTH_SOCK" $SOCK_SYMLINK
  fi

  # If provided with args, pass them through.
  if [[ -n "$@" ]]; then
    env SSH_AUTH_SOCK=$SOCK_SYMLINK tmux "$@"
    return
  fi

  # Check for .tmux file (poor man's Tmuxinator).
  if [ -x .tmux.conf ]; then
    # Prompt the first time we see a given .tmux file before running it.
    local DIGEST="$(openssl sha -sha512 .tmux)"
    if ! grep -q "$DIGEST" ~/..tmux.digests 2> /dev/null; then
      cat .tmux.conf
      read -k 1 -r \
        'REPLY?Trust (and run) this .tmux file? (t = trust, otherwise = skip) '
      echo
      if [[ $REPLY =~ ^[Tt]$ ]]; then
        echo "$DIGEST" >> ~/..tmux.digests
        ./.tmux
        return
      fi
    else
      ./.tmux.conf
      return
    fi
  fi

  # Attach to existing session, or create one, based on current directory.
  SESSION_NAME=$(basename "$(pwd)")
  /usr/bin/env SSH_AUTH_SOCK=$SOCK_SYMLINK tmux new -A -s "$SESSION_NAME"
}

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
source ~/.credentials

#source /Users/hvx/Library/Preferences/org.dystroy.broot/launcher/bash/br

export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"


eval "$(atuin init zsh)"
export PATH="$PATH:/Applications/010 Editor.app/Contents/CmdLine" #ADDED BY 010 EDITOR

if tty -s; then
exec nu --login
fi
