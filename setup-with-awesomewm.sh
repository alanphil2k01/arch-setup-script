#!/bin/sh

# Change according to your system

# System options
TIMEZONE="Asia/Kolkata"                             # Search for your timezone in /usr/share/zoneinfo/
LANGUAGE="en_US.UTF-8 UTF-8"                        # To change to other language refer /etc/locale.gen for your required language
LANG="en_US.UTF-8"                                  # Same as LANGUAGE but without charset (i.e. the 2nd part of string)
HOSTNAME="ArchLinux"                                # Hostname of the computer
EFI="true"                                          # Put "false" if you have legacy boot. To check run command "ls /sys/firmware/efi/efivars". If it exists you have an efi system

# User settings
USERNAME="alan"                                     # Enter your username
SUDOPERM="true"                                     # Do you want your user to have sudo permissions. It is required to make yay package 
# Setup yay (AUR helper)
YAY="true"

# GPU driver. Uncomment your gpu driver
GPUDRIVER="xf86-video-intel"                        # Intel GPU Driver     
#GPUDRIVER="nvidia nvidia-utils nvidia-settings"    # Nvidia GPU Driver
#GPUDRIVER="xf86-video-amdgpu"                      # AMD GPU Driver

# Init 
INIT="systemd"                                      # Systemd
INIT="runit"                                        # Runit
INIT="openrc"                                       # Openrc
INIT="s6"                                           # S6

# Preffered Terminal Editor
EDITOR="vim"                                        # Change if you prefer other editors

# Change this if you have Legacy boot
$DISK="/dev/sda"                                    # The disk you are instaling arch/artix
$BOOTPARTITION="/dev/sda1"                          # The boot partition
$SEPERATEEFI="true"                                 # "true" reccomended for dual boot with windows and will make sure you don't overwrite windows bootloader.

# TimeZone
clear
echo "Setting Timezone"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Localization
clear
echo "Making /etc/locale.conf"
echo $LANGUAGE >> /etc/locale.gen
locale-gen
echo "LANG=$LANG" >> /etc/locale.conf

# Setup Hostname
clear
echo "Making /etc/hostname"
echo $HOSTNAME >> /etc/hostname

# Setup Hosts file
clear
echo "Making /etc/hosts file"
echo "127.0.0.1    localhost" >> /etc/hosts
echo "::1          localhost" >> /etc/hosts
echo "127.0.0.1    $HOSTNAME.localhost    $HOSTNAME" >> /etc/hosts


# Install Packages
clear
pacman -Sy $EDITOR base-devel git  --noconfirm

# Root Password
clear
echo "Change password for root"
passwd

# User Setup
clear
echo "Setup User"
echo "Enter Username:" && read USERNAME
useradd -m USERNAME
printf "Do you want user to have sudo privilages[y/n]:" && read CHOICE
if [[ ! $CHOICE =~ ^[Yy]$ ]]; then
    usermod -aG wheel USERNAME
    echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
    echo "Defaults !tty_tickets" >> /etc/sudoers
fi
echo "Change password for $USERNAME"
passwd $USERNAME

# Setup Yay
clear
echo "Installing yay"
if [[ $YAY="true" && $SUDOPERM="true" ]]; then
    git clone https://aur.archlinux.org/yay.git
    chown $USERNAME:$USERNAME yay
    cd yay
    sudo -u $USERNAME makepkg -si
    cd ..
    rm -rf yay
fi

# Setup GRUB
clear
echo "Installing Grub"
if [[ "$EFI" = true ]]; then
    pacman -S grub os-prober efibootmgr --noconfirm
    grub-install --target=x86_64-efi --efi-directory --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
else
    pacman -S grub os-prober --noconfirm
    if [[ "$SEPERATEEFI" = true ]]; then
        grub-install --target=i386-pc $BOOTPARTITION
        grub-mkconfig -o /boot/grub/grub.cfg
    else
        grub-install --target=i386-pc $DISK
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
fi

# Setup Xorg and install gpu driver
clear
pacman -S xorg-server xorg-xinit $GPUDRIVER --noconfirm

# Installing packages for awesome wm
clear
sudo -u $USERNAME yay -S awesome zsh feh compton acpi i3lock-color zathura terminator brave-bin lf dmenu newsboat --noconfirm

# Setting up awesome wm with my configs
clear
curl -O https://raw.githubusercontent.com/alanphil2k01/dotfiles-awesome/master/awesome_setup.sh
sudo -u $USERNAME sh awesome_setup.sh $USERNAME

# Changing Shell
clear
echo "Changing shell to zsh"
chsh -s /bin/zsh $USERNAME
mkdir -u $USERNAME mkdir -p /home/$USERNAME/.cache/zsh/
clear
