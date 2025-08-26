#!/bin/bash
# This script patches QEMU within pve-qemu-kvm9, supporting version 9.
# Run it once in the QEMU directory before packaging.

# --- USER-DEFINED VALUES ---

# Processor
processor_name="Processr_Name"
processor_manufacturer="GenuineIntel/AuthenticAMD"
processor_family="X"
processor_max_speed="XXXX"
processor_current_speed="XXXX"
cores_per_socket="X"
processor_characteristics_value="XxXX"

# BIOS
bios_manufacturer="BRAND"
smbios_bios_version="BIOS_VER"
bios_serial_number="SERIAL"
bios_release_date_dmidecode="01/01/2001"
bios_major_release="1"
bios_minor_release="99"
bios_start_address="0xXXXX"
bios_characteristics_value="0x0000000000XXXXXXXXX"
bios_characteristics_extension_byte_0="0xXX"
bios_characteristics_extension_byte_1="0xXX"

# System
system_manufacturer="BRAND"
system_model="XXXX"
system_sku="SKU"
system_type="x64-based PC"
system_uuid="XXXXXXXXXXXX"

# Baseboard
baseboard_manufacturer="BRAND"
baseboard_product="XXXXXXXXXXX"
baseboard_version="XXXXXXXXXXXXXX"
baseboard_serial_number="SERIAL"
baseboard_asset_tag="NO Asset Tag"
baseboard_location="Type2 - Board Chassis Location"

# Chassis
chassis_manufacturer="BRAND"
chassis_type="Desktop/Notebook/ETC"
chassis_version="MODEL_NAME"
chassis_serial_number="SERIAL"
chassis_asset_tag="NO Asset Tag"
chassis_sku_number="SKU Number"

# Cache
l1d_cache_size_kb=$(echo "scale=0; 384 / $cores_per_socket" | bc)
l1i_cache_size_kb=$(echo "scale=0; 256 / $cores_per_socket" | bc)
l2_cache_size_kb=$(echo "scale=0; 10 * 1024 / $cores_per_socket" | bc)
l3_cache_size_kb="24576"

# Memory
memory_array_max_capacity_gb="32"
memory_error_correction_type="0x01"
memory_total_width="64"
memory_data_width="64"
memory_form_factor="0x0C"
memory_locator="Controller0-ChannelA-DIMM0"
memory_bank_locator="BANK 0"
memory_type="0x1A"
memory_type_detail="0xXX"
memory_speed="3200"
memory_manufacturer="Micron Technology"
memory_serial_number="XXXXXXXX"
memory_asset_tag="XXXXXXXXXX"
memory_part_number="XXXXXXXXXX-XXXXX"
memory_rank="1"
memory_configured_speed="3200"
memory_configured_voltage="1200"

# Disk
disk_serial_number="XXXX_XXXX_XXXX_XXXX"
disk_model="XXXXXXXXXXXXX"
disk_firmware_version="XXXXXXX"
DISK_PRODUCT_ID="0x1729"

# Network
net_mac_address="XX-XX-XX-XX-XX-XX"

# Machine GUID
machine_guid="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

# Display
display_edid_uid0="EDID"

# --- DERIVED VALUES ---
brand="${system_manufacturer^^}"
if [ -z "$brand" ]; then
    brand="DELL"
fi
product=${chassis_version%% *}
bios_mfg_short="${bios_manufacturer:0:3}"
fixed_len_string_14=$(printf "%-14.14s" "$(echo "${bios_manufacturer}${chassis_version}" | tr -d '[:space:]')")
fixed_len_string_16=$(printf "%-16.16s" "${bios_manufacturer}${bios_serial_number}")
SERIAL_HEX=$(echo -n "$bios_serial_number" | xxd -p | tr -d '\n' | sed 's/^/0x/;s/$/ULL/')
model_nr_hex="${display_edid_uid0:2:4}"
disk_serial_stripped=$(echo "${disk_serial_number}" | tr -d '_.')
disk_serial_16chars=$(printf "%-16.16s" "${disk_serial_stripped}")
hub_id_hex=$(echo "${machine_guid}" | tr -d '-' | cut -c 1-6)
mac_hex=$(echo "${net_mac_address}" | tr -d ':-')

echo "Starting QEMU patching operations..."

# --- SED PATCHES ---

