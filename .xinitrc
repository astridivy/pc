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

# never blank the screen. this is not a preference, it is a workaround: i915
# drops pipe A here with a FIFO underrun and never retries it, so the panel
# goes black while the machine behind it is completely fine, and the only way
# out used to be the power button. every one of those deaths in the journal
# came out of a long idle stretch, i.e. out of the blank -- so the cheapest
# thing that removes the trigger is to stop blanking at all. costs nothing on
# a mains-powered all-in-one with an LCD.
#
# `unblank` (Mod4-M) is the rescue for when it happens anyway. note it has to
# put this back afterwards, because `xset dpms force off` quietly re-enables
# dpms behind you.
xset s off -dpms

# start some nice programs

# commandod is resident on purpose: it pays gtk's ~1.6s import and the unicode
# index build once, here, so that Mod4-slash and Mod4-period are instant every
# time after. `commando` would start it on demand anyway, but then the first
# press waits. It is one daemon holding every tab-menu -- commands, glyphs,
# clipboard -- and it is also what records the clipboard, so it wants to be up
# from login rather than from the first time anyone opens the popup.
wallpaper & dockapps & bbkeys & commandod & ${TRANSPROG} & blackbox
#xrandr > xrandr.log
