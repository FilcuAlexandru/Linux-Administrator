#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Linux System Health Check
Universal script for any Linux distribution
Run levels: light | balanced | deep
No external dependencies - pure Python stdlib + /proc filesystem
"""

import sys
import os
import time
import argparse
import pwd
from collections import Counter
import re


# ============================================================================
# COLOR DEFINITIONS
# ============================================================================

class Color:
    """ANSI color codes for terminal output"""
    RED = '\033[91m'
    YELLOW = '\033[93m'
    GREEN = '\033[92m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def clean_ansi_codes(text):
    """Remove ANSI color codes from text for accurate length calculation"""
    return re.sub(r'\033\[[0-9;]*m', '', str(text))


def colorize(text, color):
    """Apply ANSI color to text"""
    return f"{color}{text}{Color.RESET}"


def read_file_safe(path):
    """Safely read file content"""
    try:
        with open(path, 'r') as f:
            return f.read().strip()
    except:
        return None


def read_lines_safe(path):
    """Safely read file lines"""
    try:
        with open(path, 'r') as f:
            return f.readlines()
    except:
        return []


def bytes_to_human_readable(bytes_value):
    """Convert bytes to human readable format"""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if bytes_value < 1024.0:
            return f"{bytes_value:.2f} {unit}"
        bytes_value /= 1024.0
    return f"{bytes_value:.2f} PB"


# ============================================================================
# DISPLAY FUNCTIONS
# ============================================================================

def print_section_header(title):
    """Display formatted section header with table-style borders"""
    title_clean = clean_ansi_codes(title)
    width = max(50, len(title_clean) + 4)
    border = '+' + '-' * (width - 2) + '+'
    
    print(f"\n{Color.BLUE}{border}{Color.RESET}")
    print(f"{Color.BLUE}|{Color.BOLD} {title.center(width - 4)} {Color.RESET}{Color.BLUE}|{Color.RESET}")
    print(f"{Color.BLUE}{border}{Color.RESET}")


def print_formatted_table(headers, data, header_color=Color.BLUE, data_colors=None):
    """Print formatted table with headers and data"""
    if not data:
        print(colorize("No data available", Color.YELLOW))
        return

    # Calculate maximum width for each column based on clean text
    col_widths = []
    for i, header in enumerate(headers):
        max_width = len(clean_ansi_codes(header))
        for row in data:
            if i < len(row):
                cell_clean = clean_ansi_codes(str(row[i]))
                max_width = max(max_width, len(cell_clean))
        col_widths.append(max_width)

    # Create table border
    border = '+' + '+'.join(['-' * (w + 2) for w in col_widths]) + '+'
    print(colorize(border, header_color))

    # Print header row with centered text
    header_row = '|'
    for i, header in enumerate(headers):
        header_text = str(header)
        header_clean = clean_ansi_codes(header_text)
        padding = col_widths[i] - len(header_clean)
        left_pad = padding // 2
        right_pad = padding - left_pad
        centered_header = ' ' * left_pad + header_text + ' ' * right_pad
        header_row += ' ' + colorize(centered_header, header_color) + ' |'
    print(header_row)
    print(colorize(border, header_color))

    # Print data rows with centered text
    for row_idx, row in enumerate(data):
        row_str = '|'
        for i in range(len(headers)):
            if i < len(row):
                cell = str(row[i])
                cell_clean = clean_ansi_codes(cell)
                
                # Truncate if too long
                if len(cell_clean) > col_widths[i]:
                    cell_clean = cell_clean[:col_widths[i] - 3] + '...'
                
                # Calculate padding for centering
                padding = col_widths[i] - len(cell_clean)
                left_pad = padding // 2
                right_pad = padding - left_pad
                
                # Get color for this cell
                cell_color = data_colors[row_idx][i] if data_colors and row_idx < len(data_colors) and i < len(data_colors[row_idx]) else Color.WHITE
                
                # Build centered cell with color
                centered_cell = ' ' * left_pad + colorize(cell_clean, cell_color) + ' ' * right_pad
                row_str += ' ' + centered_cell + ' |'
            else:
                # Empty cell
                row_str += ' ' + ' ' * col_widths[i] + ' |'
        print(row_str)

    # Print closing border
    print(colorize(border, header_color))
    print()  # Add blank line after table


# ============================================================================
# SYSTEM INFORMATION FUNCTIONS
# ============================================================================

def get_system_uptime():
    """Calculate system uptime"""
    uptime_seconds = float(read_file_safe('/proc/uptime').split()[0])
    days = int(uptime_seconds // 86400)
    hours = int((uptime_seconds % 86400) // 3600)
    minutes = int((uptime_seconds % 3600) // 60)
    return f"{days}d {hours}h {minutes}m"


def get_distribution_name():
    """Get Linux distribution name"""
    distro = "Unknown Linux"
    if os.path.exists('/etc/os-release'):
        for line in read_lines_safe('/etc/os-release'):
            if line.startswith('PRETTY_NAME='):
                distro = line.split('=')[1].strip().strip('"')
                break
            elif line.startswith('NAME='):
                distro = line.split('=')[1].strip().strip('"')
    return distro


def count_processes_by_state():
    """Count processes by their state"""
    running = sleeping = zombie = 0
    for pid in os.listdir('/proc'):
        if pid.isdigit():
            status = read_file_safe(f'/proc/{pid}/stat')
            if status:
                state = status.split()[2]
                if state == 'R':
                    running += 1
                elif state == 'S':
                    sleeping += 1
                elif state == 'Z':
                    zombie += 1
    return running, sleeping, zombie


# ============================================================================
# CHECK FUNCTIONS
# ============================================================================

def check_operating_system(level):
    """Display OS information"""
    print_section_header("OPERATING SYSTEM")
    
    data = [
        ["Distribution", get_distribution_name()],
        ["Hostname", os.uname().nodename],
        ["Kernel", os.uname().release],
        ["Architecture", os.uname().machine],
        ["Uptime", get_system_uptime()]
    ]
    colors = [
        [Color.BLUE, Color.WHITE],
        [Color.BLUE, Color.WHITE],
        [Color.BLUE, Color.WHITE],
        [Color.BLUE, Color.WHITE],
        [Color.BLUE, Color.GREEN]
    ]

    if level in ['balanced', 'deep']:
        load = read_file_safe('/proc/loadavg').split()[:3]
        load_str = f"{load[0]} / {load[1]} / {load[2]}"
        data.append(["Load Average (1/5/15 min)", load_str])
        colors.append([Color.BLUE, Color.WHITE])

    if level == 'deep':
        running, sleeping, zombie = count_processes_by_state()
        status_color = Color.RED if zombie > 0 else Color.GREEN
        data.append(["Processes (Run/Sleep/Zombie)", f"{running} / {sleeping} / {zombie}"])
        colors.append([Color.BLUE, status_color])

        from datetime import datetime
        boot_dt = datetime.fromtimestamp(time.time() - float(read_file_safe('/proc/uptime').split()[0]))
        data.append(["Boot Time", boot_dt.strftime('%Y-%m-%d %H:%M:%S')])
        colors.append([Color.BLUE, Color.WHITE])

    print_formatted_table(["Metric", "Value"], data, header_color=Color.BLUE, data_colors=colors)


def get_cpu_info():
    """Extract CPU information from /proc/cpuinfo"""
    cpuinfo = {}
    cpu_count = 0
    
    for line in read_lines_safe('/proc/cpuinfo'):
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip()
            
            if key == 'processor':
                cpu_count += 1
            elif key == 'model name' and 'model name' not in cpuinfo:
                cpuinfo['model name'] = value
            elif key == 'cpu MHz' and 'cpu MHz' not in cpuinfo:
                cpuinfo['cpu MHz'] = value
            elif key == 'physical id':
                cpuinfo['physical_cores'] = cpuinfo.get('physical_cores', set())
                cpuinfo['physical_cores'].add(value)
    
    physical = len(cpuinfo.get('physical_cores', {1}))
    model = cpuinfo.get('model name', 'Unknown')
    frequency = cpuinfo.get('cpu MHz', 'N/A')
    
    return model, physical, cpu_count, frequency


def calculate_cpu_usage():
    """Calculate CPU usage per core"""
    stat1 = read_lines_safe('/proc/stat')
    time.sleep(0.5)
    stat2 = read_lines_safe('/proc/stat')
    
    core_usage = []
    for line1, line2 in zip(stat1, stat2):
        if line1.startswith('cpu') and line1[3:4].isdigit():
            vals1 = [int(x) for x in line1.split()[1:]]
            vals2 = [int(x) for x in line2.split()[1:]]
            
            total_diff = sum(vals2) - sum(vals1)
            idle_diff = vals2[3] - vals1[3]
            
            if total_diff > 0:
                usage = 100 * (total_diff - idle_diff) / total_diff
                core_usage.append(usage)
    
    return core_usage


def get_cpu_temperature():
    """Get CPU temperature if available"""
    for root, dirs, files in os.walk('/sys/class/thermal'):
        if 'temp' in files:
            temp = read_file_safe(os.path.join(root, 'temp'))
            if temp and temp.isdigit():
                return int(temp) / 1000
    return None


def check_cpu(level):
    """Display CPU metrics"""
    print_section_header("CPU")
    
    model, physical, logical, frequency = get_cpu_info()
    
    data = [
        ["Model", model],
        ["Physical Cores", str(physical)],
        ["Logical Cores", str(logical)]
    ]
    colors = [
        [Color.BLUE, Color.WHITE],
        [Color.BLUE, Color.WHITE],
        [Color.BLUE, Color.WHITE]
    ]

    if level in ['balanced', 'deep']:
        data.append(["Current Frequency", f"{frequency} MHz" if frequency != 'N/A' else frequency])
        colors.append([Color.BLUE, Color.WHITE])
        
        core_usage = calculate_cpu_usage()
        limit = 8 if level == 'balanced' else len(core_usage)
        
        for i, usage in enumerate(core_usage[:limit]):
            status = Color.RED if usage > 80 else Color.YELLOW if usage > 60 else Color.GREEN
            data.append([f"Core {i} Usage", f"{usage:.1f}%"])
            colors.append([Color.BLUE, status])

    if level == 'deep':
        for line in read_lines_safe('/proc/stat'):
            if line.startswith('ctxt'):
                ctxt = int(line.split()[1])
                data.append(["Context Switches", f"{ctxt:,}"])
                colors.append([Color.BLUE, Color.WHITE])
            elif line.startswith('intr'):
                intr = int(line.split()[1])
                data.append(["Interrupts", f"{intr:,}"])
                colors.append([Color.BLUE, Color.WHITE])
        
        temp = get_cpu_temperature()
        if temp:
            status = Color.RED if temp > 80 else Color.YELLOW if temp > 70 else Color.GREEN
            data.append(["Temperature", f"{temp:.1f}°C"])
            colors.append([Color.BLUE, status])
        else:
            data.append(["Temperature", "N/A"])
            colors.append([Color.BLUE, Color.WHITE])

    print_formatted_table(["Metric", "Value"], data, header_color=Color.BLUE, data_colors=colors)


def get_memory_info():
    """Get memory information from /proc/meminfo"""
    mem = {}
    for line in read_lines_safe('/proc/meminfo'):
        if ':' in line:
            key, value = line.split(':', 1)
            mem[key.strip()] = int(value.strip().split()[0]) * 1024
    return mem


def check_memory(level):
    """Display memory metrics"""
    print_section_header("MEMORY")
    
    mem = get_memory_info()
    
    total = mem.get('MemTotal', 0)
    free = mem.get('MemFree', 0)
    available = mem.get('MemAvailable', free)
    used = total - available
    used_pct = (used / total * 100) if total > 0 else 0
    status = Color.RED if used_pct > 90 else Color.YELLOW if used_pct > 80 else Color.GREEN

    data = [
        ["Total", bytes_to_human_readable(total)],
        ["Used", bytes_to_human_readable(used)],
        ["Available", bytes_to_human_readable(available)],
        ["Usage", f"{used_pct:.1f}%"]
    ]
    colors = [
        [Color.BLUE, Color.WHITE],
        [Color.BLUE, status],
        [Color.BLUE, Color.GREEN],
        [Color.BLUE, status]
    ]

    if level in ['balanced', 'deep']:
        swap_total = mem.get('SwapTotal', 0)
        swap_free = mem.get('SwapFree', 0)
        swap_used = swap_total - swap_free
        swap_pct = (swap_used / swap_total * 100) if swap_total > 0 else 0
        swap_status = Color.RED if swap_pct > 80 else Color.YELLOW if swap_pct > 50 else Color.GREEN

        data.extend([
            ["Swap Total", bytes_to_human_readable(swap_total)],
            ["Swap Used", bytes_to_human_readable(swap_used)],
            ["Swap Usage", f"{swap_pct:.1f}%"],
            ["Buffers", bytes_to_human_readable(mem.get('Buffers', 0))],
            ["Cached", bytes_to_human_readable(mem.get('Cached', 0))]
        ])
        colors.extend([
            [Color.BLUE, Color.WHITE],
            [Color.BLUE, swap_status],
            [Color.BLUE, swap_status],
            [Color.BLUE, Color.WHITE],
            [Color.BLUE, Color.WHITE]
        ])

    if level == 'deep':
        data.extend([
            ["Dirty Pages", bytes_to_human_readable(mem.get('Dirty', 0))],
            ["Writeback", bytes_to_human_readable(mem.get('Writeback', 0))],
            ["Slab", bytes_to_human_readable(mem.get('Slab', 0))]
        ])
        colors.extend([[Color.BLUE, Color.WHITE] for _ in range(3)])

        if mem.get('HugePages_Total', 0) > 0:
            huge_total = mem.get('HugePages_Total', 0)
            huge_free = mem.get('HugePages_Free', 0)
            data.append(["Huge Pages (Total/Free)", f"{huge_total} / {huge_free}"])
            colors.append([Color.BLUE, Color.WHITE])

    print_formatted_table(["Metric", "Value"], data, header_color=Color.BLUE, data_colors=colors)


def get_mounted_filesystems():
    """Get list of mounted filesystems"""
    mounts = {}
    excluded_fstypes = ['proc', 'sysfs', 'devpts', 'tmpfs', 'devtmpfs', 'cgroup',
                       'cgroup2', 'pstore', 'bpf', 'tracefs', 'debugfs', 'securityfs',
                       'fusectl', 'configfs', 'mqueue', 'hugetlbfs']
    
    for line in read_lines_safe('/proc/mounts'):
        parts = line.split()
        if len(parts) >= 4:
            device, mount, fstype = parts[0], parts[1], parts[2]
            if fstype in excluded_fstypes:
                continue
            if mount.startswith('/sys') or mount.startswith('/proc'):
                continue
            mounts[mount] = {'device': device, 'fstype': fstype}
    
    return mounts


def get_disk_usage(mount):
    """Get disk usage for a mount point"""
    try:
        stat = os.statvfs(mount)
        total = stat.f_blocks * stat.f_frsize
        free = stat.f_bfree * stat.f_frsize
        available = stat.f_bavail * stat.f_frsize
        used = total - free
        used_pct = (used / total * 100) if total > 0 else 0
        
        return {
            'total': total,
            'used': used,
            'available': available,
            'used_pct': used_pct
        }
    except:
        return None


def get_disk_io_stats():
    """Get disk I/O statistics"""
    io_data = {}
    for line in read_lines_safe('/proc/diskstats'):
        parts = line.split()
        if len(parts) >= 14:
            dev = parts[2]
            if dev[-1].isdigit() and len(dev) > 3 and dev[-2].isdigit():
                continue
            reads = int(parts[5]) * 512
            writes = int(parts[9]) * 512
            io_data[dev] = {'reads': reads, 'writes': writes}
    return io_data


def check_storage(level):
    """Display storage metrics"""
    print_section_header("STORAGE")
    
    mounts = get_mounted_filesystems()
    disk_data = []
    
    for mount, info in sorted(mounts.items()):
        usage = get_disk_usage(mount)
        if usage and usage['total'] >= 1024 * 1024:
            disk_data.append({
                'mount': mount,
                'device': info['device'],
                'fstype': info['fstype'],
                **usage
            })
    
    disk_data.sort(key=lambda x: x['used_pct'], reverse=True)
    limit = 3 if level == 'light' else len(disk_data)

    data = []
    colors = []
    for disk in disk_data[:limit]:
        status = Color.RED if disk['used_pct'] > 90 else Color.YELLOW if disk['used_pct'] > 80 else Color.GREEN
        data.extend([
            ["Mount Point", disk['mount']],
            ["Device", disk['device']],
            ["Filesystem", disk['fstype']],
            ["Total", bytes_to_human_readable(disk['total'])],
            ["Used", bytes_to_human_readable(disk['used'])],
            ["Available", bytes_to_human_readable(disk['available'])],
            ["Usage", f"{disk['used_pct']:.1f}%"]
        ])
        colors.extend([
            [Color.BLUE, Color.WHITE],
            [Color.BLUE, Color.WHITE],
            [Color.BLUE, Color.WHITE],
            [Color.BLUE, Color.WHITE],
            [Color.BLUE, status],
            [Color.BLUE, Color.GREEN],
            [Color.BLUE, status]
        ])
        if disk != disk_data[:limit][-1]:
            data.append(["", ""])
            colors.append([Color.BLUE, Color.WHITE])

    if level in ['balanced', 'deep']:
        io_data = get_disk_io_stats()
        disk_limit = 5 if level == 'balanced' else 10
        
        for dev in sorted(io_data.keys())[:disk_limit]:
            if io_data[dev]['reads'] > 0 or io_data[dev]['writes'] > 0:
                io_str = f"{bytes_to_human_readable(io_data[dev]['reads'])} / {bytes_to_human_readable(io_data[dev]['writes'])}"
                data.append([f"{dev} (Read/Write)", io_str])
                colors.append([Color.BLUE, Color.WHITE])

    print_formatted_table(["Metric", "Value"], data, header_color=Color.BLUE, data_colors=colors)


def get_process_list():
    """Get list of all processes"""
    processes = []
    for pid in os.listdir('/proc'):
        if not pid.isdigit():
            continue

        try:
            stat = read_file_safe(f'/proc/{pid}/stat')
            if not stat:
                continue

            parts = stat.split(')')
            if len(parts) < 2:
                continue

            stats = parts[1].strip().split()
            if len(stats) < 20:
                continue

            comm = stat.split('(')[1].split(')')[0]
            utime = int(stats[11])
            stime = int(stats[12])
            cpu_time = utime + stime
            rss_bytes = int(stats[21]) * 4096
            state = stats[0]

            processes.append({
                'pid': pid,
                'comm': comm,
                'state': state,
                'cpu_time': cpu_time,
                'rss': rss_bytes
            })
        except:
            continue
    
    return processes


def check_processes(level):
    """Display process information"""
    print_section_header("PROCESSES")
    
    processes = get_process_list()
    processes.sort(key=lambda x: x['cpu_time'], reverse=True)
    limit = 5 if level == 'light' else 10 if level == 'balanced' else 20

    headers = ["PID", "ST", "CPU TIME", "MEMORY", "COMMAND"]
    data = []
    colors = []
    
    for proc in processes[:limit]:
        state_color = Color.RED if proc['state'] == 'Z' else Color.GREEN if proc['state'] == 'R' else Color.WHITE
        data.append([proc['pid'], proc['state'], str(proc['cpu_time']), bytes_to_human_readable(proc['rss']), proc['comm']])
        colors.append([Color.WHITE, state_color, Color.WHITE, Color.WHITE, Color.WHITE])

    print_formatted_table(headers, data, header_color=Color.BLUE, data_colors=colors)

    if level in ['balanced', 'deep']:
        print_section_header("Top Processes by Memory")
        processes.sort(key=lambda x: x['rss'], reverse=True)
        data = []
        colors = []
        for proc in processes[:limit]:
            state_color = Color.RED if proc['state'] == 'Z' else Color.GREEN if proc['state'] == 'R' else Color.WHITE
            data.append([proc['pid'], proc['state'], str(proc['cpu_time']), bytes_to_human_readable(proc['rss']), proc['comm']])
            colors.append([Color.WHITE, state_color, Color.WHITE, Color.WHITE, Color.WHITE])
        print_formatted_table(headers, data, header_color=Color.BLUE, data_colors=colors)

    if level == 'deep' and any(p['state'] == 'Z' for p in processes):
        print_section_header("Zombie Processes")
        zombies = [p for p in processes if p['state'] == 'Z'][:5]
        data = [[p['pid'], p['comm']] for p in zombies]
        colors = [[Color.WHITE, Color.RED] for _ in data]
        print_formatted_table(["PID", "COMMAND"], data, header_color=Color.BLUE, data_colors=colors)


def get_user_statistics():
    """Get user statistics"""
    all_users = [u for u in pwd.getpwall() if u.pw_uid >= 1000 and 
                 u.pw_shell != '/usr/sbin/nologin' and u.pw_shell != '/bin/false']
    
    active_uids = set()
    proc_count_by_uid = Counter()
    
    for pid_dir in os.listdir('/proc'):
        if pid_dir.isdigit():
            status_path = f'/proc/{pid_dir}/status'
            status = read_file_safe(status_path)
            if status:
                try:
                    uid_line = [line for line in status.split('\n') if line.startswith('Uid:')][0]
                    uid = int(uid_line.split()[1])
                    if uid != 0:
                        active_uids.add(uid)
                        proc_count_by_uid[uid] += 1
                except (IndexError, ValueError):
                    continue
    
    return len(all_users), active_uids, proc_count_by_uid


def get_logged_in_users():
    """Get list of logged-in users"""
    logged_in = set()
    for pid_dir in os.listdir('/proc'):
        if pid_dir.isdigit():
            stat_path = f'/proc/{pid_dir}/stat'
            stat = read_file_safe(stat_path)
            if stat:
                try:
                    parts = stat.split()
                    if len(parts) > 7:
                        uid = int(parts[5])
                        tty_nr = int(parts[7])
                        if uid != 0 and tty_nr != 0:
                            user_name = pwd.getpwuid(uid)[0]
                            cmdline = read_file_safe(f'/proc/{pid_dir}/cmdline')
                            if cmdline and (cmdline.startswith('bash') or 
                                          cmdline.startswith('zsh') or 
                                          ' ' in cmdline.replace('\x00', ' ')):
                                logged_in.add(user_name)
                except (ValueError, KeyError, IndexError):
                    continue
    return logged_in


def get_user_resource_usage():
    """Calculate total CPU time and RAM usage per user"""
    user_resources = {}
    
    for pid_dir in os.listdir('/proc'):
        if not pid_dir.isdigit():
            continue
        
        try:
            # Get UID from process status
            status = read_file_safe(f'/proc/{pid_dir}/status')
            if not status:
                continue
            
            uid = None
            for line in status.split('\n'):
                if line.startswith('Uid:'):
                    uid = int(line.split()[1])
                    break
            
            if uid is None or uid == 0:
                continue
            
            # Get username
            try:
                username = pwd.getpwuid(uid).pw_name
            except KeyError:
                username = f"UID_{uid}"
            
            # Get CPU time and memory from stat
            stat = read_file_safe(f'/proc/{pid_dir}/stat')
            if not stat:
                continue
            
            parts = stat.split(')')
            if len(parts) < 2:
                continue
            
            stats = parts[1].strip().split()
            if len(stats) < 21:
                continue
            
            utime = int(stats[11])
            stime = int(stats[12])
            cpu_time = utime + stime
            rss_bytes = int(stats[21]) * 4096
            
            # Accumulate resources
            if username not in user_resources:
                user_resources[username] = {'cpu_time': 0, 'ram': 0, 'processes': 0}
            
            user_resources[username]['cpu_time'] += cpu_time
            user_resources[username]['ram'] += rss_bytes
            user_resources[username]['processes'] += 1
            
        except (ValueError, IndexError):
            continue
    
    return user_resources


def get_user_login_history():
    """Get last login information for users"""
    login_info = {}
    
    # Try to read wtmp for login history
    wtmp_path = '/var/log/wtmp'
    if os.path.exists(wtmp_path):
        try:
            import struct
            from datetime import datetime
            
            # wtmp structure (simplified, 384 bytes per record)
            with open(wtmp_path, 'rb') as f:
                while True:
                    record = f.read(384)
                    if len(record) < 384:
                        break
                    
                    try:
                        # Extract user (offset 0, 32 bytes)
                        user = record[0:32].split(b'\x00')[0].decode('utf-8', errors='ignore').strip()
                        # Extract timestamp (offset 340, 4 bytes)
                        timestamp = struct.unpack('I', record[340:344])[0]
                        
                        # Only store valid usernames (not empty, not special entries)
                        if user and timestamp > 0 and len(user) > 0 and not user.startswith('~'):
                            dt = datetime.fromtimestamp(timestamp)
                            login_info[user] = dt.strftime('%Y-%m-%d %H:%M:%S')
                    except:
                        continue
        except:
            pass
    
    # Fallback: get session start time from oldest process
    for pid_dir in os.listdir('/proc'):
        if not pid_dir.isdigit():
            continue
        
        try:
            status = read_file_safe(f'/proc/{pid_dir}/status')
            if not status:
                continue
            
            uid = None
            for line in status.split('\n'):
                if line.startswith('Uid:'):
                    uid = int(line.split()[1])
                    break
            
            if uid is None or uid == 0:
                continue
            
            try:
                username = pwd.getpwuid(uid).pw_name
            except KeyError:
                continue
            
            # Skip if username is empty
            if not username:
                continue
            
            # Get process start time
            stat = read_file_safe(f'/proc/{pid_dir}/stat')
            if stat:
                parts = stat.split(')')
                if len(parts) >= 2:
                    stats = parts[1].strip().split()
                    if len(stats) >= 20:
                        starttime = int(stats[19])
                        boot_time = time.time() - float(read_file_safe('/proc/uptime').split()[0])
                        process_start = boot_time + (starttime / os.sysconf(os.sysconf_names['SC_CLK_TCK']))
                        
                        if username not in login_info or process_start < time.mktime(time.strptime(login_info[username], '%Y-%m-%d %H:%M:%S')):
                            from datetime import datetime
                            login_info[username] = datetime.fromtimestamp(process_start).strftime('%Y-%m-%d %H:%M:%S')
        except:
            continue
    
    return login_info


def calculate_session_duration(login_time_str):
    """Calculate session duration from login time string"""
    try:
        from datetime import datetime
        login_time = datetime.strptime(login_time_str, '%Y-%m-%d %H:%M:%S')
        duration_sec = (datetime.now() - login_time).total_seconds()
        
        days = int(duration_sec // 86400)
        hours = int((duration_sec % 86400) // 3600)
        minutes = int((duration_sec % 3600) // 60)
        
        if days > 0:
            return f"{days}d {hours}h {minutes}m"
        elif hours > 0:
            return f"{hours}h {minutes}m"
        else:
            return f"{minutes}m"
    except:
        return "N/A"


def check_users(level):
    """Display user metrics (Deep level only)"""
    if level != 'deep':
        return

    print_section_header("USERS")
    
    total_users, active_uids, proc_count_by_uid = get_user_statistics()
    
    if active_uids:
        print_section_header("Top Active Users by Process Count")
        top_users = proc_count_by_uid.most_common(5)
        user_data = []
        user_colors = []
        for uid, count in top_users:
            try:
                user_info = pwd.getpwuid(uid)
                user_str = f"{user_info.pw_name} (Home: {user_info.pw_dir})"
            except KeyError:
                user_str = f"UID {uid}"
            user_data.append(["User", f"{user_str}: {count} processes"])
            user_colors.append([Color.BLUE, Color.WHITE])
        print_formatted_table(["Metric", "Value"], user_data, header_color=Color.BLUE, data_colors=user_colors)

    # Resource usage per user
    user_resources = get_user_resource_usage()
    if user_resources:
        print_section_header("Resource Usage by User")
        
        # Sort by total RAM usage
        sorted_users = sorted(user_resources.items(), key=lambda x: x[1]['ram'], reverse=True)[:5]
        
        headers = ["User", "Processes", "CPU Time", "RAM Usage"]
        resource_data = []
        resource_colors = []
        
        for username, resources in sorted_users:
            ram_status = Color.YELLOW if resources['ram'] > 1024**3 else Color.GREEN  # > 1GB
            resource_data.append([
                username,
                str(resources['processes']),
                str(resources['cpu_time']),
                bytes_to_human_readable(resources['ram'])
            ])
            resource_colors.append([Color.WHITE, Color.WHITE, Color.WHITE, ram_status])
        
        print_formatted_table(headers, resource_data, header_color=Color.BLUE, data_colors=resource_colors)

    # Login history
    login_info = get_user_login_history()
    logged_in = get_logged_in_users()
    
    if login_info or logged_in:
        print_section_header("User Login History & Sessions")
        
        # Filter valid users only (UID >= 1000, real users)
        valid_users = set()
        
        # Get all system users with UID >= 1000
        try:
            real_users = {u.pw_name for u in pwd.getpwall() if u.pw_uid >= 1000 and 
                         u.pw_shell not in ['/usr/sbin/nologin', '/bin/false', '/sbin/nologin']}
        except:
            real_users = set()
        
        # Add users from login_info if they are real users or logged in
        for user in login_info.keys():
            if user and user.strip() and (user in real_users or user in logged_in):
                valid_users.add(user)
        
        # Add logged in users
        for user in logged_in:
            if user and user.strip():
                valid_users.add(user)
        
        headers = ["User", "Last Login", "Session Duration", "Status"]
        login_data = []
        login_colors = []
        
        for username in sorted(valid_users)[:10]:
            last_login = login_info.get(username, "N/A")
            duration = calculate_session_duration(last_login) if last_login != "N/A" else "N/A"
            status = "Active" if username in logged_in else "Inactive"
            status_color = Color.GREEN if status == "Active" else Color.YELLOW
            
            login_data.append([username, last_login, duration, status])
            login_colors.append([Color.WHITE, Color.WHITE, Color.WHITE, status_color])
        
        if login_data:
            print_formatted_table(headers, login_data, header_color=Color.BLUE, data_colors=login_colors)

    # User sessions (only if multiple users logged in)
    if len(logged_in) > 1:
        print_section_header("Active User Sessions")
        session_data = []
        session_colors = []
        for user in sorted(logged_in)[:5]:
            session_count = sum(1 for pid_dir in os.listdir('/proc') if pid_dir.isdigit() and
                                read_file_safe(f'/proc/{pid_dir}/stat') and
                                int(read_file_safe(f'/proc/{pid_dir}/stat').split()[5]) == pwd.getpwnam(user).pw_uid and
                                int(read_file_safe(f'/proc/{pid_dir}/stat').split()[7]) != 0)
            session_data.append([f"Sessions for {user}", str(session_count)])
            session_colors.append([Color.BLUE, Color.WHITE])
        print_formatted_table(["Metric", "Value"], session_data, header_color=Color.BLUE, data_colors=session_colors)


# ============================================================================
# MAIN FUNCTION
# ============================================================================

def run_health_check(run_level='balanced'):
    """Run system health check with specified level"""
    print_section_header("Linux System Health Check")
    print_section_header(f"Run Level: {run_level.upper()}")

    check_operating_system(run_level)
    check_cpu(run_level)
    check_memory(run_level)
    check_storage(run_level)
    check_processes(run_level)
    check_users(run_level)
    
    print_section_header("Check Completed Successfully")
    print()


def main():
    """Main entry point for command-line execution"""
    parser = argparse.ArgumentParser(
        description='Universal Linux System Health Check',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Run Levels:
  light    - Quick overview (< 2 seconds)
  balanced - Standard check with details (2-5 seconds)
  deep     - Comprehensive analysis (5-15 seconds) - Includes users for remote monitoring

Examples:
  %(prog)s --run-level=light
  %(prog)s --run-level=balanced
  %(prog)s --run-level=deep
        """)

    parser.add_argument('--run-level',
                       choices=['light', 'balanced', 'deep'],
                       default='balanced',
                       help='Analysis depth (default: balanced)')

    args = parser.parse_args()

    try:
        run_health_check(args.run_level)
    except KeyboardInterrupt:
        print(f"\n{Color.YELLOW}Check interrupted by user{Color.RESET}\n")
        sys.exit(1)
    except Exception as e:
        print(f"\n{Color.RED}Error: {str(e)}{Color.RESET}\n")
        sys.exit(1)


if __name__ == '__main__':
    main()