# General QEMU string replacements
sed -i "s/QEMU v\" QEMU_VERSION/${brand} v\" QEMU_VERSION/g" block/vhdx.c
sed -i "s/QEMU VVFAT\", 10/${brand} VVFAT\", 10/g" block/vvfat.c
sed -i "s/QEMU Microsoft Mouse/${brand} Microsoft Mouse/g" chardev/msmouse.c
sed -i "s/QEMU Wacom Pen Tablet/${brand} Wacom Pen Tablet/g" chardev/wctablet.c
sed -i "s/QEMU vhost-user-gpu/${brand} vhost-user-gpu/g" contrib/vhost-user-gpu/vhost-user-gpu.c

# ACPI modifications
sed -i "s/desc->oem_id/\"${brand}\"/g" hw/acpi/aml-build.c
sed -i "s/desc->oem_table_id/\"${product}\"/g" hw/acpi/aml-build.c
sed -i "s/array, ACPI_BUILD_APPNAME8/array, \"${product}\"/g" hw/acpi/aml-build.c
sed -i "s/\"QEMU/\"Intel/g" hw/acpi/aml-build.c
sed -i 's/"QEMUQEQEMUQEMU"/"'"${fixed_len_string_14}"'"/g' hw/acpi/core.c
sed -i 's/"QEMU"/"'${brand}'/g' hw/acpi/core.c
sed -i 's/rev = 3/rev = 4/g' hw/i386/acpi-build.c
sed -i 's/lat = 0xfff/lat = 0x1fff/g' hw/i386/acpi-build.c
sed -i 's/rev = 1/rev = 3/g' hw/i386/acpi-build.c
sed -i 's/if (f->rev <= 4) {/if (f->rev <= 6) {\n\t\tbuild_append_gas_from_struct(tbl, \&f->sleep_ctl);\n\t\tbuild_append_gas_from_struct(tbl, \&f->sleep_sts);/g' hw/acpi/aml-build.c

# EDID (Display) modifications
sed -i "s/info->vendor = \"RHT\"/info->vendor = \"${bios_mfg_short}\"/g" hw/display/edid-generate.c
sed -i "s/QEMU Monitor/${brand} Monitor/g" hw/display/edid-generate.c
sed -i "s/uint16_t model_nr = 0x1234;/uint16_t model_nr = 0x${model_nr_hex};/g" hw/display/edid-generate.c

# i386 and IDE specific replacements
sed -i 's/"QEMU/"'${brand}'/g' hw/i386/fw_cfg.c
sed -i "s/\"QEMU Virtual CPU/\"${processor_name}/g" hw/i386/pc.c
sed -i 's/"QEMU/"'${brand}'/g' hw/i386/pc_piix.c
sed -i "s/Standard PC (i440FX + PIIX, 1996)/${system_manufacturer} ${system_model} ${system_type}/g" hw/i386/pc_piix.c
sed -i 's/"QEMU/"'${brand}'/g' hw/i386/pc_q35.c
sed -i "s/Standard PC (Q35 + ICH9, 2009)/${system_manufacturer} ${system_model} ${system_type}/g" hw/i386/pc_q35.c
sed -i 's/mc->name, pcmc->smbios_legacy_mode,/"'${brand}'-PC", pcmc->smbios_legacy_mode,/g' hw/i386/pc_q35.c
sed -i 's/"QEMU/"'${brand}'/g' hw/ide/atapi.c
sed -i 's/"QEMU/"'${brand}'/g' hw/ide/core.c
sed -i 's/QM%05d/'${brand:0:2}'%05d/g' hw/ide/core.c
sed -i 's/#include "trace.h"/#include "trace.h"\n#include <stdio.h>/g' hw/ide/core.c
sed -i 's/if (dev->serial)/srand(time(NULL));\n\tif (dev->serial)/g' hw/ide/core.c
sed -i 's/QM%05d", s->drive_serial/'${brand}'-%04d-lixiaoliu", rand()%10000/g' hw/ide/core.c
sed -i 's/qemu_hw_version()/s->drive_serial_str/g' hw/ide/core.c
sed -i 's/0x09, 0x03, 0x00, 0x64, 0x64, 0x01, 0x00/0x09, 0x03, 0x00, 0x64, 0x64, 0x9a, 0x02/g' hw/ide/core.c
sed -i 's/0x0c, 0x03, 0x00, 0x64, 0x64, 0x00, 0x00/0x0c, 0x03, 0x00, 0x64, 0x64, 0x9a, 0x02/g' hw/ide/core.c

