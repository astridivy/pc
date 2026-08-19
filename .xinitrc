#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

export DISPLAY=:0
xrandr --output HDMI-0 --primary --mode 1920x1080 --pos 0x0

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

# The screen is *meant* to blank -- that nap is wanted. Recording the failed
# experiment so nobody re-runs it: from 2026-08-15 to 08-18 this line read
# `xset s off -dpms`, on the theory that the panel died out of the idle blank
# (every death up to then had come out of a long quiet stretch). It did not
# help. The pipe A underruns kept happening with dpms disabled -- five of them
# in one boot -- so blanking was never the trigger, and turning it off only
# cost the nap. `unblank` (Mod4-M) is the actual answer, and it rings the bell
# so you know it fired.
#
# Leaving the timeouts at the server's own defaults (10 min) rather than
# restating them here, which is where they were before any of this.

# start some nice programs

# commandod is resident on purpose: it pays gtk's ~1.6s import and the unicode
# index build once, here, so that Mod4-slash and Mod4-period are instant every
# time after. `commando` would start it on demand anyway, but then the first
# press waits. It is one daemon holding every tab-menu -- commands, glyphs,
# clipboard -- and it is also what records the clipboard, so it wants to be up
# from login rather than from the first time anyone opens the popup.
wallpaper & dockapps & bbkeys & commandod & ${TRANSPROG} & blackbox
#xrandr > xrandr.log
