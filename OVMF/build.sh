#!/bin/bash
apt-get update
apt-get install pve-qemu-kvm gcc-aarch64-linux-gnu gcc-riscv64-linux-gnu libacl1-dev libaio-dev libattr1-dev libcap-ng-dev libcurl4-gnutls-dev libepoxy-dev libfdt-dev libgbm-dev libglusterfs-dev libgnutls28-dev libiscsi-dev libjpeg-dev libnuma-dev libpci-dev libpixman-1-dev libproxmox-backup-qemu0-dev librbd-dev libsdl1.2-dev libseccomp-dev libslirp-dev libspice-protocol-dev libspice-server-dev libsystemd-dev liburing-dev libusb-1.0-0-dev libusbredirparser-dev libvirglrenderer-dev meson python3-sphinx python3-sphinx-rtd-theme quilt xfslibs-dev devscripts -y
wget https://github.com/lixiaoliu666/pve-anti-detection-edk2-firmware-ovmf/raw/refs/heads/main/sedPatch-pve-edk2-firmware-anti-dection.sh
wget https://github.com/Ape-xCV/Nika-Read-Only/raw/refs/heads/main/edk2patch.sh
mv sedPatch-pve-edk2-firmware-anti-dection.sh sedpatch.sh
patch -p1 < edk2patch.patch
git clone git://git.proxmox.com/git/pve-edk2-firmware.git
cd pve-edk2-firmware
mk-build-deps --install
git submodule update --init --recursive
make clean
cp /sys/firmware/acpi/bgrt/image ../Logo.bmp
cp ../Logo.bmp debian/
cp ../sedpatch.sh edk2/
cp ../edk2patch.sh ./
cd edk2
sed -i 's/\(--pcd PcdFirmwareVendor=L"\)[^"]*\\0"/\1INSYDE Corp.\\\\0"/' ../debian/rules
chmod +x sedpatch.sh
bash sedpatch.sh
cd ..
mv edk2 edk2backup
bash edk2patch.sh && rm -rf edk2backup
cd edk2
git diff > edk2-autoGenPatch.patch
cp edk2-autoGenPatch.patch ../
cd ..
rm ../sedpatch.sh ../edk2patch.sh
make