# Input-specific patches
sed -i 's/"QEMU/"'${brand}'/g' hw/input/adb-kbd.c
sed -i 's/"QEMU/"'${brand}'/g' hw/input/adb-mouse.c
sed -i 's/"QEMU/"'${brand}'/g' hw/input/hid.c
sed -i 's/"QEMU/"'${brand}'/g' hw/input/ps2.c
sed -i 's/"QEMU Virtio/"'${brand}'/g' hw/input/virtio-input-hid.c
sed -i 's/0x0627/0x1089/g' hw/input/virtio-input-hid.c
sed -i 's/0x0627/0x1729/g' hw/usb/dev-hid.c
sed -i 's/0x1af4/0x8086/g' hw/audio/hda-codec.c

# Misc hardware replacements
sed -i "s/QEMU M68K Virtual Machine/${brand} ${system_type}/g" hw/m68k/virt.c
sed -i "s/\"QEMU/\"${brand}/g" hw/misc/pvpanic-isa.c
sed -i "s/\"QEMU/\"${brand}/g" hw/nvme/ctrl.c
sed -i "s/\"QEMU/\"${brand}/g" hw/nvram/fw_cfg-acpi.c
sed -i "s/0x51454d5520434647ULL/${SERIAL_HEX}/g" hw/nvram/fw_cfg.c
sed -i "s/\"QEMU/\"${brand}/g" hw/pci-host/gpex.c
sed -i "s/\"QEMU/\"${brand}/g" hw/ppc/prep.c
sed -i "s/\"QEMU/\"${brand}/g" hw/ppc/e500plat.c
sed -i "s/qemu-e500/${brand,,}-e500/g" hw/ppc/e500plat.c
sed -i "s/\"QEMU Virtual/\"${brand}/g" hw/riscv/virt.c
sed -i "s/\"KVM Virtual/\"${brand}/g" hw/riscv/virt.c
sed -i "s/\"QEMU/\"${brand}/g" hw/riscv/virt.c
sed -i "s/\"QEMU/\"${brand}/g" hw/sd/sd.c
sed -i "s/\"QEMU/\"${brand}/g" hw/ufs/lu.c
sed -i 's/"WAET"/"WWWT"/g' hw/i386/acpi-build.c
sed -i 's/!object_dynamic_cast/object_dynamic_cast/g' hw/vfio/igd.c
sed -i 's/#define PCI_SUBVENDOR_ID_REDHAT_QUMRANET 0x1af4/#define PCI_SUBVENDOR_ID_REDHAT_QUMRANET 0x8086/g' include/hw/pci/pci.h

# USB modifications
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/dev-audio.c
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/dev-hid.c
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/dev-hub.c
sed -i "s/314159/${hub_id_hex}/g" hw/usb/dev-hub.c
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/dev-mtp.c
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/dev-network.c
sed -i "s/\"RNDIS\/QEMU/\"RNDIS\/'${brand}'/g" hw/usb/dev-network.c
sed -i "s/400102030405/${mac_hex}/g" hw/usb/dev-network.c
sed -i "s/s->vendorid = 0x1234;/s->vendorid = 0x8086;/g" hw/usb/dev-network.c
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/dev-serial.c
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/dev-smartcard-reader.c
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/dev-storage.c
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/dev-uas.c
sed -i "s/27842/${DISK_PRODUCT_ID}/g" hw/usb/dev-uas.c
sed -i 's/QEMU Sun Mouse/'${brand}' Sun Mouse/g' hw/char/escc.c
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/dev-wacom.c
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/u2f-emulated.c
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/u2f-passthru.c
sed -i "s/\"QEMU/\"${brand}/g" hw/usb/u2f.c

# SCSI modifications
sed -i "s/s16s8s16s16s16/${disk_model}/g" hw/scsi/mptconfig.c
sed -i "s/\"2.5\"/\"${disk_firmware_version}\"/g" hw/scsi/mptconfig.c
sed -i "s/QEMU MPT Fusion/${disk_model}/g" hw/scsi/mptconfig.c
sed -i "s/\"QEMU\"/\"${disk_model:0:4}\"/g" hw/scsi/mptconfig.c
sed -i "s/0000111122223333/${disk_serial_16chars}/g" hw/scsi/mptconfig.c
sed -i "s/\"QEMU/\"${brand}/g" hw/scsi/scsi-bus.c
sed -i "s/\"QEMU/\"${brand}/g" hw/scsi/megasas.c
sed -i "s/\"QEMU/\"${brand}/g" hw/scsi/scsi-disk.c
sed -i "s/\"QEMU/\"${brand}/g" hw/scsi/spapr_vscsi.c
sed -i 's/qemu_hw_version()/"1089"/g' hw/scsi/scsi-bus.c
sed -i 's/qemu_hw_version()/"1729"/g' hw/scsi/scsi-disk.c

