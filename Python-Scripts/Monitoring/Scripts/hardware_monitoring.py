#!/usr/bin/env python3
# -*- coding: utf-8 -*-

######################################################################
# A Python script for monitoring hardware on any Linux distribution  #
# Fetches hardware information from /proc and /sys filesystems       #
# Processes the fetched data for further analysis                    #
# Author: Alexandru Filcu                                            #
# License: MIT                                                       #
# Version: 1.0.0                                                     #
######################################################################

######################
# IMPORT HANDY TOOLS #
######################

import sys
import os
import re
import json
import csv
import argparse
import glob
from datetime import datetime
from collections import OrderedDict

#############
# CONSTANTS #
#############

VERSION = "1.0.0"

# Severity levels
SEVERITY_CRITICAL = "CRITICAL"
SEVERITY_WARN = "WARN"
SEVERITY_INFO = "INFO"

# Terminal colors
COLOR_RESET = '\033[0m'
COLOR_RED = '\033[91m'
COLOR_YELLOW = '\033[93m'
COLOR_GREEN = '\033[92m'
COLOR_BLUE = '\033[94m'
COLOR_CYAN = '\033[96m'
COLOR_BOLD = '\033[1m'
COLOR_MAGENTA = '\033[95m'
COLOR_WHITE = '\033[97m'

# Verbosity levels
VERBOSITY_BASIC = 1
VERBOSITY_DETAILED = 2
VERBOSITY_FULL = 3

#####################
# UTILITY FUNCTIONS #
#####################

def clean_ansi_codes(text):
    """Remove ANSI color codes from text for accurate length calculation."""
    return re.sub(r'\033\[[0-9;]*m', '', str(text))

def colorize(text, color):
    """Apply color to text for terminal output."""
    return f"{color}{text}{COLOR_RESET}"

def read_file_safe(path):
    """Safely read file content and return as string."""
    try:
        with open(path, 'r') as f:
            return f.read().strip()
    except Exception:
        return None

def read_lines_safe(path):
    """Safely read file lines and return as list."""
    try:
        with open(path, 'r') as f:
            return [line.strip() for line in f.readlines()]
    except Exception:
        return []

def bytes_to_human(bytes_value):
    """Convert bytes to human-readable format."""
    if bytes_value == 0:
        return "0 B"
    
    for unit in ['B', 'KB', 'MB', 'GB', 'TB', 'PB']:
        if bytes_value < 1024.0:
            return f"{bytes_value:.2f} {unit}"
        bytes_value /= 1024.0
    return f"{bytes_value:.2f} EB"

def get_severity_color(severity):
    """Get color for severity level."""
    severity_colors = {
        SEVERITY_CRITICAL: COLOR_RED,
        SEVERITY_WARN: COLOR_YELLOW,
        SEVERITY_INFO: COLOR_GREEN
    }
    return severity_colors.get(severity, COLOR_GREEN)

def truncate_text(text, max_length):
    """Truncate text to maximum length and add ellipsis if needed."""
    text_clean = clean_ansi_codes(str(text))
    if len(text_clean) <= max_length:
        return str(text)
    return str(text)[:max_length-3] + "..."

#####################
# DISPLAY FUNCTIONS #
#####################

def print_main_header():
    """Print main header with borders."""
    title1 = "HARDWARE MONITOR - Universal Linux Hardware Information Tool"
    title2 = f"Version {VERSION}"
    width = 70
    border = '#' * width
    
    print(f"\n{COLOR_CYAN}{border}{COLOR_RESET}")
    
    # Calculate padding for title1
    padding1 = width - 2 - len(title1)
    left_pad1 = padding1 // 2
    right_pad1 = padding1 - left_pad1
    line1 = '#' + ' ' * left_pad1 + title1 + ' ' * right_pad1 + '#'
    print(f"{COLOR_CYAN}{line1}{COLOR_RESET}")
    
    # Calculate padding for title2
    padding2 = width - 2 - len(title2)
    left_pad2 = padding2 // 2
    right_pad2 = padding2 - left_pad2
    line2 = '#' + ' ' * left_pad2 + title2 + ' ' * right_pad2 + '#'
    print(f"{COLOR_CYAN}{line2}{COLOR_RESET}")
    
    print(f"{COLOR_CYAN}{border}{COLOR_RESET}")

