#
# ~/.bashrc
#
# bootstrap, source cute-ils and bashrc/bashrc
#
# 2019-02-23
# astridivy (Astrid REDACTED)

source $HOME/.cutestrap

# import cute-itls/* # maybe someday
import bashrc/bashrc

bind 'TAB: menu-complete'
bind '"\e[Z": menu-complete-backward'

import git-autocomplete.sh


#######################################################################


# leaving all the windows crap in here for now, some is salvageable
# and I don't want to lose it in the merge

# this arch install is weird...
# it's like a bizarre blend of arch and f***ing random WSL defaults

# TODO: need to not repeat PATH over and over again
# either write a very clever bash script... or just put it in top level .bashrc
# since bashrc xxx yyy sources the files directly
#export PATH=$HOME/bin/:/usr/bin:/usr/local/bin:$PATH

#alias ls='ls --color=auto -I NTUSER.DAT\* -I ntuser.dat\*'

#van () {
#  vim -c "term++curwin man $*"
#}

# quick access to home
# TODO add -i and -o options that either append ~/ to input or output of commands
#mv~ () {
#  mv "$@" ~
#}
#
#cp~ () {
#  cp "$@" ~
#}

#vimS () {
#	if [[ $1 ]]; then
#		vim -S "~/$1"
#	else
#		vim -S "~/.vim/restore.session"
#	fi
#}

#RIP z, long live fasd!
#alias fasdrc='vim ~/.fasdrc'
#
#eval "$(fasd --init auto)"
#
#alias vmux='vim -c "term++curwin"'
#
#alias fe='fasd -e'
#alias v='fasd -f -e vim'

# TODO: editable backscroll. this will be epic.
# so it doesn't work very well now, but the idea is to combine script and vim
# lol you scrub it's just called Terminal Normal mode
#:e () {
#
#  [[ ! -d $HOME/.buffer ]] && mkdir $HOME/.buffer
#  cd $HOME/.buffer
#
#  for (( i = 9 ; $i ; i-- )) ; do {
#	local nxt=$(($i + 1))
#	[[ -f "$i.buffer" ]] && cp "$i.buffer" "$nxt.buffer" && rm "$i.buffer"
#  } done
#
#  script -c "$*"
#
#  cat typescript > "0.buffer"
#  vim "0.buffer"
#}

# double check z placement
#unalias z
#z () {
#  fasd_cd -d "$@";
#  pwd;
#}

# LOLR4ND0M
#alias clock='tty-clock -s -t -c'

# git prompt :)
#GIT_PROMPT_ONLY_IN_REPO=1
#source ~/.bash-git-prompt/gitprompt.sh
#
## super star
#shopt -s globstar
#
## maybe i'll have better luck in here
