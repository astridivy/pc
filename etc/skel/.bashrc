#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias la='ls -a --color=auto'
alias cp='cp -i'
alias mv='mv -i'
alias ..='cd+ ..'
alias ...='cd+ .. ..'
alias whattime='date +%l:%M%P'
export PS1='[`whattime` \u@\h \W]\$ '
