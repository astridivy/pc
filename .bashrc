#
# ~/.bashrc
#
# (astridivy/bashrc)

source $HOME/.cutestrap
import bashrc/bashrc

alias wifi-menu='sudo wifi-menu'

# cuuuuute colors!
Tomorrow-Night-Nineties.color

[[ -f $HOME/.git-autocomplete.bash ]] &&
  source $HOME/.git-autocomplete.bash

export MESA_GL_VERSION_OVERRIDE=2.1
