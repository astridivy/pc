#!/bin/bash
echo "See you on the other side!"
echo "(The next two scripts have been installed to /mnt/root)"

cat > /mnt/root/3_chroot.sh <<EOF
  chroot_time () {
    if [[ ! \$1 ]] || [[ ! \$2 ]]; then
      echo "Chroot Time:"
      echo "chroot_time <timezone> <hostname>"
      return 1
    fi

    TMZN="\$1"
    HSNM="\$2"

    ln -is "/usr/share/zoneinfo/\$TMZN" /etc/localtime
    
    hwclock --systohc
    
    echo "Uncomment en_US.UTF-8 UTF-8 from /etc/locale.gen"
    
    bash
    
    locale-gen
    
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    
    echo \$HSNM > /etc/hostname
    
    echo $'127.0.0.1	localhost\n::1		localhost' > /etc/hosts
    
    pacman -S grub
    
    grub-mkconfig
    
    echo "Install grub (grub-install /dev/sdX)"
    
    bash
  }

  export -f chroot_time

  echo "In the following shell, please invoke \`chroot_time'"
  chroot_time

  bash
EOF

cat > /mnt/root/4_user.sh <<EOF
echo "Set root password"
passwd

user () {
  if [[ ! \$1 ]]; then
    echo "Set up user"
    echo "user <username>"
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
  echo "To continue, exit."

  bash

  echo "ok visudo time: uncomment the desired line to enable sudo group"

  bash
}

export -f user

user
echo "In the following shell, please invoke \`user'"

bash
EOF

arch-chroot /mnt
