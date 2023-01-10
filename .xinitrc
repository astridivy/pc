#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

# pile a crap 1 bit color... just why lmao
# xsetroot -bitmap $HOME/doc/galaxy.xbm

if [ $_X_TRANSPARENCY ]; then
  TRANSPROG='picom -f --xrender-sync-fence -D 2'
else
  TRANSPROG=':'
fi


setxkbmap -option ctrl:nocaps

# fonts? ??
xset fp+ /usr/share/fonts/

wallpaper & dockapps & bbkeys & ${TRANSPROG} & blackbox
