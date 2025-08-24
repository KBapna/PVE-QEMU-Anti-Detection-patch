# ===================== Processor =====================
$processor_name = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
$processor_manufacturer = (Get-CimInstance Win32_Processor | Select-Object -First 1).Manufacturer
$processor_family = (Get-CimInstance Win32_Processor | Select-Object -First 1).Family
$processor_max_speed = (Get-CimInstance Win32_Processor | Select-Object -First 1).MaxClockSpeed
$processor_current_speed = (Get-CimInstance Win32_Processor | Select-Object -First 1).CurrentClockSpeed
$cores_per_socket = (Get-CimInstance Win32_Processor | Select-Object -First 1).NumberOfCores
$processor_characteristics_value_numeric = (Get-CimInstance Win32_Processor | Select-Object -First 1).ProcessorType
$processor_characteristics_value = "0x{0:X2}" -f $processor_characteristics_value_numeric

# ===================== BIOS =====================
$bios = Get-CimInstance Win32_BIOS | Select-Object -First 1
$bios_manufacturer = $bios.Manufacturer
$smbios_bios_version = $bios.SMBIOSBIOSVersion
$bios_serial_number = $bios.SerialNumber
# GET DMIDECODE VALUES
$bios_release_date_dmidecode = if ($bios.ReleaseDate) { [System.Management.ManagementDateTimeConverter]::ToDateTime($bios.ReleaseDate).ToString('MM/dd/yyyy') } else { "Not Available" }
$bios_major_release = "X"
$bios_minor_release = "XX"
$bios_start_address = "0xXXXX"
$bios_characteristics_value = "0x0000000000XXXXXXXXX"
$bios_characteristics_extension_byte_0 = "0xXX"
$bios_characteristics_extension_byte_1 = "0xXX"

# ===================== System =====================
$sys = Get-CimInstance Win32_ComputerSystem | Select-Object -First 1
$system_manufacturer = $sys.Manufacturer
$system_model = $sys.Model
$system_sku = $sys.SystemSKUNumber
$system_type = $sys.SystemType
$system_uuid = (Get-CimInstance Win32_ComputerSystemProduct | Select-Object -First 1).UUID

# ===================== Baseboard =====================
$board = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
$baseboard_manufacturer = $board.Manufacturer
$baseboard_product = $board.Product
$baseboard_version = $board.Version
$baseboard_serial_number = $board.SerialNumber
$baseboard_asset_tag = $board.Tag
$baseboard_location = "Type2 - Board Chassis Location"

# ===================== Chassis =====================
$chassis = Get-CimInstance Win32_SystemEnclosure | Select-Object -First 1
$chassis_manufacturer = $chassis.Manufacturer
$chassis_type_number = $chassis.ChassisTypes
$chassis_type_map = @{
    1 = "Other"
    2 = "Unknown"
    3 = "Desktop"
    4 = "Low Profile Desktop"
    5 = "Pizza Box"
    6 = "Mini Tower"
    7 = "Tower"
    8 = "Portable"
    9 = "Laptop"
    10 = "Notebook"
    11 = "Hand Held"
    12 = "Docking Station"
    13 = "All in One"
    14 = "Sub-Laptop"
    15 = "Space-saving"
    16 = "Lunch Box"
    17 = "Main System Chassis"
    18 = "Expansion Chassis"
    19 = "Component Chassis"
    20 = "Rack Mount Chassis"
    21 = "Compact PCI"
    22 = "Advanced TCA"
    23 = "Blade"
    24 = "Blade Enclosure"
    25 = "Stick PC"
    26 = "Mini PC"
    27 = "Stick PC"
}
$chassis_type = if ($chassis_type_number -is [System.Array]) {
    $chassis_type_number | ForEach-Object { $chassis_type_map[$_] }
} else {
    $chassis_type_map[$chassis_type_number]
}
$chassis_version = $chassis.Version
$chassis_serial_number = $chassis.SerialNumber
$chassis_asset_tag = $chassis.SMBIOSAssetTag
$chassis_sku_number = "SKU Number"

# ===================== Cache =====================
$l1d_cache_size_kb = [math]::Round(384 / $cores_per_socket)
$l1i_cache_size_kb = [math]::Round(256 / $cores_per_socket)
$l2_cache_size_kb = [math]::Round((10 * 1024) / $cores_per_socket)
$l3_cache_size_kb = 24576

# ===================== Memory =====================
$mem = Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1
$memArray = Get-CimInstance Win32_PhysicalMemoryArray
$memory_array_max_capacity_gb = [math]::Round($memArray.MaxCapacity / 1GB)
$memory_error_correction_type = "0x01"
$memory_total_width = $mem.TotalWidth
$memory_data_width = $mem.DataWidth
$memory_form_factor = "0x0C"
$memory_locator = "Controller0-ChannelA-DIMM0"
$memory_bank_locator = "BANK 0"
$memory_type = "0x1A"
$memory_type_detail = "0x80"
$memory_speed = $mem.Speed
$memory_manufacturer = $mem.Manufacturer
$memory_serial_number = $mem.SerialNumber
$memory_asset_tag = $mem.AssetTag
$memory_part_number = $mem.PartNumber
$memory_rank = "1"
$memory_configured_speed = $mem.ConfiguredClockSpeed
$memory_configured_voltage = $mem.ConfiguredVoltage

