#!/bin/bash
apt-get update
apt-get install wget libacl1-dev libaio-dev libattr1-dev libcap-ng-dev libcurl4-gnutls-dev libepoxy-dev libfdt-dev libgbm-dev libglusterfs-dev libgnutls28-dev libiscsi-dev libjpeg-dev libnuma-dev libpci-dev libpixman-1-dev libproxmox-backup-qemu0-dev librbd-dev libsdl1.2-dev libseccomp-dev libslirp-dev libspice-protocol-dev libspice-server-dev libsystemd-dev liburing-dev libusb-1.0-0-dev libusbredirparser-dev libvirglrenderer-dev meson python3-sphinx python3-sphinx-rtd-theme quilt xfslibs-dev lintian python3-venv xxd bc devscripts -y
wget https://github.com/lixiaoliu666/pve-anti-detection/raw/refs/heads/main/hpet.aml
wget https://raw.githubusercontent.com/lixiaoliu666/pve-anti-detection/refs/heads/9.2.0-6/smbios.h
wget https://raw.githubusercontent.com/lixiaoliu666/pve-anti-detection/refs/heads/9.2.0-6/smbios.c
wget https://github.com/Ape-xCV/Nika-Read-Only/raw/refs/heads/main/qemupatch.sh
wget https://github.com/Ape-xCV/Nika-Read-Only/raw/refs/heads/main/ssdt1.dsl
wget https://github.com/Ape-xCV/Nika-Read-Only/raw/refs/heads/main/ssdt2.dsl
iasl ssdt1.dsl
iasl ssdt2.dsl
xxd -i ssdt1.aml > ssdt1.h
xxd -i ssdt2.aml > ssdt2.h
xxd -i hpet.aml > hpet.h
patch -p1 < qemupatch.patch
git clone git://git.proxmox.com/git/pve-qemu.git
cd pve-qemu
git reset --hard 245689b9ae4120994de29b71595ea58abac06f3c
mk-build-deps --install
git submodule update --init --recursive
make clean
cp ../SSDT.patch qemu/
cp ../ssdt1.h qemu/
cp ../ssdt2.h qemu/
cp ../hpet.h qemu/
cp ../sedpatch.sh qemu/
cp ../qemupatch.sh ./
cd qemu
meson subprojects download
git apply SSDT.patch
chmod +x sedpatch.sh
bash sedpatch.sh
cd ..
mv qemu qemubackup
bash qemupatch.sh && rm -rf qemubackup
cd qemu
cp ../../smbios.h include/hw/firmware/smbios.h
cp ../../smbios.c hw/smbios/smbios.c
bash sedpatch.sh
git diff > qemu-autoGenPatch.patch
cp qemu-autoGenPatch.patch ../
cd ..
rm ../hpet.aml ../ssdt1.aml ../ssdt1.dsl ../ssdt2.aml ../ssdt2.dsl ../hpet.h ../ssdt1.h ../ssdt2.h ../qemupatch.sh ../smbios.c ../smbios.h
mk-build-deps --install
make