def print_main_footer():
    """Print main footer with borders."""
    title = "Hardware monitoring completed"
    width = 70
    border = '#' * width
    
    print(f"\n{COLOR_GREEN}{border}{COLOR_RESET}")
    
    # Calculate padding for title
    padding = width - 2 - len(title)
    left_pad = padding // 2
    right_pad = padding - left_pad
    line = '#' + ' ' * left_pad + title + ' ' * right_pad + '#'
    print(f"{COLOR_GREEN}{line}{COLOR_RESET}")
    
    print(f"{COLOR_GREEN}{border}{COLOR_RESET}\n")

def print_section_header(title, color=COLOR_CYAN):
    """Print formatted section header with borders."""
    title_clean = clean_ansi_codes(title)
    width = max(60, len(title_clean) + 4)
    border = '+' + '-' * (width - 2) + '+'
    
    print(f"\n{color}{border}{COLOR_RESET}")
    print(f"{color}|{COLOR_BOLD} {title.center(width - 4)} {COLOR_RESET}{color}|{COLOR_RESET}")
    print(f"{color}{border}{COLOR_RESET}")

def print_formatted_table(headers, data, header_color=COLOR_BLUE, 
                         data_colors=None, max_col_width=50):
    """Print formatted table with headers and data."""
    if not data:
        print(colorize("No data available", COLOR_YELLOW))
        return

    # Calculate column widths
    col_widths = []
    for i, header in enumerate(headers):
        max_width = len(clean_ansi_codes(header))
        for row in data:
            if i < len(row):
                cell_clean = clean_ansi_codes(str(row[i]))
                cell_width = min(len(cell_clean), max_col_width)
                max_width = max(max_width, cell_width)
        col_widths.append(max_width + 2)

    # Create borders
    border = '+' + '+'.join(['-' * w for w in col_widths]) + '+'
    
    # Print header
    print(colorize(border, header_color))
    header_row = '|'
    for i, header in enumerate(headers):
        header_text = str(header)
        header_clean = clean_ansi_codes(header_text)
        padding = col_widths[i] - len(header_clean)
        left_pad = padding // 2
        right_pad = padding - left_pad
        centered_header = ' ' * left_pad + header_text + ' ' * right_pad
        header_row += colorize(centered_header, header_color) + '|'
    print(header_row)
    print(colorize(border, header_color))

    # Print data rows
    for row_idx, row in enumerate(data):
        row_str = '|'
        for i in range(len(headers)):
            if i < len(row):
                cell = truncate_text(row[i], max_col_width)
                cell_clean = clean_ansi_codes(cell)
                padding = col_widths[i] - len(cell_clean)
                left_pad = padding // 2
                right_pad = padding - left_pad
                
                cell_color = (data_colors[row_idx][i] 
                            if data_colors and row_idx < len(data_colors) 
                            and i < len(data_colors[row_idx]) 
                            else COLOR_WHITE)
                
                padded_cell = ' ' * left_pad + colorize(cell_clean, cell_color) + ' ' * right_pad
                row_str += padded_cell + '|'
            else:
                row_str += ' ' * col_widths[i] + '|'
        print(row_str)

    # Print closing border
    print(colorize(border, header_color))
    print()

def print_info_table(category_data, category_name, verbosity):
    """Print information in table format with status."""
    if not category_data:
        print(colorize("No data available", COLOR_YELLOW))
        return
    
    headers = ["Metric", "Value", "Status"]
    data = []
    colors = []
    
    for key, value in category_data.items():
        # Format value based on type
        if isinstance(value, list):
            if verbosity >= VERBOSITY_FULL:
                value_str = ', '.join(str(item) for item in value[:3])
                if len(value) > 3:
                    value_str += f" ... (+{len(value)-3} more)"
            else:
                value_str = f"{len(value)} items"
        elif isinstance(value, dict):
            value_str = (json.dumps(value) if verbosity >= VERBOSITY_FULL 
                        else f"{len(value)} keys")
        else:
            value_str = str(value)
        
        # Determine status and color
        status, status_color = determine_status(key, value)
        
        data.append([key, value_str, status])
        colors.append([COLOR_BLUE, COLOR_WHITE, status_color])
    
    print_formatted_table(headers, data, COLOR_CYAN, colors, max_col_width=40)

