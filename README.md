# PVE-QEMU-Anti-Detection-Patch

This repository customizes PVE QEMU patches to make your QEMU build *unique*. It integrates patches from multiple sources and compile QEMU and OVMF.

- [Nika-Read-Only by Ape-xCV](https://github.com/Ape-xCV/Nika-Read-Only) (commit: Latest)  
- [pve-anti-detection by lixiaoliu666](https://github.com/lixiaoliu666/pve-anti-detection) (commit: 4c0a73f6898ab48586637eb09c904c6c57db85d3)

## What Doest It Do?

- **Customizable Configuration**: Adjust scripts for your system’s unique values
- **Automated Build Scripts**: Simplified QEMU and OVMF downloading, patching, and compiling  

## Usage

### QEMU Setup

1. Clone the repository:
```bash
git clone https://github.com/KBapna/PVE-QEMU-Anti-Detection-patch.git
cd PVE-QEMU-Anti-Detection-patch/QEMU
```

2. Modify the `sedpatch.sh` script:  

- Use the helper script `GetSysInfo.ps1` to fetch most system values on Windows Host. Some values like `BIOS serials`, and `chassis_type` must be set manually.  
> Tip: use `dmidecode` to extract BIOS-related info on Linux.

3. Once all values are set in sedpatch.sh run the build script:
```bash
./build.sh
```

This will:
- Download QEMU v9.2.0-7  
- Apply all patches in order  
- Build QEMU from source  
- Output `.deb` to `pve-qemu/`

4. Install the built QEMU package:
```bash
dpkg -i pve-qemu/pve-qemu-kvm_9.2.0-7_amd64.deb
```

### OVMF Setup

1. Clone the repository (if not already):
```bash
git clone https://github.com/KBapna/PVE-QEMU-Anti-Detection-patch.git
cd PVE-QEMU-Anti-Detection-patch/OVMF
```

2. Run the build script:
```bash
./build.sh
```

This will:
- Download the latest EDK2 OVMF  
- Apply all patches  
- Build from source  
- Output `.deb` to `pve-edk2-firmware/`

3. Install the built OVMF package:
```bash
dpkg -i pve-edk2-firmware/pve-edk2-firmware-ovmf_4.2025.02-4_all.deb
```

## Virtual Machine Configuration

### Recommended Setup

- **BIOS**: Q35 with OVMF  
- **Storage**: SATA  
- **Graphics**: Passthrough GPU  
- **CPU**: host  
- **Network Adapter**: E1000e  
- **Memory**: 4GB, 8GB, 16GB, etc.

### Example `/etc/pve/qemu-server/100.conf`

```ini
args: -smp 16,cores=8,threads=2,sockets=1 -cpu host,model=0,hypervisor=off,vmware-cpuid-freq=false,enforce=false,host-phys-bits=true -smbios type=0 -smbios type=9 -smbios type=8
balloon: 0
bios: ovmf
boot: order=sata0;net0
cores: 16
cpu: host
efidisk0: local-lvm:vm-100-disk-0,efitype=4m,pre-enrolled-keys=1,size=4M
hostpci0: 0000:01:00,pcie=1
machine: pc-q35-9.2+pve1,enable-s3=1,enable-s4=1
memory: 32768
sata0: local-lvm:vm-100-disk-1,cache=writeback,discard=on,size=512G,ssd=1
scsihw: virtio-scsi-single
smbios1: uuid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX
sockets: 1
tablet: 0
tpmstate0: local-lvm:vm-100-disk-2,size=4M,version=v2.0
usb0: host=1-1
usb1: host=1-2
vga: none
vmgenid: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX
```

### Main Lines in config

```ini
args: -smp 16,cores=8,threads=2,sockets=1 -cpu host,model=0,hypervisor=off,vmware-cpuid-freq=false,enforce=false,host-phys-bits=true -smbios type=0 -smbios type=9 -smbios type=8
```

```ini
machine: pc-q35-9.2+pve1,enable-s3=1,enable-s4=1
```

### Enables:
- 16 vCPUs (8 cores × 2 threads)  `-smp 16,cores=8,threads=2,sockets=1`
- Host CPU passthrough with CPUID spoofing  
- Q35 chipset with sleep state support  
- SMBIOS spoofing to mask virtualization


## Restore Official Packages (If Needed)

```bash
apt reinstall pve-qemu-kvm
apt reinstall pve-edk2-firmware-ovmf
```


## DISCLAIMER

- This project is for **research and educational purposes** only  
- It modifies QEMU to hide virtualization signatures from guests  
- Use responsibly and respect applicable laws and licenses

## Credits

- [Nika-Read-Only by Ape-xCV](https://github.com/Ape-xCV/Nika-Read-Only)  
- [pve-anti-detection by lixiaoliu666](https://github.com/lixiaoliu666/pve-anti-detection)  

These patches were adapted and modularized to patch QEMU releases
