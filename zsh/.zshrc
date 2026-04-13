# If you come from bash you might have to change your $PATH.
# export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# Java
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH="$JAVA_HOME/bin:$PATH"

# Maven
export MAVEN_HOME="/opt/homebrew/opt/maven"
export PATH="$MAVEN_HOME/bin:$PATH"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# Docker CLI
export PATH="$PATH:/Applications/Docker.app/Contents/Resources/bin"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# Aliases

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Git
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gbd='git branch -d'
alias gc='git commit -v'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gd='git diff'
alias gl='git pull'
alias gp='git push'
alias gs='git status'
alias gst='git status'

# Development
alias nr='npm run'
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias ns='npm start'
alias nt='npm test'
alias nup='npm update'
alias nun='npm uninstall'
alias nci='npm ci'
alias nout='npm outdated'
alias nv='node -v'
alias npv='npm -v'
alias npx='npx'
alias pn='pnpm'
alias pni='pnpm install'
alias py='python3'
alias pip='pip3'
alias serve='python3 -m http.server'

# Docker
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'

# Terraform
alias tf='terraform'
alias tfi='terraform init'
alias tfm='terraform fmt'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfv='terraform validate'

# Java & Maven
alias m='mvn'
alias mc='mvn clean'
alias mi='mvn install'
alias mcis='mvn clean install'
alias mp='mvn package'
alias mt='mvn test'
alias mcv='mvn clean verify'
alias j='java'
alias jc='javac'

# Node
alias n='node'
alias nd='node --inspect'
alias nn='node --no-warnings'

# Kubernetes
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'

# System
alias c='clear'
alias h='history'
alias reload='source ~/.zshrc'
alias zshrc='vim ~/.zshrc'
alias grep='grep --color=auto'
alias killport='f() { lsof -ti :$1 | xargs kill -9 2>/dev/null || echo "Port $1 not in use"; }; f'

# tfenv path
export PATH="/opt/homebrew/opt/tfenv/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Local bin
export PATH="$HOME/.local/bin:$PATH"