def determine_status(key, value):
    """Determine status and color based on key and value."""
    status = "OK"
    status_color = COLOR_GREEN
    value_lower = str(value).lower()
    key_lower = key.lower()
    
    # Check for usage percentage
    if "usage" in key_lower or "percentage" in key_lower:
        try:
            usage_value = float(str(value).strip('%'))
            if usage_value > 90:
                status, status_color = "CRITICAL", COLOR_RED
            elif usage_value > 80:
                status, status_color = "WARNING", COLOR_YELLOW
        except (ValueError, AttributeError):
            pass
    
    # Check for temperature
    elif "temperature" in key_lower:
        try:
            temp_value = float(str(value).strip('°C'))
            if temp_value > 80:
                status, status_color = "CRITICAL", COLOR_RED
            elif temp_value > 70:
                status, status_color = "WARNING", COLOR_YELLOW
        except (ValueError, AttributeError):
            pass
    
    # Check for error indicators
    elif ("error" in key_lower or "failed" in key_lower or 
          "critical" in value_lower):
        status, status_color = "CRITICAL", COLOR_RED
    
    elif "warning" in value_lower or "warn" in key_lower:
        status, status_color = "WARNING", COLOR_YELLOW
    
    elif "unknown" in value_lower or "n/a" in value_lower:
        status, status_color = "UNKNOWN", COLOR_YELLOW
    
    return status, status_color

########################
# HARDWARE INFORMATION #
########################

class HardwareInfo:
    """Base class for hardware information storage."""
    
    def __init__(self):
        self.data = OrderedDict()
        self.severity = SEVERITY_INFO
    
    def to_dict(self):
        """Convert to dictionary for export."""
        return {
            'category': self.__class__.__name__,
            'severity': self.severity,
            'data': self.data
        }

#####################
# HARDWARE CRAWLERS #
#####################

def collect_os_information(verbosity):
    """Collect operating system and kernel information."""
    info = HardwareInfo()
    
    # Basic OS information
    uname = os.uname()
    info.data['Hostname'] = uname.nodename
    info.data['Kernel Name'] = uname.sysname
    info.data['Kernel Release'] = uname.release
    info.data['Kernel Version'] = uname.version
    info.data['Architecture'] = uname.machine
    
    # Distribution information
    if os.path.exists('/etc/os-release'):
        distro_info = {}
        for line in read_lines_safe('/etc/os-release'):
            if '=' in line:
                key, value = line.split('=', 1)
                distro_info[key] = value.strip('"')
        
        info.data['Distribution'] = distro_info.get('PRETTY_NAME', 
                                                     distro_info.get('NAME', 'Unknown'))
        info.data['Distribution ID'] = distro_info.get('ID', 'unknown')
        info.data['Distribution Version'] = distro_info.get('VERSION_ID', 'N/A')
    
    if verbosity >= VERBOSITY_DETAILED:
        add_os_detailed_info(info)
    
    if verbosity >= VERBOSITY_FULL:
        add_os_full_info(info)
    
    return info

