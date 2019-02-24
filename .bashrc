# this arch install is weird...
# it's like a bizarre blend of arch and f***ing random WSL defaults

export PATH=$HOME/bin/:/usr/bin:/usr/local/bin:$PATH

alias _ls='ls'
alias ls='ls --color=auto -I NTUSER.DAT\* -I ntuser.dat\*'
alias lsd='ls --group-directories-first'

cdl () {
  cd $1 && ls
}

# useful when we can actually scroll up
mancat () {
  man $1 | cat
}

van () {
  vim -c "term++curwin man $*"
}

# quick access to home
mv~ () {
  mv "$@" ~
}

cp~ () {
  cp "$@" ~
}

vimS () {
	if [[ $1 ]]; then
		vim -S "~/$1"
	else
		vim -S "~/.vim/restore.session"
	fi
}

alias bashrc='vim ~/.bashrc && source ~/.bashrc'
alias sob='source ~/.bashrc'
alias vimrc='vim ~/.vimrc'
#TODO: replace with a proper todo management system
alias todo='vim ~/todo.txt'

alias cute='cd ~/random/cute'

alias pacman='sudo pacman'

alias lynx='lynx --session ~/.lynxsession'
alias g='google'
alias l='locate'

#RIP z, long live fasd!
alias fasdrc='vim ~/.fasdrc'

eval "$(fasd --init auto)"

alias vmux='vim -c "term++curwin"'

alias fe='fasd -e'
alias v='fasd -f -e vim'

# TODO: editable backscroll. this will be epic.
# so it doesn't work very well now, but the idea is to combine script and vim
# lol you scrub it's just called Terminal Normal mode
:e () {

  [[ ! -d $HOME/.buffer ]] && mkdir $HOME/.buffer
  cd $HOME/.buffer

  for (( i = 9 ; $i ; i-- )) ; do {
	local nxt=$(($i + 1))
	[[ -f "$i.buffer" ]] && cp "$i.buffer" "$nxt.buffer" && rm "$i.buffer"
  } done

  script -c "$*"

  cat typescript > "0.buffer"
  vim "0.buffer"
}

# double check z placement
unalias z
z () {
  fasd_cd -d "$@";
  pwd;
}

# git autocomplete plsssss
source ~/lib/git-autocomplete.sh

# LOLR4ND0M
alias clock='tty-clock -s -t -c'

# git prompt :)
GIT_PROMPT_ONLY_IN_REPO=1
source ~/.bash-git-prompt/gitprompt.sh

# super star
shopt -s globstar