# ===================== Disk =====================
$disk = Get-CimInstance Win32_DiskDrive | Select-Object -First 1
$disk_serial_number = $disk.SerialNumber
$disk_model = $disk.Model
$disk_firmware_version = $disk.FirmwareRevision
$DISK_PRODUCT_ID = "0x1729"

# ===================== Network =====================
$net = Get-CimInstance Win32_NetworkAdapter | Where-Object {$_.MACAddress -ne $null} | Select-Object -First 1
$net_mac_address = $net.MACAddress

# ===================== Machine GUID =====================
$machine_guid = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid").MachineGuid

# ===================== Display =====================
$display_edid_uid0 = "EDID" # Placeholder for EDID UID

# Output all values in the specified INFO="VALUE" format
Write-Host "`n# Processor"
Write-Host "processor_name=`"$processor_name`""
Write-Host "processor_manufacturer=`"$processor_manufacturer`""
Write-Host "processor_family=`"$processor_family`""
Write-Host "processor_max_speed=`"$processor_max_speed`""
Write-Host "processor_current_speed=`"$processor_current_speed`""
Write-Host "cores_per_socket=`"$cores_per_socket`""
Write-Host "processor_characteristics_value=`"$processor_characteristics_value`""

Write-Host "`n# BIOS"
Write-Host "bios_manufacturer=`"$bios_manufacturer`""
Write-Host "smbios_bios_version=`"$smbios_bios_version`""
Write-Host "bios_serial_number=`"$bios_serial_number`""
Write-Host "`n# GET DMIDECODE VALUES"
Write-Host "bios_release_date_dmidecode=`"$bios_release_date_dmidecode`""
Write-Host "bios_major_release=`"$bios_major_release`""
Write-Host "bios_minor_release=`"$bios_minor_release`""
Write-Host "bios_start_address=`"$bios_start_address`""
Write-Host "bios_characteristics_value=`"$bios_characteristics_value`""
Write-Host "bios_characteristics_extension_byte_0=`"$bios_characteristics_extension_byte_0`""
Write-Host "bios_characteristics_extension_byte_1=`"$bios_characteristics_extension_byte_1`""

Write-Host "`n# System"
Write-Host "system_manufacturer=`"$system_manufacturer`""
Write-Host "system_model=`"$system_model`""
Write-Host "system_sku=`"$system_sku`""
Write-Host "system_type=`"$system_type`""
Write-Host "system_uuid=`"$system_uuid`""

Write-Host "`n# Baseboard"
Write-Host "baseboard_manufacturer=`"$baseboard_manufacturer`""
Write-Host "baseboard_product=`"$baseboard_product`""
Write-Host "baseboard_version=`"$baseboard_version`""
Write-Host "baseboard_serial_number=`"$baseboard_serial_number`""
Write-Host "baseboard_asset_tag=`"$baseboard_asset_tag`""
Write-Host "baseboard_location=`"$baseboard_location`""

Write-Host "`n# Chassis"
Write-Host "chassis_manufacturer=`"$chassis_manufacturer`""
Write-Host "chassis_type=`"$chassis_type`""
Write-Host "chassis_version=`"$chassis_version`""
Write-Host "chassis_serial_number=`"$chassis_serial_number`""
Write-Host "chassis_asset_tag=`"$chassis_asset_tag`""
Write-Host "chassis_sku_number=`"$chassis_sku_number`""

Write-Host "`n# Cache"
Write-Host "l1d_cache_size_kb=`"$l1d_cache_size_kb`""
Write-Host "l1i_cache_size_kb=`"$l1i_cache_size_kb`""
Write-Host "l2_cache_size_kb=`"$l2_cache_size_kb`""
Write-Host "l3_cache_size_kb=`"$l3_cache_size_kb`""

Write-Host "`n# Memory"
Write-Host "memory_array_max_capacity_gb=`"$memory_array_max_capacity_gb`""
Write-Host "memory_error_correction_type=`"$memory_error_correction_type`""
Write-Host "memory_total_width=`"$memory_total_width`""
Write-Host "memory_data_width=`"$memory_data_width`""
Write-Host "memory_form_factor=`"$memory_form_factor`""
Write-Host "memory_locator=`"$memory_locator`""
Write-Host "memory_bank_locator=`"$memory_bank_locator`""
Write-Host "memory_type=`"$memory_type`""
Write-Host "memory_type_detail=`"$memory_type_detail`""
Write-Host "memory_speed=`"$memory_speed`""
Write-Host "memory_manufacturer=`"$memory_manufacturer`""
Write-Host "memory_serial_number=`"$memory_serial_number`""
Write-Host "memory_asset_tag=`"$memory_asset_tag`""
Write-Host "memory_part_number=`"$memory_part_number`""
Write-Host "memory_rank=`"$memory_rank`""
Write-Host "memory_configured_speed=`"$memory_configured_speed`""
Write-Host "memory_configured_voltage=`"$memory_configured_voltage`""

Write-Host "`n# Disk"
Write-Host "disk_serial_number=`"$disk_serial_number`""
Write-Host "disk_model=`"$disk_model`""
Write-Host "disk_firmware_version=`"$disk_firmware_version`""
Write-Host "DISK_PRODUCT_ID=`"$DISK_PRODUCT_ID`""

Write-Host "`n# Network"
Write-Host "net_mac_address=`"$net_mac_address`""

Write-Host "`n# Machine GUID"
Write-Host "machine_guid=`"$machine_guid`""

Write-Host "`n# Display"
Write-Host "display_edid_uid0=`"$display_edid_uid0`""
