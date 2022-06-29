#!/usr/bin/env bash
# Синхронизация системных часов
timedatectl set-ntp true
sleep 150
# Проверка режима загрузки
if ls /sys/firmware/efi/efivars
# Базовая установка для EFI
then
echo 'Your boot mode is EFI'
# Создание разделов
echo -e ',488384758K,L\n,+,U\n' | sfdisk -X gpt -w always -W always --lock /dev/sda
# Форматирование разделов
mkfs.ext4 /dev/sda1
mkfs.fat -F 32 /dev/sda2
# Монтирование разделов
mount /dev/sda1 /mnt
mount -m /dev/sda2 /mnt/boot
# Установка базовых пакетов
pacstrap /mnt base linux-lts linux-firmware intel-ucode sudo nano
# Создание fstab
genfstab -U /mnt >> /mnt/etc/fstab
# Вход в chroot
arch-chroot /mnt
# Задание часового пояса
ln -sf /usr/share/zoneinfo/Asia/Omsk /etc/localtime
hwclock --systohc
# Локализация
sed -i -e 's/#en_US.UTF-8/en_US.UTF-8/; s/#ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=ru_RU.UTF-8' > /etc/locale.conf
echo -e 'KEYMAP=ru\nFONT=cyr-sun16' > /etc/vconsole.conf
# Настройка сети
echo -n 'Set your hostname:'
read $HOSTNAME
echo $HOSTNAME > /etc/hostname
echo -e '127.0.0.1\tlocalhost\n::1      \tlocalhost\n127.0.1.1\t$HOSTNAME' >> /etc/hosts
# Регенерация initramfs
mkinitcpio -P
# Задание пароля для суперпользователя
echo -n 'Set password for root:'
passwd
# Установка загрузчика
bootctl --esp-path=/boot install
echo -e 'default  arch.conf\nconsole-mode max\neditor no' > /boot/loader/loader.conf
echo -e "title   Arch Linux\nlinux   /vmlinuz-linux-lts\ninitrd  /intel-ucode.img\ninitrd  /initramfs-linux-lts.img\noptions root=UUID=`lsblk -dno UUID /dev/sda1` rw" > /boot/loader/entries/arch.conf
echo -e "title   Arch Linux (fallback initramfs)\nlinux   /vmlinuz-linux-lts\ninitrd  /intel-ucode.img\ninitrd  /initramfs-linux-lts-fallback.img\noptions root=UUID=`lsblk -dno UUID /dev/sda1` rw" > /boot/loader/entries/arch-fallback.conf
# Выход из chroot
exit
# Размонтирование разделов
umount -R /mnt
# Выключение системы
systemctl poweroff
# Базовая установка для BIOS
else
echo 'Your boot mode is BIOS'
# Создание разделов
echo -e ',+,L\n' | sfdisk -X dos -w always -W always --lock /dev/sda
# Форматирование разделов
mkfs.ext4 /dev/sda1
# Монтирование разделов
mount /dev/sda1 /mnt
# Установка необходимых пакетов
pacstrap /mnt base linux-lts linux-firmware intel-ucode sudo nano syslinux
# Создание fstab
genfstab -U /mnt >> /mnt/etc/fstab
# Вход в chroot
arch-chroot /mnt
# Задание часового пояса
ln -sf /usr/share/zoneinfo/Asia/Omsk /etc/localtime
hwclock --systohc
# Локализация
sed -i -e 's/#en_US.UTF-8/en_US.UTF-8/; s/#ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=ru_RU.UTF-8' > /etc/locale.conf
echo -e 'KEYMAP=ru\nFONT=cyr-sun16' > /etc/vconsole.conf
# Настройка сети
echo -n 'Set your hostname:'
read $HOSTNAME
echo $HOSTNAME > /etc/hostname
echo -e '127.0.0.1\tlocalhost\n::1      \tlocalhost\n127.0.1.1\n$HOSTNAME' >> /etc/hosts
# Регенерация initramfs
mkinitcpio -P
# Задание пароля для суперпользователя
echo -n 'Set password for root:'
passwd
# Установка загрузчика
syslinux-install_update -i -a -m
echo -e "PROMPT 0\nTIMEOUT 0\nDEFAULT arch\n\nLABEL arch\n\tLINUX ../vmlinuz-linux-lts\n\tAPPEND root=UUID=`lsblk -dno UUID /dev/sda1` rw\n\tINITRD ../intel-ucode.img,../initramfs-linux-lts.img\n\nLABEL archfallback\n\tLINUX ../vmlinuz-linux-lts\n\tAPPEND root=UUID=`lsblk -dno UUID /dev/sda1` rw\n\tINITRD ../intel-ucode.img,../initramfs-linux-lts-fallback.img" > /boot/syslinux/syslinux.img
# Выход из chroot
exit
# Размонтирование разделов
umount /mnt
# Выключение системы
systemctl poweroff
fi
