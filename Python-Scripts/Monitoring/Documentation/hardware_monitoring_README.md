# Hardware Monitor

A comprehensive Python script for monitoring hardware on any Linux distribution. Fetches detailed hardware information from `/proc` and `/sys` filesystems and presents it in a clean, organized format.

## 📋 Features

- **Universal Compatibility**: Works on any Linux distribution
- **Multiple Verbosity Levels**: Choose between basic, detailed, or full hardware information
- **Smart Status Detection**: Automatically detects critical issues and warnings
- **Multiple Export Formats**: Export data to JSON, CSV, or LOG files
- **Colorized Output**: Easy-to-read terminal output with color-coded status indicators
- **Zero External Dependencies**: Uses only Python standard library

## 🔧 Hardware Information Collected

| Category | Information |
|----------|-------------|
| **System** | Hostname, Kernel, Distribution, Architecture, Uptime, Load Average |
| **CPU** | Model, Vendor, Cores, Frequency, Cache, Features/Flags |
| **Memory** | Total/Used/Available RAM, Swap Usage, Active/Inactive Memory |
| **Motherboard** | Vendor, Model, BIOS Version, Chassis Information |
| **Storage** | Block Devices, Type (SSD/HDD), Size, Model |
| **Graphics** | GPU Vendor, Driver Information |

## 📦 Requirements

- Python 3.6 or higher
- Linux operating system
- Root/sudo access (for some hardware information)

## 🚀 Installation

1. Download the script:
```bash
wget https://example.com/hardware_monitor.py
# or
curl -O https://example.com/hardware_monitor.py
```

2. Make it executable:
```bash
chmod +x hardware_monitor.py
```

3. Run it:
```bash
./hardware_monitor.py --v
```

## 💻 Usage

### Basic Usage

```bash
# Basic hardware information
python3 hardware_monitor.py --v

# Detailed hardware information
python3 hardware_monitor.py --vv

# Full hardware information (comprehensive)
python3 hardware_monitor.py --vvv
```

### Export Options

```bash
# Export to JSON format
python3 hardware_monitor.py --vv --export-format=json

# Export to CSV format
python3 hardware_monitor.py --vv --export-format=csv

# Export to LOG format
python3 hardware_monitor.py --vv --export-format=log

# Specify custom output directory
python3 hardware_monitor.py --vv --export-format=json --path=/tmp/reports
```

### Help and Version

```bash
# Display help information
python3 hardware_monitor.py --help

# Display version
python3 hardware_monitor.py --version
```

## 📊 Verbosity Levels

### Level 1: Basic (`--v`)
Essential hardware information including:
- System overview (hostname, kernel, distribution)
- CPU model and core count
- Memory usage
- Basic motherboard information
- Storage devices count
- Graphics devices count

### Level 2: Detailed (`--vv`)
All basic information plus:
- System uptime and load average
- CPU frequency and cache size
- Swap memory details
- BIOS information
- Storage device models
- GPU driver information

### Level 3: Full (`--vvv`)
All detailed information plus:
- Kernel parameters and loaded modules
- Per-core CPU frequencies
- CPU features and flags
- Memory breakdown (active/inactive/dirty pages)
- HugePages information
- Chassis and product serial numbers

## 📁 Export Formats

### JSON Format
Structured data format, ideal for:
- Integration with other tools
- Programmatic processing
- Data analysis

Example:
```json
{
  "os": {
    "category": "HardwareInfo",
    "severity": "INFO",
    "data": {
      "Hostname": "server-01",
      "Kernel Release": "5.15.0-56-generic"
    }
  }
}
```

### CSV Format
Comma-separated values, ideal for:
- Excel/LibreOffice Calc
- Data analysis
- Reporting

Format:
```csv
Category,Severity,Key,Value
HardwareInfo,INFO,Hostname,server-01
HardwareInfo,INFO,Kernel Release,5.15.0-56-generic
```

### LOG Format
Human-readable text format, ideal for:
- Documentation
- Audit logs
- Quick review

Example:
```
======================================================================
HARDWARE MONITOR - SYSTEM REPORT
Generated: 2025-10-10 14:30:00
======================================================================

[INFO] HardwareInfo
----------------------------------------------------------------------
Hostname: server-01
Kernel Release: 5.15.0-56-generic
```

## 🎨 Output Example

```
####################################################################
#      hardware_monitor.py - A Linux Hardware Monitoring Tool      #  
#                          Version 1.0.0                           #
####################################################################

Verbosity Level: Basic
Timestamp: 2025-10-10 14:30:00

+----------------------------------------------------------+
|                     SYSTEM OVERVIEW                      |
+----------------------------------------------------------+
+--------------------+---------------------------+--------+
|       Metric       |          Value            | Status |
+--------------------+---------------------------+--------+
|      Hostname      |        server-01          |   OK   |
+--------------------+---------------------------+--------+
|    Kernel Name     |          Linux            |   OK   |
+--------------------+---------------------------+--------+
```

## 🛠️ Troubleshooting

### Permission Denied Errors
Some hardware information requires elevated privileges:
```bash
sudo python3 hardware_monitor.py --v
```

### No DMI Information Available
This is normal on virtual machines or containers. The script will continue and show available information.

### Python Version Issues
Ensure you're using Python 3.6 or higher:
```bash
python3 --version
```

## 📝 Examples

### Quick System Check
```bash
# Quick overview with export
python3 hardware_monitor.py --v --export-format=log
```

### Detailed Analysis
```bash
# Detailed analysis with JSON export for further processing
python3 hardware_monitor.py --vv --export-format=json --path=./reports
```

### Comprehensive Audit
```bash
# Full system audit with all details
sudo python3 hardware_monitor.py --vvv --export-format=csv --path=/var/log/hardware
```

### Scheduled Monitoring
Add to crontab for regular monitoring:
```bash
# Run every day at 2 AM
0 2 * * * /usr/bin/python3 /path/to/hardware_monitor.py --vv --export-format=json --path=/var/log/hardware
```

## 🔍 Use Cases

- **System Administration**: Regular hardware monitoring and inventory
- **Capacity Planning**: Track resource usage over time
- **Troubleshooting**: Quick hardware diagnostics
- **Documentation**: Generate hardware reports for compliance
- **Automation**: Integrate with monitoring systems
- **Auditing**: Maintain hardware change logs

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

This project is licensed under the MIT License.

```
MIT License

Copyright (c) 2025 Alexandru Filcu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 👤 Author

**Alexandru Filcu**

## 🌟 Support

If you find this tool helpful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs
- 💡 Suggesting new features
- 📖 Improving documentation

## 📚 Version History

### Version 1.0.0 (2025-10-10)
- Initial release
- Support for OS, CPU, Memory, Motherboard, Storage, and Graphics information
- Three verbosity levels
- Export to JSON, CSV, and LOG formats
- Colorized terminal output
- Smart status detection

---

**Note**: This script reads hardware information from system files and requires appropriate permissions. Always review the script before running with elevated privileges.