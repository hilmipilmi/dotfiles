#!/bin/sh
# define ${D} before call
# see: https://janweitz.de/article/creating-a-zfs-zroot-raid-10-on-ubuntu-16.04/
#      https://github.com/zfsonlinux/zfs/wiki/Ubuntu-16.04-Root-on-ZFS
#      https://github.com/zfsonlinux/pkg-zfs/wiki/HOWTO-install-Ubuntu-17.04-to-a-Whole-Disk-Native-ZFS-Root-Filesystem-using-Ubiquity-GUI-installer
if [ -z ${D} ]; then echo "disk id missing"; exit 1; fi

hname=DL15W6J72
ifname=enp0s31f6
echo "############### ifname:  ${ifname} : change?  ###############"
echo "############### hostname:${hname}  : change?  ###############"

echo "##### need to partition with sgdisk ######"
# nodo: sgdisk -Z -n9:-8M:0 -t9:bf07 -c9:Reserved -n2:-8M:0 -t2:ef02 -c2:GRUB  -n3:-512M:0 -t3:ef00 -c3:UEFI -n1:0:0 -t1:bf01 -c1:ZFS <dev>
# nodo: sgdisk -Z -n9:-8M:0 -t9:bf07 -c9:Reserved -n2:-8M:0 -t2:ef02 -c2:GRUB -n1:0:0 -t1:bf01 -c1:ZFS /dev/disk/by-id/nvme-eui.0000000001000000e4d25c4ddd934d01

# sgdisk --zap-all ${D}
# sgdisk -a1 -n1:24K:+1000K -t1:EF02
# sgdisk     -n2:1M:+512M   -t2:EF00 ${D}
# sgdisk     -n3:0:+512M    -t3:BF01 ${D}
# sgdisk     -n4:0:0        -t4:BF01 ${D}


apt-add-repository universe
apt update
apt install --yes debootstrap gdisk zfs-initramfs git emacs

rm -rf /mnt/*

zpool create -o ashift=12 -d \
      -o feature@async_destroy=enabled \
      -o feature@bookmarks=enabled \
      -o feature@embedded_data=enabled \
      -o feature@empty_bpobj=enabled \
      -o feature@enabled_txg=enabled \
      -o feature@extensible_dataset=enabled \
      -o feature@filesystem_limits=enabled \
      -o feature@hole_birth=enabled \
      -o feature@large_blocks=enabled \
      -o feature@lz4_compress=enabled \
      -o feature@spacemap_histogram=enabled \
      -o feature@userobj_accounting=enabled \
      -O acltype=posixacl -O canmount=off -O compression=lz4 -O devices=off \
      -O normalization=formD -O relatime=on -O xattr=sa \
      -O mountpoint=/ -R /mnt \
      bpool ${D}-part3

zpool create -f -o ashift=12 \
      -O atime=off -O canmount=off -O compression=lz4 -O normalization=formD \
      -O mountpoint=/ -R /mnt \
      rpool ${D}-part4

zfs create -o canmount=off -o mountpoint=none rpool/ROOT
zfs create -o canmount=noauto -o mountpoint=/ rpool/ROOT/ubuntu
zfs mount rpool/ROOT/ubuntu


zfs create                 -o setuid=off              rpool/home
zfs create -o mountpoint=/root                        rpool/home/root
zfs create -o canmount=off -o setuid=off  -o exec=off rpool/var
zfs create -o com.sun:auto-snapshot=false             rpool/var/cache
zfs create                                            rpool/var/log
zfs create                                            rpool/var/spool
zfs create -o com.sun:auto-snapshot=false -o exec=on  rpool/var/tmp

zfs create -o mountpoint=/tmp                         rpool/tmp

#If you use /srv on this system:
zfs create                                            rpool/srv

#If this system will have games installed:
zfs create                                            rpool/var/games

# If this system will store local email in /var/mail:
zfs create                                            rpool/var/mail

#If this system will use NFS (locking):
zfs create -o com.sun:auto-snapshot=false \
             -o mountpoint=/var/lib/nfs                 rpool/var/nfs


chmod 1777 /mnt/var/tmp
debootstrap bionic /mnt
zfs set devices=off rpool


echo ${hname}                    > /mnt/etc/hostname
echo "127.0.1.1       ${hname}" >> /mnt/etc/hosts


cat > /mnt/etc/network/interfaces.d/${ifname} <<EOF
auto ${ifname}
iface ${ifname} inet dhcp
EOF

cat >> /etc/fstab << EOF
rpool/var/log /var/log zfs defaults 0 0
rpool/var/tmp /var/tmp zfs defaults 0 0
EOF

mount --rbind /dev  /mnt/dev
mount --rbind /proc /mnt/proc
mount --rbind /sys  /mnt/sys

mkdir -p /mnt/tmp/
cp update.sh /mnt/tmp/update.sh
chmod 1777 /mnt/tmp/
echo "execute /tmp/update.sh in choot"

chroot /mnt /bin/bash --login
