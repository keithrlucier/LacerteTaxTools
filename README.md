# Lacerte Primary Options Path Manager

**Version 6.0** | PowerShell 5.1+ | Windows

---

## Overview

Automated PowerShell tool for managing Lacerte tax software data paths across all tax modules and users. Ensures consistent data path configuration for multi-user environments with shared network drives.

---

## Key Features

### Core Capabilities
- **Batch Path Updates** - Configure all tax module paths in a single operation
- **Multi-User Support** - Update master options or propagate to all users
- **Network Drive Management** - Auto-detect and map network drives as needed
- **Safe Operations** - Dry run preview before making any changes
- **Comprehensive Backup** - Automatic backup of all modified files with SHA256 verification
- **Detailed Logging** - Full audit trail of all operations

### Supported Tax Modules
| Module | Data Folder | K1 Support |
|--------|------------|------------|
| Individual | IDATA | Yes |
| Partnership | PDATA | Yes |
| Corporate | CDATA | No |
| S-Corp | SDATA | Yes |
| Fiduciary | FDATA | Yes |
| Exempt Organization | RDATA | No |
| Estate | TDATA | No |
| Gift | NDATA | No |
| Benefit Plan | BDATA | No |

---

## System Requirements

### Prerequisites
- **Windows OS** with PowerShell 5.1 or higher
- **Lacerte Tax Software** installed
- **Administrative privileges** for network drive mapping
- **Write permissions** to Lacerte option directories

### File Structure
```
C:\Lacerte\
└── [YY]tax\
    └── OPTION[YY]\
        ├── OPMaster.w[Y]     (Primary options)
        └── OPT*.w[Y]         (User options)

[DRIVE]:\
└── [YY]TAX\
    ├── IDATA\
    ├── PDATA\
    ├── CDATA\
    └── SHARED\
        └── K1\
```

---

## Installation

### Step 1: Download Script
Save `Lacerte Primary Options - Set Data Paths for all users.ps1` to your preferred location

### Step 2: Set Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 3: Configure Defaults (Optional)
Edit these variables at the top of the script:
```powershell
$DefaultYear         = 2024    # Default tax year
$DefaultDriveLetter  = 'L'      # Default data drive
$DefaultProceedChoice = 'A'     # A=All users, Y=Master only
$ToolRoot           = 'C:\temp\LacerteOptionsTool'
```

---

## Usage Guide

### Basic Execution
```powershell
.\Lacerte Primary Options - Set Data Paths for all users.ps1
```

### Interactive Prompts

**1. Tax Year Selection**
```
Enter Lacerte Tax Year (e.g. 2024) [2024]: _
```

**2. Drive Letter Selection**
```
Available drives: C:, D:, L:, S:
Enter drive letter for 24TAX [L]: _
```

**3. Dry Run Preview**
```
=== DRY RUN (no changes) ===
Active options path
C:\Lacerte\24tax\OPTION24

Individual
L:\24TAX\IDATA
L:\24TAX\SHARED\K1
 -> will become: L:\24TAX\IDATA
 -> will become: L:\24TAX\SHARED\K1
```

**4. Confirmation Options**
```
Proceed? (Y=Master only, A=All users, N=Cancel) [A]: _
```
- **Y** - Update OPMaster.w[Y] only (primary options)
- **A** - Update OPMaster.w[Y] and all OPT*.w[Y] files
- **N** - Cancel without changes

---

## Directory Structure

### Working Directories
```
C:\temp\LacerteOptionsTool\
├── Logs\
│   └── LacerteOptionsTool_[TIMESTAMP].log
└── Backups\
    └── [TIMESTAMP]\
        └── Lacerte_[YY]tax_OPTION[YY]\
            ├── OPMaster.w[Y]
            ├── OPT*.w[Y]
            └── manifest.json
```

### Data Paths Configuration
```
[DRIVE]:\[YY]TAX\              # Example: L:\24TAX\
├── IDATA\                     # Individual returns
├── PDATA\                     # Partnership returns
├── CDATA\                     # Corporate returns
├── SDATA\                     # S-Corp returns
├── FDATA\                     # Fiduciary returns
├── RDATA\                     # Exempt Organization returns
├── TDATA\                     # Estate returns
├── NDATA\                     # Gift returns
├── BDATA\                     # Benefit Plan returns
└── SHARED\
    └── K1\                    # Shared K1 data
```

---

## Advanced Features

### Network Drive Mapping
The script automatically attempts to discover UNC paths for unmapped drives using:
1. SMB mapping detection
2. Registry lookup (HKCU:\Network)
3. Net use command parsing
4. Manual UNC path entry prompt

### INI File Processing
- Preserves existing configuration structure
- Updates only data path entries (key=1)
- Updates K1 paths where applicable (key=1395)
- Creates missing sections as needed
- Maintains file encoding compatibility

### Safety Mechanisms
- **Pre-modification SHA256 hashing** of all files
- **Complete file backup** before any changes
- **Manifest generation** with change tracking
- **Atomic write operations** to prevent corruption
- **Comprehensive error handling** with rollback capability

---

## Troubleshooting

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Drive not found | Script will prompt for UNC path to map |
| No option files found | Launch Lacerte once to generate option files |
| Access denied | Run PowerShell as Administrator |
| Files not updating | Check file permissions in OPTION[YY] folder |
| Network path issues | Verify network connectivity and permissions |

### Log File Location
```
C:\temp\LacerteOptionsTool\Logs\LacerteOptionsTool_[TIMESTAMP].log
```

### Backup Recovery
All original files are preserved in:
```
C:\temp\LacerteOptionsTool\Backups\[TIMESTAMP]\
```
Use manifest.json to verify file integrity with SHA256 hashes

---

## Best Practices

### Recommended Workflow
1. **Close Lacerte** on all workstations before running
2. **Run dry run** first to preview changes
3. **Verify network connectivity** to data drives
4. **Test with one user** before applying to all
5. **Keep backups** until changes are verified

### Multi-Office Deployment
- Customize default values per location
- Use consistent drive letters across offices
- Document UNC paths for each location
- Maintain separate logs per deployment

---

## Technical Notes

### File Modifications
- **OPMaster.w[Y]** - Primary options file (affects all users on sync)
- **OPT[USERNAME].w[Y]** - Individual user option files

### Year Markers
- **YY** = Two-digit year (2024 becomes 24)
- **WY** = Single-digit year (2024 becomes 4)

### Module Section Mapping
```
[IND] -> Individual
[PAR] -> Partnership
[COR] -> Corporate
[SCO] -> S-Corporation
[FID] -> Fiduciary
[EXM] -> Exempt Organization
[EST] -> Estate
[GFT] -> Gift
[BFT] -> Benefit Plan
```

---

## Support and Contribution

### Reporting Issues
When reporting issues, please include:
- Lacerte version and tax year
- PowerShell version ($PSVersionTable)
- Complete error message
- Relevant log file excerpt

### Version History
- **v6.0** - Production release with full backup and logging
- Comprehensive error handling
- Network drive auto-discovery
- Multi-user support
- SHA256 integrity verification

---

## License

This script is provided as-is for Lacerte tax software administrators. Use at your own risk. Always maintain backups before making configuration changes.

---

## Author Notes

Developed for enterprise Lacerte deployments requiring centralized data path management across multiple users and workstations. Designed with safety and auditability as primary concerns.