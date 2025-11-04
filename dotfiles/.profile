alias vimr='open -a vimr.app "$@"'
alias cat=ccat
alias lsl="ls -lah"
alias lst="ls -laht"
alias cp="fcp"
export GO15VENDOREXPERIMENT=1
export PATH="/usr/local/bin:$HOME/bin:$HOME/.rvm/bin:$HOME/.local/bin:$PATH:/usr/local/sbin" # Add RVM to PATH for scripting
export EDITOR="vim"
export PAGER="less"
export TERM="xterm-256color"
export XDG_CONFIG_HOME=$HOME/.config

export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/opt/go/libexec/bin:$GOPATH/bin:$HOME/.cabal/bin
#export VIMINIT=":source $XDG_CONFIG_HOME"/vim/vimrc

#export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_25.jdk/Contents/Home
export JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk-12.0.2.jdk/Contents/Home
#export VIMINIT=":source $XDG_CONFIG_HOME"/vim/vimrc
#export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

alias lldb="rust-lldb"
alias prettyjson="python -m json.tool"
alias fix='echo -e "\e<"; reset; stty sane; tput rs1; clear; echo -e "\033c"'
alias gc='git commit -m'
alias ls='eza'
alias vim='nvim'
export DOTNET_CLI_TELEMETRY_OPTOUT=1
make_venv() { python3 -m venv "$HOME/.virtualenvs/$1" }
load_venv() { source "$HOME/.virtualenvs/$1/bin/activate" }
base64_decode() {
  flag='-d'
  if uname -a | grep 'xnu' > /dev/null; then
    flag='-D'
  fi

  echo -n $1 | base64 $flag | xxd
}

if [ -f ~/.secret_profile ]; then
	source ~/.secret_profile
fi

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  alias tcopy="xclip -selection c"
  alias disks="lsblk -o \"NAME,MAJ:MIN,RM,SIZE,RO,FSTYPE,MOUNTPOINT,UUID\""
fi

#if command -v tmux>/dev/null; then
#  [[ ! $TERM =~ screen ]] && [ -z $TMUX ] && exec tmux
#fi

#[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
#export PATH="$(pyenv root)/shims:$PATH"
. "$HOME/.cargo/env"
export PATH="$PATH:/Applications/010 Editor.app/Contents/CmdLine" #ADDED BY 010 EDITOR

export PATH="$PATH:/Applications/screenpipe.app/Contents/MacOS"