# Include header modifications
sed -i "s/\"BOCHS/\"${bios_mfg_short}C/g" include/hw/acpi/aml-build.h
sed -i "s/\"BXPC/\"${bios_mfg_short}PC/g" include/hw/acpi/aml-build.h
sed -i 's/"QEMU0002/"'${brand}'0002/g' include/standard-headers/linux/qemu_fw_cfg.h
sed -i "s/0x51454d5520434647ULL/${SERIAL_HEX}/g" include/standard-headers/linux/qemu_fw_cfg.h

# Migration related
sed -i "s/\"QEMU/\"${brand}/g" migration/options.c
sed -i "s/\"QEMU/\"${brand}/g" migration/rdma.c

# PC BIOS modifications
sed -i "s/\"QEMU/\"${brand}/g" pc-bios/s390-ccw/virtio-scsi.h
sed -i "s/0x51454d5520434647ULL/${SERIAL_HEX}/g" pc-bios/optionrom/optionrom.h
sed -i "s/\"QEMU/\"${brand}/g" roms/seabios/src/fw/ssdt-misc.dsl
sed -i "s/\"QEMU/\"${brand}/g" roms/seabios-hppa/src/fw/ssdt-misc.dsl

# Target specific modifications
sed -i 's/memcpy(signature, "KVMKVMKVM\\0\\0\\0", 12);/memcpy(signature, "\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0", 12);/' target/i386/kvm/kvm.c
#sed -i "s/KVMKVMKVM\\\\0\\\\0\\\\0/${processor_manufacturer}/g" target/i386/kvm/kvm.c # can cause issues with Nvidia Card (code 43)
sed -i "s/\"Microsoft Hv/\"${processor_manufacturer}/g" target/i386/cpu.c
sed -i 's|QEMUQEMUQEMUQEMU|'"${fixed_len_string_16}"'|g' target/s390x/tcg/misc_helper.c
sed -i 's/"QEMU/"'${brand}'/g' target/s390x/tcg/misc_helper.c
sed -i 's/"KVM/"ATX/g' target/s390x/tcg/misc_helper.c

# SMBIOS modifications

# Type 0 (BIOS Information)
sed -i "s|SMBIOS_TABLE_SET_STR(0, vendor_str, \"American Megatrends International LLC.\");|SMBIOS_TABLE_SET_STR(0, vendor_str, \"${bios_manufacturer}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(0, bios_version_str, \"H3.7G\");|SMBIOS_TABLE_SET_STR(0, bios_version_str, \"${smbios_bios_version}\");|g" hw/smbios/smbios.c
sed -i "s|t->bios_starting_address_segment = cpu_to_le16(0xE800);|t->bios_starting_address_segment = cpu_to_le16(${bios_start_address});|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(0, bios_release_date_str, \"02/21/2023\");|SMBIOS_TABLE_SET_STR(0, bios_release_date_str, \"${bios_release_date_dmidecode}\");|g" hw/smbios/smbios.c
sed -i "s|t->bios_characteristics = cpu_to_le64(0x08);|t->bios_characteristics = cpu_to_le64(${bios_characteristics_value});|g" hw/smbios/smbios.c
sed -i "s|t->bios_characteristics_extension_bytes\[0\] = 0xEF;.*|t->bios_characteristics_extension_bytes[0] = ${bios_characteristics_extension_byte_0};|g" hw/smbios/smbios.c
sed -i "s|t->bios_characteristics_extension_bytes\[1\] = 0x0F;|t->bios_characteristics_extension_bytes[1] = ${bios_characteristics_extension_byte_1};|g" hw/smbios/smbios.c
sed -i "s|t->system_bios_major_release = 3;|t->system_bios_major_release = ${bios_major_release};|g" hw/smbios/smbios.c
sed -i "s|t->system_bios_minor_release = 7;|t->system_bios_minor_release = ${bios_minor_release};|g" hw/smbios/smbios.c
sed -i "s|t->embedded_controller_major_release = 0xFF;|t->embedded_controller_major_release = ${bios_major_release};|g" hw/smbios/smbios.c
sed -i "s|t->embedded_controller_minor_release = 0xFF;|t->embedded_controller_minor_release = ${bios_minor_release};|g" hw/smbios/smbios.c

