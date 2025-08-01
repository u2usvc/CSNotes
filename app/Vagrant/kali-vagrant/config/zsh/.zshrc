#############################
###        OPTIONS        ###
#############################
setopt share_history
setopt appendhistory
# for capital-case autocompletion
autoload -Uz compinit && compinit

# slash backward-kill-word
autoload -U select-word-style
select-word-style bash

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# prevent from closing on Ctrl+d
setopt ignore_eof


#############################
###       VARIABLES       ###
#############################
# main
  export ZDOTDIR='/home/vagrant/.config/zsh'
  export EDITOR='/usr/bin/nvim'
  export MANPAGER="nvim +Man!"
  export HISTSIZE=10000
  export SAVEHIST=10000
  export HISTFILE="/home/vagrant/.config/zsh/zsh_history"

# themes
  export GTK_THEME=Adwaita-dark

# complementary
  export QT_STYLE_OVERRIDE="adwaita-dark"
  
# libvirt / qemu
  export LIBVIRT_DEFAULT_URI=qemu:///system

# LSP
  export GEM_HOME="/home/vagrant/.local/share/gem/ruby/3.1.0/gems"
  export PATH=$PATH:/home/vagrant/.local/share/nvim/mason/bin/

# XDG
  export XDG_CONFIG_HOME="/home/vagrant/.config"
  export XDG_CACHE_HOME="/home/vagrant/.cache"
  export XDG_DATA_HOME="/home/vagrant/.local/share"
  export XDG_STATE_HOME="/home/vagrant/.local/state"
  export XDG_CONFIG_HOME="/home/vagrant/.config"
  export XDG_CURRENT_DESKTOP=sway
  export XDG_SCREENSHOTS_DIR="/home/vagrant/Screenshots"
  export SDL_VIDEODRIVER=wayland
  export _JAVA_AWT_WM_NONREPARENTING=1
  export QT_QPA_PLATFORM=wayland
  export XDG_SESSION_DESKTOP=sway
  export XDG_DESKTOP_DIR="$HOME/Desktop"
  export XDG_DOWNLOAD_DIR="$HOME/Downloads"
  export XDG_TEMPLATES_DIR="$HOME/Templates"
  export XDG_PUBLICSHARE_DIR="$HOME/Public"
  export XDG_DOCUMENTS_DIR="$HOME/Documents"
  export XDG_MUSIC_DIR="$HOME/Music"
  export XDG_PICTURES_DIR="$HOME/Pictures"
  export XDG_VIDEOS_DIR="$HOME/Videos"


# style
  export MINIKUBE_IN_STYLE=false


#############################
###        PROMPT         ###
#############################
# Execution sequence (/etc, /~) 1) zshenv 2) zprofile (login) 3) zshrc (interactive) 4) zlogin (login)
# PROMPT='%B%F{6}%n@%m%f%b %F{3}%~%f %F{9}[%?]%f > ' # One line prompt
PROMPT='
┌──%F{12}(%n@%m)%f %F{11}[%~]%f %F{9}{%?}%f %F{14}%D{%T}%f
└─> '


#############################
###        ALIASES        ###
#############################
# cross-dev
  alias wing++="/usr/lib/mingw64-toolchain/bin/x86_64-w64-mingw32-c++"
  alias winobjdump='/usr/lib/mingw64-toolchain/bin/x86_64-w64-mingw32-objdump'

# func
  alias ll="ls -lhtr --color=always"
  alias la='ls -lahtr --color=always'
  alias dir='dir -al'
  alias cls='clear'
  alias srcz='source $ZDOTDIR/.zshrc'
  alias sudo='sudo -E'
  alias irssi='irssi --config=~/.config/irssi/irssi.conf --connect=irc.libera.chat'

# Looks
	alias grep='grep --color=auto'
	alias ip='ip --color=auto'
  alias btw='fastfetch'
  # alias feh='feh --image-bg "#282828"'
  alias display-colors='for i in {1..256}; do print -P "%F{$i}Color : $i"; done;'

#############################
###         PATH          ###
#############################
export PATH=$PATH:/home/vagrant/.config/fastfetch
export PATH="$(ruby -e 'puts Gem.user_dir')/gems/bin/:$PATH"
export PATH=$PATH:/home/vagrant/bin
export PATH="$PATH:/home/vagrant/.dotnet/tools"
export PATH="$PATH:/home/vagrant/.local/bin"
export PATH="$PATH:/home/vagrant/utils"
export PATH="$PATH:/home/vagrant/.local/share/nvim/mason/packages/omnisharp"


#############################
###        KEYMAP         ###
#############################
# use man zshzle for reference on commands
# use cat to get keycodes
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
bindkey '^[^L' forward-char
bindkey '^[^H' backward-char


#############################
###        PLUGINS        ###
#############################
source ~/.config/zsh/scripts/antigen/antigen.zsh

antigen bundle jeffreytse/zsh-vi-mode
zvm_config() {
  ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
  ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
  ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_UNDERLINE
  ZVM_VI_HIGHLIGHT_FOREGROUND=#282828 
  ZVM_VI_HIGHLIGHT_BACKGROUND=#e78a4e
}

antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle Aloxaf/fzf-tab

antigen apply