def add_os_detailed_info(info):
    """Add detailed OS information."""
    # Uptime
    uptime_data = read_file_safe('/proc/uptime')
    if uptime_data:
        uptime_seconds = float(uptime_data.split()[0])
        days = int(uptime_seconds // 86400)
        hours = int((uptime_seconds % 86400) // 3600)
        minutes = int((uptime_seconds % 3600) // 60)
        info.data['Uptime'] = f"{days}d {hours}h {minutes}m"
    
    # Load average
    load_avg = read_file_safe('/proc/loadavg')
    if load_avg:
        loads = load_avg.split()[:3]
        info.data['Load Average'] = f"{loads[0]} (1min) / {loads[1]} (5min) / {loads[2]} (15min)"

def add_os_full_info(info):
    """Add full OS information."""
    # Kernel command line
    cmdline = read_file_safe('/proc/cmdline')
    if cmdline:
        info.data['Kernel Parameters'] = (cmdline[:100] + "..." 
                                          if len(cmdline) > 100 else cmdline)
    
    # Kernel modules count
    if os.path.exists('/proc/modules'):
        modules = read_lines_safe('/proc/modules')
        info.data['Loaded Modules'] = len(modules)

def collect_cpu_information(verbosity):
    """Collect CPU hardware information."""
    info = HardwareInfo()
    
    cpuinfo = read_lines_safe('/proc/cpuinfo')
    if not cpuinfo:
        info.severity = SEVERITY_CRITICAL
        info.data['Status'] = "Unable to read CPU information"
        return info
    
    cpu_data = parse_cpuinfo(cpuinfo)
    
    # Basic CPU information
    info.data['Model'] = cpu_data.get('model_name', 'Unknown')
    info.data['Vendor'] = cpu_data.get('vendor_id', 'Unknown')
    info.data['Logical Processors'] = cpu_data['processor_count']
    info.data['Physical CPUs'] = len(cpu_data['physical_ids']) or 1
    info.data['Cores per CPU'] = len(cpu_data['core_ids']) or cpu_data['processor_count']
    
    if verbosity >= VERBOSITY_DETAILED:
        add_cpu_detailed_info(info, cpu_data)
    
    if verbosity >= VERBOSITY_FULL:
        add_cpu_full_info(info, cpu_data)
    
    return info

def parse_cpuinfo(cpuinfo):
    """Parse /proc/cpuinfo data."""
    cpu_data = {
        'processor_count': 0,
        'physical_ids': set(),
        'core_ids': set()
    }
    
    for line in cpuinfo:
        if ':' not in line:
            continue
        key, value = line.split(':', 1)
        key = key.strip()
        value = value.strip()
        
        if key == 'processor':
            cpu_data['processor_count'] += 1
        elif key == 'model name' and 'model_name' not in cpu_data:
            cpu_data['model_name'] = value
        elif key == 'vendor_id' and 'vendor_id' not in cpu_data:
            cpu_data['vendor_id'] = value
        elif key == 'cpu MHz' and 'cpu_mhz' not in cpu_data:
            cpu_data['cpu_mhz'] = value
        elif key == 'cache size' and 'cache_size' not in cpu_data:
            cpu_data['cache_size'] = value
        elif key == 'physical id':
            cpu_data['physical_ids'].add(value)
        elif key == 'core id':
            cpu_data['core_ids'].add(value)
        elif key == 'flags' and 'flags' not in cpu_data:
            cpu_data['flags'] = value.split()
        elif key == 'bogomips' and 'bogomips' not in cpu_data:
            cpu_data['bogomips'] = value
    
    return cpu_data

def add_cpu_detailed_info(info, cpu_data):
    """Add detailed CPU information."""
    info.data['Current Frequency'] = f"{cpu_data.get('cpu_mhz', 'N/A')} MHz"
    info.data['Cache Size'] = cpu_data.get('cache_size', 'N/A')
    info.data['BogoMIPS'] = cpu_data.get('bogomips', 'N/A')

def add_cpu_full_info(info, cpu_data):
    """Add full CPU information."""
    # CPU frequency scaling
    freq_paths = glob.glob('/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq')
    if freq_paths:
        frequencies = []
        for path in freq_paths[:4]:
            freq = read_file_safe(path)
            if freq:
                frequencies.append(int(freq) / 1000)
        
        if frequencies:
            freq_display = ', '.join(f'{f:.0f}MHz' for f in frequencies[:3])
            if len(frequencies) > 3:
                freq_display += "..."
            info.data['Core Frequencies'] = f"{len(frequencies)} cores: {freq_display}"
    
    # CPU features/flags
    if 'flags' in cpu_data and cpu_data['flags']:
        important_flags = [f for f in cpu_data['flags'] 
                          if f in ['vmx', 'svm', 'aes', 'avx', 'avx2', 
                                  'sse4_1', 'sse4_2', 'lm']]
        if important_flags:
            flags_str = ', '.join(important_flags[:5])
            if len(important_flags) > 5:
                flags_str += "..."
            info.data['Notable Features'] = flags_str

def collect_memory_information(verbosity):
    """Collect RAM and memory hardware information."""
    info = HardwareInfo()
    
    meminfo = read_lines_safe('/proc/meminfo')
    if not meminfo:
        info.severity = SEVERITY_CRITICAL
        info.data['Status'] = "Unable to read memory information"
        return info
    
    mem_data = parse_meminfo(meminfo)
    
    # Calculate memory usage
    total_mem = mem_data.get('MemTotal', 0)
    available_mem = mem_data.get('MemAvailable', mem_data.get('MemFree', 0))
    used_mem = total_mem - available_mem
    
    info.data['Total Memory'] = bytes_to_human(total_mem)
    info.data['Available Memory'] = bytes_to_human(available_mem)
    info.data['Used Memory'] = bytes_to_human(used_mem)
    
    usage_percent = (used_mem / total_mem * 100) if total_mem > 0 else 0
    info.data['Usage Percentage'] = f"{usage_percent:.1f}%"
    
    # Set severity based on usage
    if usage_percent > 90:
        info.severity = SEVERITY_CRITICAL
    elif usage_percent > 80:
        info.severity = SEVERITY_WARN
    
    if verbosity >= VERBOSITY_DETAILED:
        add_memory_detailed_info(info, mem_data)
    
    if verbosity >= VERBOSITY_FULL:
        add_memory_full_info(info, mem_data)
    
    return info

def parse_meminfo(meminfo):
    """Parse /proc/meminfo data."""
    mem_data = {}
    for line in meminfo:
        if ':' in line:
            key, value = line.split(':', 1)
            value_parts = value.strip().split()
            if value_parts:
                try:
                    # Convert kB to bytes
                    mem_data[key.strip()] = int(value_parts[0]) * 1024
                except ValueError:
                    mem_data[key.strip()] = value.strip()
    return mem_data

def add_memory_detailed_info(info, mem_data):
    """Add detailed memory information."""
    swap_total = mem_data.get('SwapTotal', 0)
    swap_free = mem_data.get('SwapFree', 0)
    swap_used = swap_total - swap_free
    
    info.data['Swap Total'] = bytes_to_human(swap_total)
    info.data['Swap Used'] = bytes_to_human(swap_used)
    info.data['Swap Free'] = bytes_to_human(swap_free)
    
    if swap_total > 0:
        swap_usage = (swap_used / swap_total * 100)
        info.data['Swap Usage'] = f"{swap_usage:.1f}%"

def add_memory_full_info(info, mem_data):
    """Add full memory information."""
    info.data['Active Memory'] = bytes_to_human(mem_data.get('Active', 0))
    info.data['Inactive Memory'] = bytes_to_human(mem_data.get('Inactive', 0))
    info.data['Dirty Pages'] = bytes_to_human(mem_data.get('Dirty', 0))
    info.data['Writeback'] = bytes_to_human(mem_data.get('Writeback', 0))
    info.data['Slab'] = bytes_to_human(mem_data.get('Slab', 0))
    
    # Huge pages
    hugepages_total = mem_data.get('HugePages_Total', 0)
    if isinstance(hugepages_total, int) and hugepages_total > 0:
        info.data['HugePages Total'] = hugepages_total
        info.data['HugePages Free'] = mem_data.get('HugePages_Free', 0)

def collect_motherboard_information(verbosity):
    """Collect motherboard and system board information."""
    info = HardwareInfo()
    dmi_base = '/sys/class/dmi/id'
    
    if not os.path.exists(dmi_base):
        info.severity = SEVERITY_WARN
        info.data['Status'] = "DMI information not available"
        return info
    
    # Board information
    info.data['Board Vendor'] = read_file_safe(f'{dmi_base}/board_vendor') or 'Unknown'
    info.data['Board Name'] = read_file_safe(f'{dmi_base}/board_name') or 'Unknown'
    info.data['Board Version'] = read_file_safe(f'{dmi_base}/board_version') or 'Unknown'
    
    if verbosity >= VERBOSITY_DETAILED:
        add_motherboard_detailed_info(info, dmi_base)
    
    if verbosity >= VERBOSITY_FULL:
        add_motherboard_full_info(info, dmi_base)
    
    return info

def add_motherboard_detailed_info(info, dmi_base):
    """Add detailed motherboard information."""
    # System information
    info.data['System Vendor'] = read_file_safe(f'{dmi_base}/sys_vendor') or 'Unknown'
    info.data['System Product'] = read_file_safe(f'{dmi_base}/product_name') or 'Unknown'
    info.data['System Version'] = read_file_safe(f'{dmi_base}/product_version') or 'Unknown'
    
    # BIOS information
    info.data['BIOS Vendor'] = read_file_safe(f'{dmi_base}/bios_vendor') or 'Unknown'
    info.data['BIOS Version'] = read_file_safe(f'{dmi_base}/bios_version') or 'Unknown'
    info.data['BIOS Date'] = read_file_safe(f'{dmi_base}/bios_date') or 'Unknown'

def add_motherboard_full_info(info, dmi_base):
    """Add full motherboard information."""
    # Chassis information
    info.data['Chassis Vendor'] = read_file_safe(f'{dmi_base}/chassis_vendor') or 'Unknown'
    info.data['Chassis Type'] = read_file_safe(f'{dmi_base}/chassis_type') or 'Unknown'
    info.data['Chassis Serial'] = read_file_safe(f'{dmi_base}/chassis_serial') or 'N/A'
    
    # Product serial and UUID
    product_serial = read_file_safe(f'{dmi_base}/product_serial')
    product_uuid = read_file_safe(f'{dmi_base}/product_uuid')
    
    if product_serial:
        info.data['Product Serial'] = product_serial
    if product_uuid:
        info.data['Product UUID'] = product_uuid

def collect_storage_information(verbosity):
    """Collect storage devices information."""
    info = HardwareInfo()
    block_path = '/sys/block'
    
    if not os.path.exists(block_path):
        info.severity = SEVERITY_WARN
        info.data['Status'] = "Block device information not available"
        return info
    
    devices = []
    block_devices = os.listdir(block_path)
    
    for device in block_devices:
        # Skip loop and ram devices in basic verbosity
        if verbosity < VERBOSITY_FULL:
            if device.startswith(('loop', 'ram')):
                continue
        
        device_info = parse_block_device(device, block_path, verbosity)
        if device_info:
            devices.append(device_info)
    
    info.data['Total Block Devices'] = len(devices)
    
    # Format devices for display
    device_display = [
        f"{d['name']} ({d.get('type', 'Unknown')}) - {d.get('size', 'Unknown size')}"
        for d in devices
    ]
    
    if len(device_display) > 5 and verbosity < VERBOSITY_FULL:
        info.data['Devices'] = device_display[:5] + [f"... (+{len(device_display) - 5} more)"]
    else:
        info.data['Devices'] = device_display
    
    return info

def parse_block_device(device, block_path, verbosity):
    """Parse information for a single block device."""
    device_path = os.path.join(block_path, device)
    device_info = {'name': device}
    
    # Size
    size_sectors = read_file_safe(f'{device_path}/size')
    if size_sectors:
        try:
            size_bytes = int(size_sectors) * 512
            device_info['size'] = bytes_to_human(size_bytes)
        except ValueError:
            pass
    
    # Device type
    rotational = read_file_safe(f'{device_path}/queue/rotational')
    device_info['type'] = "SSD" if rotational == '0' else "HDD"
    
    if verbosity >= VERBOSITY_DETAILED:
        model = read_file_safe(f'{device_path}/device/model')
        vendor = read_file_safe(f'{device_path}/device/vendor')
        if model:
            device_info['model'] = model.strip()
        if vendor:
            device_info['vendor'] = vendor.strip()
    
    return device_info

def collect_graphics_information(verbosity):
    """Collect graphics/GPU hardware information."""
    info = HardwareInfo()
    gpus = []
    
    drm_path = '/sys/class/drm'
    if os.path.exists(drm_path):
        drm_cards = [d for d in os.listdir(drm_path) 
                     if d.startswith('card') and '-' not in d]
        
        for card in drm_cards:
            gpu_info = parse_gpu_device(card, drm_path, verbosity)
            if gpu_info:
                gpus.append(gpu_info)
    
    info.data['Graphics Devices'] = len(gpus)
    
    if gpus:
        gpu_display = [f"{gpu.get('vendor', 'Unknown')} ({gpu.get('driver', 'N/A')})" 
                      for gpu in gpus]
        info.data['GPUs'] = gpu_display
    else:
        info.data['GPUs'] = ["No discrete GPU detected"]
    
    return info

def parse_gpu_device(card, drm_path, verbosity):
    """Parse information for a single GPU device."""
    card_path = os.path.join(drm_path, card)
    device_path = f'{card_path}/device'
    
    if not os.path.exists(device_path):
        return None
    
    gpu_info = {'device': card}
    
    # Vendor ID
    vendor_id = read_file_safe(f'{device_path}/vendor')
    if vendor_id:
        gpu_info['vendor'] = get_gpu_vendor_name(vendor_id)
    
    if verbosity >= VERBOSITY_DETAILED:
        # Driver
        driver_path = f'{device_path}/driver'
        if os.path.islink(driver_path):
            driver = os.path.basename(os.readlink(driver_path))
            gpu_info['driver'] = driver
    
    return gpu_info

def get_gpu_vendor_name(vendor_id):
    """Get GPU vendor name from vendor ID."""
    vendor_map = {
        '0x8086': 'Intel',
        '0x10de': 'NVIDIA',
        '0x1002': 'AMD',
        '0x1af4': 'Virtio',
        '0x1234': 'QEMU',
    }
    return vendor_map.get(vendor_id, vendor_id)


####################
# EXPORT FUNCTIONS #
####################

def export_to_json(data, filepath):
    """Export collected data to JSON file."""
    try:
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"\n{colorize('[SUCCESS]', COLOR_GREEN)} Data exported to: {colorize(filepath, COLOR_CYAN)}")
    except Exception as e:
        print(f"\n{colorize('[ERROR]', COLOR_RED)} Failed to export JSON: {str(e)}")

def export_to_csv(data, filepath):
    """Export collected data to CSV file."""
    try:
        with open(filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
            writer.writerow(['Category', 'Severity', 'Key', 'Value'])
            
            for category, info in data.items():
                if isinstance(info, dict):
                    severity = info.get('severity', SEVERITY_INFO)
                    category_name = info.get('category', category)
                    
                    if 'data' in info and isinstance(info['data'], dict):
                        for key, value in info['data'].items():
                            if isinstance(value, (list, dict)):
                                value = json.dumps(value)
                            writer.writerow([category_name, severity, key, str(value)])
        
        print(f"\n{colorize('[SUCCESS]', COLOR_GREEN)} Data exported to: {colorize(filepath, COLOR_CYAN)}")
    except Exception as e:
        print(f"\n{colorize('[ERROR]', COLOR_RED)} Failed to export CSV: {str(e)}")

def export_to_log(data, filepath):
    """Export collected data to LOG file."""
    try:
        with open(filepath, 'w') as f:
            f.write("=" * 70 + "\n")
            f.write("HARDWARE MONITOR - SYSTEM REPORT\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("=" * 70 + "\n\n")
            
            for category, info in data.items():
                if isinstance(info, dict):
                    severity = info.get('severity', SEVERITY_INFO)
                    category_name = info.get('category', category)
                    
                    f.write(f"\n[{severity}] {category_name}\n")
                    f.write("-" * 70 + "\n")
                    
                    if 'data' in info and isinstance(info['data'], dict):
                        for key, value in info['data'].items():
                            if isinstance(value, (list, dict)):
                                f.write(f"{key}:\n")
                                f.write(f"  {json.dumps(value, indent=2)}\n")
                            else:
                                f.write(f"{key}: {value}\n")
        
        print(f"\n{colorize('[SUCCESS]', COLOR_GREEN)} Data exported to: {colorize(filepath, COLOR_CYAN)}")
    except Exception as e:
        print(f"\n{colorize('[ERROR]', COLOR_RED)} Failed to export LOG: {str(e)}")


##################
# MAIN EXECUTION #
##################

def create_argument_parser():
    """Create and configure argument parser."""
    parser = argparse.ArgumentParser(
        description='hardware_monitor.py - A Linux Hardware Monitoring Tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --v
  %(prog)s --vv --export-format=json
  %(prog)s --vvv --export-format=log --path=/tmp/reports
  %(prog)s --vv --export-format=csv --path=./output
        """)
    
    parser.add_argument('--v', action='store_const', const=VERBOSITY_BASIC, 
                       dest='verbosity',
                       help='Basic verbosity (essential hardware info)')
    parser.add_argument('--vv', action='store_const', const=VERBOSITY_DETAILED, 
                       dest='verbosity',
                       help='Detailed verbosity (includes additional hardware details)')
    parser.add_argument('--vvv', action='store_const', const=VERBOSITY_FULL, 
                       dest='verbosity',
                       help='Full verbosity (comprehensive hardware analysis)')
    parser.add_argument('--export-format', choices=['log', 'json', 'csv'],
                       help='Export format (log/json/csv)')
    parser.add_argument('--path', default='.',
                       help='Output directory for exported files (default: current directory)')
    parser.add_argument('--version', action='version', version=f'%(prog)s {VERSION}')
    
    return parser

def collect_all_hardware_info(verbosity):
    """Collect all hardware information."""
    collected_data = OrderedDict()
    
    sections = [
        ("SYSTEM OVERVIEW", 'os', collect_os_information),
        ("PROCESSOR INFORMATION", 'cpu', collect_cpu_information),
        ("MEMORY INFORMATION", 'memory', collect_memory_information),
        ("MOTHERBOARD INFORMATION", 'motherboard', collect_motherboard_information),
        ("STORAGE INFORMATION", 'storage', collect_storage_information),
        ("GRAPHICS INFORMATION", 'graphics', collect_graphics_information),
    ]
    
    for section_title, key, collector_func in sections:
        print_section_header(section_title)
        collected_data[key] = collector_func(verbosity).to_dict()
        print_info_table(collected_data[key]['data'], key.upper(), verbosity)
    
    return collected_data

def print_summary(collected_data):
    """Print collection summary."""
    print_section_header("COLLECTION SUMMARY", COLOR_GREEN)
    
    critical_count = sum(1 for v in collected_data.values() 
                        if v.get('severity') == SEVERITY_CRITICAL)
    warn_count = sum(1 for v in collected_data.values() 
                    if v.get('severity') == SEVERITY_WARN)
    
    summary_data = [
        ["Categories Collected", str(len(collected_data)), "OK"],
        ["Critical Issues", str(critical_count), 
         "CRITICAL" if critical_count > 0 else "OK"],
        ["Warnings", str(warn_count), 
         "WARNING" if warn_count > 0 else "OK"],
        ["Overall Status", 
         "HEALTHY" if critical_count == 0 else "ISSUES DETECTED",
         "OK" if critical_count == 0 else "WARNING"]
    ]
    
    summary_colors = []
    for row in summary_data:
        colors = [COLOR_BLUE, COLOR_WHITE]
        if "CRITICAL" in row[2]:
            colors.append(COLOR_RED)
        elif "WARNING" in row[2]:
            colors.append(COLOR_YELLOW)
        else:
            colors.append(COLOR_GREEN)
        summary_colors.append(colors)
    
    print_formatted_table(["Metric", "Value", "Status"], summary_data, 
                         COLOR_GREEN, summary_colors, max_col_width=30)

def export_data(collected_data, export_format, output_path):
    """Export collected data to specified format."""
    # Ensure output directory exists
    if not os.path.exists(output_path):
        try:
            os.makedirs(output_path)
        except Exception as e:
            print(f"\n{colorize('[ERROR]', COLOR_RED)} Failed to create output directory: {str(e)}")
            sys.exit(1)
    
    # Generate filename
    timestamp = datetime.now().strftime('%Y_%m_%d_%H_%M_%S')
    filename = f"hardware_monitor_{timestamp}.{export_format}"
    filepath = os.path.join(output_path, filename)
    
    # Export based on format
    export_functions = {
        'json': export_to_json,
        'csv': export_to_csv,
        'log': export_to_log
    }
    
    export_func = export_functions.get(export_format)
    if export_func:
        export_func(collected_data, filepath)

def main():
    """Main execution function."""
    parser = create_argument_parser()
    args = parser.parse_args()
    
    # Set default verbosity
    verbosity = args.verbosity if args.verbosity else VERBOSITY_BASIC
    
    # Print header
    print_main_header()
    print(f"\nVerbosity Level: {colorize(['Basic', 'Detailed', 'Full'][verbosity - 1], COLOR_YELLOW)}")
    print(f"Timestamp: {colorize(datetime.now().strftime('%Y-%m-%d %H:%M:%S'), COLOR_GREEN)}\n")
    
    # Collect hardware information
    try:
        collected_data = collect_all_hardware_info(verbosity)
    except KeyboardInterrupt:
        print(f"\n\n{colorize('[WARNING]', COLOR_YELLOW)} Collection interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n{colorize('[ERROR]', COLOR_RED)} Error during collection: {str(e)}")
        sys.exit(1)
    
    # Print summary
    print_summary(collected_data)
    
    # Export if requested
    if args.export_format:
        export_data(collected_data, args.export_format, args.path)
    
    # Print footer
    print_main_footer()

if __name__ == '__main__':
    main()