# Type 1 (System Information)
sed -i "s|SMBIOS_TABLE_SET_STR(1, manufacturer_str, \"Maxsun\");|SMBIOS_TABLE_SET_STR(1, manufacturer_str, \"${system_manufacturer}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(1, product_name_str, motherboard);|SMBIOS_TABLE_SET_STR(1, product_name_str, \"${chassis_version}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(1, version_str, \"VER:H3.7G(2022/11/29)\");|SMBIOS_TABLE_SET_STR(1, version_str, \"${smbios_bios_version}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(1, serial_number_str, \"Default string\");|SMBIOS_TABLE_SET_STR(1, serial_number_str, \"${bios_serial_number}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(1, sku_number_str, \"Default string\");|SMBIOS_TABLE_SET_STR(1, sku_number_str, \"${system_sku}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(1, family_str, \"Default string\");|SMBIOS_TABLE_SET_STR(1, family_str, \"${chassis_version}\");|g" hw/smbios/smbios.c

# Type 2 (Base Board Information)
sed -i "s|SMBIOS_TABLE_SET_STR(2, manufacturer_str, \"Maxsun\");|SMBIOS_TABLE_SET_STR(2, manufacturer_str, \"${baseboard_manufacturer}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(2, product_str, motherboard);|SMBIOS_TABLE_SET_STR(2, product_str, \"${baseboard_product}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(2, version_str, \"VER:H3.7G(2022/11/29)\");|SMBIOS_TABLE_SET_STR(2, version_str, \"${baseboard_version}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(2, serial_number_str, \"Default string\");|SMBIOS_TABLE_SET_STR(2, serial_number_str, \"${baseboard_serial_number}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(2, asset_tag_number_str,\"Default string\");|SMBIOS_TABLE_SET_STR(2, asset_tag_number_str,\"${baseboard_asset_tag}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(2, location_str,\"Default string\");|SMBIOS_TABLE_SET_STR(2, location_str,\"${baseboard_location}\");|g" hw/smbios/smbios.c

