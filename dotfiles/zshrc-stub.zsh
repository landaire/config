# Minimal login stub. Homebrew env, then hand off to nushell for interactive ttys.
eval "$(/opt/homebrew/bin/brew shellenv)"

if [[ -o interactive ]] && [[ -o login ]]; then
  exec nu --login
fi
