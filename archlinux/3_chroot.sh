#!/bin/bash
cat > /mnt/root/4_configure.sh <<EOF

  chroot_time () {
    if [[ ! \$1 ]] || [[ ! \$2 ]]; then
      echo "chroot_time()"
      echo "  usage: chroot_time <timezone> <hostname>"
      return 1
    fi 


    TMZN="\$1"
    HSNM="\$2"

    ln -is "/usr/share/zoneinfo/\$TMZN" /etc/localtime
    
    hwclock --systohc
    
    echo "en_US.UTF-8 UTF-8 from /etc/locale.gen"
    
    echo $'en_US.UTF-8 UTF-8' >> /etc/locale.gen
    
    locale-gen
    
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    
    echo \$HSNM > /etc/hostname
    
    echo $'127.0.0.1	localhost\n::1		localhost' > /etc/hosts
    
    pacman -S grub

    mkdir /boot/grub

    echo "Edit your grub configuration now (if necessary). Exit to continue."
    bash
    
    grub-mkconfig > /boot/grub/grub.cfg
    
    echo "Install grub (grub-install /dev/sdX)"

    bash
  }

  export -f chroot_time

  list_tz () {
    timedatectl list-timezones | column -x | less
  }

  export -f list_tz

  echo "In the following shell, please invoke chroot_time()
  echo "chroot_time()"
  echo "  usage: chroot_time <timezone> <hostname>"
  echo "You may want to list all available timezones first with list_tz()"

  bash
EOF

chmod +x /mnt/root/4_configure.sh

cat > /mnt/root/5_user.sh <<EOF
echo "Set root password"
passwd

user () {
  if [[ ! \$1 ]]; then
    echo "Set up primary user"
    echo "usage: user <username>"
    return
  fi

  useradd \$1 -m -N
  usermod \$1 -G wheel -a

  echo "Set user's password"
  passwd \$1

  echo
  echo "If you want to login without a password add"
  echo "auth sufficient pam_succeed_if.so user ingroup nopasswdlogin"
  echo "to /etc/pam.d/login"
  echo "(and make the group, etc.)"
  echo "To continue, exit now"

  bash

  echo "ok visudo time: uncomment the desired line to enable sudo group"

  bash
}

export -f user

echo "In the following shell, please invoke user"
echo "user()"
echo "  Set up primary user"
echo "  usage: user <username>"

bash
EOF

chmod +x /mnt/root/5_user.sh

echo "See you on the other side!"
echo "(The next two scripts have been installed to /mnt/root)"
echo "$ cd"
echo "suffices to get you there once chroot'd"
echo ""
echo "Now time to chroot into the newly installed OS with"
echo "$ arch-chroot /mnt"