# Type 3 (System Enclosure)
sed -i "s|SMBIOS_TABLE_SET_STR(3, manufacturer_str, \"Default string\");|SMBIOS_TABLE_SET_STR(3, manufacturer_str, \"${chassis_manufacturer}\");|g" hw/smbios/smbios.c
sed -i 's/t->type = 0x01; \/\* Other \*\//t->type = 0x0A; \/\* Notebook \*\//g' hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(3, version_str, \"Default string\");|SMBIOS_TABLE_SET_STR(3, version_str, \"${chassis_version}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(3, serial_number_str, \"Default string\");|SMBIOS_TABLE_SET_STR(3, serial_number_str, \"${chassis_serial_number}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(3, asset_tag_number_str, \"Default string\");|SMBIOS_TABLE_SET_STR(3, asset_tag_number_str, \"${chassis_asset_tag}\");|g" hw/smbios/smbios.c
sed -i "s|t->security_status = 0x03;.*|t->security_status = 0x02; /* None */|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(3, sku_number_str, \"Default string\");|SMBIOS_TABLE_SET_STR(3, sku_number_str, \"${chassis_sku_number}\");|g" hw/smbios/smbios.c

# Type 4 (Processor Information)
sed -i "s|SMBIOS_TABLE_SET_STR(4, socket_designation_str, \"LGA1700\");|SMBIOS_TABLE_SET_STR(4, socket_designation_str, \"U3E1\");|g" hw/smbios/smbios.c
sed -i "s|t->processor_family = 0xC6;|t->processor_family = $(printf "0x%x" ${processor_family});|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(4, processor_manufacturer_str, \"Intel(R) Corporation\");|SMBIOS_TABLE_SET_STR(4, processor_manufacturer_str, \"${processor_manufacturer}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(4, processor_version_str, \"12th Gen Intel(R) Core(TM) i7\");|SMBIOS_TABLE_SET_STR(4, processor_version_str, \"${processor_name}\");|g" hw/smbios/smbios.c
sed -i "s|t->max_speed = cpu_to_le16(4900);|t->max_speed = cpu_to_le16(${processor_max_speed});|g" hw/smbios/smbios.c
sed -i "s|t->current_speed = cpu_to_le16(4455);|t->current_speed = cpu_to_le16(${processor_current_speed});|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(4, serial_number_str, \"To Be Filled By O.E.M.\");|SMBIOS_TABLE_SET_STR(4, serial_number_str, \"${baseboard_serial_number}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(4, asset_tag_number_str, \"To Be Filled By O.E.M.\");|SMBIOS_TABLE_SET_STR(4, asset_tag_number_str, \"${baseboard_asset_tag}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(4, part_number_str, \"To Be Filled By O.E.M.\");|SMBIOS_TABLE_SET_STR(4, part_number_str, \"${baseboard_product}\");|g" hw/smbios/smbios.c
sed -i "s|t->processor_characteristics = cpu_to_le16(0x04);.*|t->processor_characteristics = cpu_to_le16(${processor_characteristics_value}); /* 64-bit Capable */|g" hw/smbios/smbios.c
sed -i "s|t->processor_family2 = cpu_to_le16(0xC6);|t->processor_family2 = cpu_to_le16(${processor_family});|g" hw/smbios/smbios.c
sed -i 's/t->l1_cache_handle = cpu_to_le16(0xFFFF);/t->l1_cache_handle = cpu_to_le16(0x0039);/g' hw/smbios/smbios.c
sed -i 's/t->l2_cache_handle = cpu_to_le16(0xFFFF);/t->l2_cache_handle = cpu_to_le16(0x003A);/g' hw/smbios/smbios.c
sed -i 's/t->l3_cache_handle = cpu_to_le16(0xFFFF);/t->l3_cache_handle = cpu_to_le16(0x003B);/g' hw/smbios/smbios.c
sed -i 's/t->external_clock = cpu_to_le16(0);/t->external_clock = cpu_to_le16(100);/g' hw/smbios/smbios.c
sed -i 's/t->voltage = 0;/t->voltage = 0x8B;/g' hw/smbios/smbios.c

# Type 7 (Cache Information)
sed -i "s|smbios_build_type_7_table(0,\"L1 Cache\",0x180,cores_per_socket\*0x20,0x4,0x4,0x7);|smbios_build_type_7_table(0,\"L1 Cache\",0x180,${l1d_cache_size_kb},0x4,0x4,0x9);|g" hw/smbios/smbios.c
sed -i "s|smbios_build_type_7_table(1,\"L1 Cache\",0x180,cores_per_socket\*0x20,0x4,0x3,0x7);|smbios_build_type_7_table(1,\"L1 Cache\",0x180,${l1i_cache_size_kb},0x4,0x3,0x7);|g" hw/smbios/smbios.c
sed -i "s|smbios_build_type_7_table(2,\"L2 Cache\",0x181,cores_per_socket\*0x800,0x5,0x4,0x8);|smbios_build_type_7_table(2,\"L2 Cache\",0x181,${l2_cache_size_kb},0x5,0x5,0x0);|g" hw/smbios/smbios.c
sed -i "s|smbios_build_type_7_table(3,\"L2 Cache\",0x181,cores_per_socket\*0x800,0x5,0x3,0x8);|smbios_build_type_7_table(3,\"L3 Cache\",0x182,${l3_cache_size_kb},0x6,0x5,0x9);|g" hw/smbios/smbios.c
sed -i "/unsigned cores_per_socket = machine_topo_get_cores_per_socket(ms);/d" hw/smbios/smbios.c
sed -i '/smbios_build_type_7_table(3,"L2 Cache",0x181,cores_per_socket\*0x800,0x5,0x3,0x8);/d' hw/smbios/smbios.c
sed -i '/smbios_build_type_7_table(4,"L3 Cache",0x182,0x2000,0x6,0x5,0x8);/d' hw/smbios/smbios.c
sed -i '/smbios_build_type_7_table(5,"L3 Cache",0x182,0x2000,0x6,0x5,0x8);/d' hw/smbios/smbios.c
sed -i '/smbios_build_type_7_table(6,"lixiaoliu L4 Cache",0x183,0x4000,0x6,0x5,0x1);/d' hw/smbios/smbios.c

# Type 16 (Physical Memory Array)
sed -i "s|t->error_correction = 0x03;|t->error_correction = ${memory_error_correction_type};|g" hw/smbios/smbios.c

# Type 17 (Memory Device)
sed -i "s|t->total_width = cpu_to_le16(64);.*|t->total_width = cpu_to_le16(${memory_total_width});|g" hw/smbios/smbios.c
sed -i 's/t->data_width = cpu_to_le16(0xFFFF);/t->data_width = cpu_to_le16(64);/g' hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(17, manufacturer_str, \"Kingston\");|SMBIOS_TABLE_SET_STR(17, manufacturer_str, \"${memory_manufacturer}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(17, serial_number_str, \"DF1EC466\");|SMBIOS_TABLE_SET_STR(17, serial_number_str, \"${memory_serial_number}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_TABLE_SET_STR(17, part_number_str, \"KHX1600C9S3L/8G\");|SMBIOS_TABLE_SET_STR(17, part_number_str, \"${memory_part_number}\");|g" hw/smbios/smbios.c
sed -i 's/t->minimum_voltage = cpu_to_le16(0);/t->minimum_voltage = cpu_to_le16(1350);/g' hw/smbios/smbios.c
sed -i 's/t->maximum_voltage = cpu_to_le16(0);/t->maximum_voltage = cpu_to_le16(1500);/g' hw/smbios/smbios.c
sed -i 's/t->configured_voltage = cpu_to_le16(0);/t->configured_voltage = cpu_to_le16(1350);/g' hw/smbios/smbios.c
sed -i 's/t->location = 0x01;/t->location = 0x03;/g' hw/smbios/smbios.c
sed -i 's/t->memory_type = 0x07;/t->memory_type = 0x1A;/g' hw/smbios/smbios.c

# Initializing defaults in smbios_defaults_init
sed -i "s|SMBIOS_SET_DEFAULT(smbios_type1.manufacturer, \"Maxsun\");|SMBIOS_SET_DEFAULT(smbios_type1.manufacturer, \"${system_manufacturer}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_SET_DEFAULT(smbios_type1.product, \"MS-Terminator B760M\");|SMBIOS_SET_DEFAULT(smbios_type1.product, \"${system_model}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_SET_DEFAULT(smbios_type1.version, \"VER:H3.7G(2022/11/29)\");|SMBIOS_SET_DEFAULT(smbios_type1.version, \"${smbios_bios_version}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_SET_DEFAULT(type2.manufacturer, \"Maxsun\");|SMBIOS_SET_DEFAULT(type2.manufacturer, \"${baseboard_manufacturer}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_SET_DEFAULT(type2.product, \"MS-Terminator B760M\");|SMBIOS_SET_DEFAULT(type2.product, \"${baseboard_product}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_SET_DEFAULT(type2.version, \"VER:H3.7G(2022/11/29)\");|SMBIOS_SET_DEFAULT(type2.version, \"${baseboard_version}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_SET_DEFAULT(type3.manufacturer, \"Default string\");|SMBIOS_SET_DEFAULT(type3.manufacturer, \"${chassis_manufacturer}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_SET_DEFAULT(type3.version, \"Default string\");|SMBIOS_SET_DEFAULT(type3.version, \"${chassis_version}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_SET_DEFAULT(type4.manufacturer, \"Intel(R) Corporation\");|SMBIOS_SET_DEFAULT(type4.manufacturer, \"${processor_manufacturer}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_SET_DEFAULT(type4.version, \"12th Gen Intel(R) Core(TM) i7-12700\");|SMBIOS_SET_DEFAULT(type4.version, \"${processor_name}\");|g" hw/smbios/smbios.c
sed -i "s|SMBIOS_SET_DEFAULT(type17.manufacturer, \"KINGSTON\");|SMBIOS_SET_DEFAULT(type17.manufacturer, \"${memory_manufacturer}\");|g" hw/smbios/smbios.c

# CPU specific
sed -i "s/\"QEMU TCG CPU version/\"TCG CPU version/g" target/i386/cpu.c

# --- ONE-TIME PATCHES ---

grep -q "do this once" hw/i2c/smbus_eeprom.c
if [ $? -ne 0 ]; then
    sed -i 's/for (i = 0; i < nb_eeprom/\/\/do this once\n#include<stdio.h>\neeprom_buf[0]=0x92;\neeprom_buf[1]=0x10;\neeprom_buf[2]=0x0B;\neeprom_buf[3]=0x03;\neeprom_buf[4]=0x04;\neeprom_buf[5]=0x21;\neeprom_buf[6]=0x02;\neeprom_buf[7]=0x09;\neeprom_buf[8]=0x03;\neeprom_buf[9]=0x52;\neeprom_buf[0x0a]=0x01;\neeprom_buf[0x0b]=0x08;\neeprom_buf[0x0c]=0x0A;\neeprom_buf[0x0d]=0x00;\neeprom_buf[0x0e]=0xFE;\neeprom_buf[0x0f]=0x00;\neeprom_buf[0x10]=0x5A;\neeprom_buf[0x11]=0x78;\neeprom_buf[0x12]=0x5A;\neeprom_buf[0x13]=0x30;\neeprom_buf[0x14]=0x5A;\neeprom_buf[0x15]=0x11;\neeprom_buf[0x16]=0x0E;\neeprom_buf[0x17]=0x81;\neeprom_buf[0x18]=0x20;\neeprom_buf[0x19]=0x08;\neeprom_buf[0x1a]=0x3C;\neeprom_buf[0x1b]=0x3C;\neeprom_buf[0x1c]=0x00;\neeprom_buf[0x1d]=0xF0;\neeprom_buf[0x1e]=0x83;\neeprom_buf[0x1f]=0x81;\neeprom_buf[0x3c]=0x0F;\neeprom_buf[0x3d]=0x11;\neeprom_buf[0x3e]=0x65;\neeprom_buf[0x3f]=0x00;\neeprom_buf[0x70]=0x00;\neeprom_buf[0x71]=0x00;\neeprom_buf[0x72]=0x00;\neeprom_buf[0x73]=0x00;\neeprom_buf[0x74]=0x00;\neeprom_buf[0x75]=0x01;\neeprom_buf[0x76]=0x98;\neeprom_buf[0x77]=0x07;\neeprom_buf[0x78]=0x25;\neeprom_buf[0x79]=0x18;\neeprom_buf[0x7a]=0x20;\neeprom_buf[0x7b]=0x25;\nsrand(time(NULL));\nint rr=rand()%10000;\neeprom_buf[0x7c]=rr>>8;\neeprom_buf[0x7d]=rr;\neeprom_buf[0x7e]=0xB3;\neeprom_buf[0x7f]=0x21;\neeprom_buf[0x80]=0x4B;\neeprom_buf[0x81]=0x48;\neeprom_buf[0x82]=0x58;\neeprom_buf[0x83]=0x31;\neeprom_buf[0x84]=0x36;\neeprom_buf[0x85]=0x30;\neeprom_buf[0x86]=0x30;\neeprom_buf[0x87]=0x43;\neeprom_buf[0x88]=0x39;\neeprom_buf[0x89]=0x53;\neeprom_buf[0x8a]=0x33;\neeprom_buf[0x8b]=0x4C;\neeprom_buf[0x8c]=0x2F;\neeprom_buf[0x8d]=0x38;\neeprom_buf[0x8e]=0x47;\neeprom_buf[0x8f]=0x20;\neeprom_buf[0x90]=0x20;\neeprom_buf[0x91]=0x20;\neeprom_buf[0x92]=0x00;\neeprom_buf[0x93]=0x00;\neeprom_buf[0x94]=0x00;\neeprom_buf[0x95]=0x00;\neeprom_buf[0xfe]=0x00;\neeprom_buf[0xff]=0x5A;\nfor (i = 0; i < nb_eeprom/g' hw/i2c/smbus_eeprom.c
    echo "hw/i2c/smbus_eeprom.c processed (one-time)."
else
    echo "hw/i2c/smbus_eeprom.c already processed. Skipping."
fi

grep -q "do this once" hw/acpi/vmgenid.c
if [ $? -ne 0 ]; then
    sed -i 's/    Aml \*ssdt/        \/\/INTELINSIDE\n        return;\/\/do this once\n    Aml \*ssdt/g' hw/acpi/vmgenid.c
    echo "hw/acpi/vmgenid.c processed (one-time)."
else
    echo "hw/acpi/vmgenid.c already processed. Skipping."
fi

# acpi-build.c one-time patch (comments out fw_cfg node creation)
grep -q "do this once" hw/i386/acpi-build.c
if [ $? -ne 0 ]; then
    sed -i '/static void build_dbg_aml(Aml \*table)/,/ /s/{/{\n      return;\/\/do this once/g' hw/i386/acpi-build.c
#   sed -i 's/dev = aml_device("PCI0");/aml_append(sb_scope, aml_name_decl("OSYS", aml_int(0x03E8)));\n\tAml *osi = aml_if(aml_equal(aml_call1("_OSI", aml_string("Windows 2012")), aml_int(1)));\n\taml_append(osi, aml_store(aml_int(0x07DC), aml_name("OSYS")));\n\taml_append(sb_scope, osi);\n\tosi = aml_if(aml_equal(aml_call1("_OSI",aml_string("Windows 2013")), aml_int(1)));\n\taml_append(osi, aml_store(aml_int(0x07DD), aml_name("OSYS")));\n\taml_append(sb_scope, osi);\n\taml_append(sb_scope, aml_name_decl("_TZ", aml_int(0x03E8)));\n\taml_append(sb_scope, aml_name_decl("_PTS", aml_int(0x03E8)));\n\tdev = aml_device("PCI0");/g' hw/i386/acpi-build.c
    sed -i '/create fw_cfg node/,/}/s/}/}*\//g' hw/i386/acpi-build.c
    sed -i '/create fw_cfg node/,/}/s/{/\/*{/g' hw/i386/acpi-build.c
    echo "hw/i386/acpi/build.c processed (one-time)."
else
    echo "hw/i386/acpi/build.c already processed. Skipping."
fi
echo "All QEMU patching operations completed. ✨"
