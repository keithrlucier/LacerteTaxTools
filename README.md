# Lacerte Data Path Configuration Tool

**Version 6.0** | PowerShell 5.1+ | Windows

---

## Overview

Automated PowerShell tool that updates data path configurations within Lacerte tax software option files. The script modifies only the data directory paths (where client files are stored) and K1 sharing paths, leaving all other user preferences and settings intact.

**Key Clarification:** This tool updates data paths within option files - it does NOT modify "primary options" globally. It can update either the master template only or both the master and all user option files.

---

## What This Script Does

### Script Modifies
- **Data path entries** (key=1) for each tax module (IDATA, PDATA, CDATA, etc.)
- **K1 path entries** (key=1395) for modules that support K1 data sharing
- Only these specific path settings within the INI-formatted option files

### Script Does NOT Modify
- User preferences, display settings, or print configurations
- Any of the other ~12,000 options per user file
- Client data files or return data
- Program files or Lacerte installation
- OPINDEX or NETDIR files

### Update Modes Explained
| Mode | Files Updated | Impact | When to Use |
|------|--------------|--------|-------------|
| **Master Only (Y)** | OPMaster.w[Y] only | Affects new users or when users sync from master | Setting defaults for future users |
| **All Users (A)** | OPMaster.w[Y] + all OPT*.w[Y] | Immediate effect on all existing users | Server migration or drive letter changes |

---

## Key Features

### Core Capabilities
- **Batch Data Path Updates** - Configure all tax module data paths in a single operation
- **Flexible Update Modes** - Update master template only or apply to all existing user files
- **Network Drive Management** - Auto-detect and map network drives as needed
- **Safe Operations** - Dry run preview before making any changes
- **Comprehensive Backup** - Automatic backup of all modified files with SHA256 verification
- **Detailed Logging** - Full audit trail of all operations

### Supported Tax Modules
| Module | Data Folder | K1 Support | INI Section |
|--------|------------|------------|-------------|
| Individual | IDATA | Yes | [IND] |
| Partnership | PDATA | Yes | [PAR] |
| Corporate | CDATA | No | [COR] |
| S-Corp | SDATA | Yes | [SCO] |
| Fiduciary | FDATA | Yes | [FID] |
| Exempt Organization | RDATA | No | [EXM] |
| Estate | TDATA | No | [EST] |
| Gift | NDATA | No | [GFT] |
| Benefit Plan | BDATA | No | [BFT] |

---

## System Requirements

### Prerequisites
- **Windows OS** with PowerShell 5.1 or higher
- **Lacerte Tax Software** installed
- **Administrative privileges** for network drive mapping (if needed)
- **Write permissions** to C:\Lacerte\[YY]tax\OPTION[YY] directory

### Lacerte File Structure
```
C:\Lacerte\
└── [YY]tax\                  # YY = 2-digit year (24 for 2024)
    └── OPTION[YY]\
        ├── OPINDEX           # User index (not modified by script)
        ├── OPMaster.w[Y]     # Master template - defaults for new users
        ├── OPT001.w[Y]       # User 1 option file (~12,000 settings)
        ├── OPT002.w[Y]       # User 2 option file
        └── OPT*.w[Y]         # Additional user files

[DRIVE]:\                     # Network data drive
└── [YY]TAX\                  # Tax year data root
    ├── IDATA\                # Individual return data
    ├── PDATA\                # Partnership return data
    ├── CDATA\                # Corporate return data
    ├── SDATA\                # S-Corp return data
    ├── FDATA\                # Fiduciary return data
    ├── RDATA\                # Exempt Organization return data
    ├── TDATA\                # Estate return data
    ├── NDATA\                # Gift return data
    ├── BDATA\                # Benefit Plan return data
    └── SHARED\
        └── K1\               # Shared K1 data (for applicable modules)
```

---

## Installation

### Step 1: Download Script
Save the PowerShell script to your preferred location

### Step 2: Set Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 3: Configure Defaults (Optional)
Edit these variables at the top of the script:
```powershell
$DefaultYear         = 2024    # Default tax year
$DefaultDriveLetter  = 'L'      # Default data drive letter
$DefaultProceedChoice = 'A'     # A=All users, Y=Master only, N=Cancel
$ToolRoot           = 'C:\temp\LacerteOptionsTool'  # Logs and backups location
```

---

## Usage Guide

### Basic Execution
```powershell
# Navigate to script location and run
.\Set-Lacerte-PrimaryOptions-Paths.ps1

# Or with full path
& "C:\Scripts\Lacerte Primary Options - Set Data Paths for all users.ps1"
```

### Interactive Workflow

**Step 1: Tax Year Selection**
```
Enter Lacerte Tax Year (e.g. 2024) [2024]: _
```
- Enter the 4-digit tax year
- Press Enter to accept default

**Step 2: Drive Letter Selection**
```
Available drives: C:, D:, L:, S:
Enter drive letter for 24TAX [L]: _
```
- Script shows currently mapped drives
- Enter letter only (L not L:)
- If drive not mapped, script will prompt for UNC path

**Step 3: Dry Run Preview**
```
=== DRY RUN (no changes) ===
Active options path
C:\Lacerte\24tax\OPTION24

Individual
L:\24TAX\IDATA
L:\24TAX\SHARED\K1
 -> will become: L:\24TAX\IDATA
 -> will become: L:\24TAX\SHARED\K1

Partnership
L:\24TAX\PDATA
L:\24TAX\SHARED\K1
 -> will become: L:\24TAX\PDATA
 -> will become: L:\24TAX\SHARED\K1
[continues for all modules...]
```

**Step 4: Confirmation**
```
Proceed? (Y=Master only, A=All users, N=Cancel) [A]: _
```
- **Y** = Update OPMaster.w[Y] only
- **A** = Update OPMaster.w[Y] and all OPT*.w[Y] files
- **N** = Cancel without changes

---

## Directory Structure

### Tool Working Directories
```
C:\temp\LacerteOptionsTool\
├── Logs\
│   └── LacerteOptionsTool_YYYYMMDD-HHMMSS.log
└── Backups\
    └── YYYYMMDD-HHMMSS\
        └── Lacerte_[YY]tax_OPTION[YY]\
            ├── OPMaster.w[Y]        # Backup of master file
            ├── OPT001.w[Y]          # Backup of user files (if modified)
            ├── OPT002.w[Y]
            └── manifest.json        # SHA256 hashes and change log
```

### Resulting Data Path Structure
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
    └── K1\                    # Shared K1 data for applicable modules
```

---

## Advanced Features

### Network Drive Mapping
When a specified drive letter is not found, the script:
1. Attempts SMB mapping detection (`Get-SmbMapping`)
2. Checks registry for persistent mappings (`HKCU:\Network`)
3. Parses `net use` output for active connections
4. Prompts for manual UNC path entry if auto-discovery fails
5. Creates persistent drive mapping for the session

### INI File Processing
- **Preserves Structure** - Maintains all existing sections and settings
- **Targeted Updates** - Only modifies data path (key=1) and K1 path (key=1395) entries
- **Section Creation** - Adds missing module sections if needed
- **Encoding Preservation** - Maintains original file encoding (typically Windows-1252)
- **Line Ending Consistency** - Preserves Windows CRLF line endings

### Safety Mechanisms
- **Pre-flight Check** - Dry run shows current and proposed paths
- **SHA256 Verification** - Hashes all files before and after modification
- **Complete Backups** - Copies original files before any changes
- **Manifest Generation** - JSON file documenting all changes with timestamps
- **Atomic Operations** - Uses .NET methods for reliable file writes
- **Error Handling** - Comprehensive try-catch blocks with detailed logging

---

## Troubleshooting

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Drive not found | Network drive not mapped | Script prompts for UNC path, or map drive manually first |
| No option files found | Lacerte never launched | Launch Lacerte once to generate option files |
| Access denied | Insufficient permissions | Run PowerShell as Administrator |
| Files not updating | Read-only files | Check file attributes in OPTION[YY] folder |
| Network path issues | Connection problems | Verify network connectivity and share permissions |
| OPMaster.w[Y] missing | New installation | Launch Lacerte and configure options once |

### Understanding Option Files
- **OPMaster.w[Y]** - Template for new users, created when admin sets defaults
- **OPT001.w[Y], OPT002.w[Y]...** - Individual user files, one per Lacerte user
- **OPINDEX** - Maps Windows usernames to OPT file numbers (not modified)
- **File contains ~12,000 options** - Script only changes data paths

### Log File Analysis
Check logs at: `C:\temp\LacerteOptionsTool\Logs\`
```
[2024-03-15] [INFO] Selected Year=2024 (YY=24,WY=4), Root=L:\, NewDataRoot=L:\24TAX
[2024-03-15] [INFO] Option files location: C:\Lacerte\24tax\OPTION24
[2024-03-15] [SUCCESS] Updated: C:\Lacerte\24tax\OPTION24\OPMaster.w4
[2024-03-15] [SUCCESS] Updated: C:\Lacerte\24tax\OPTION24\OPT001.w4
```

### Backup Recovery
To restore original files:
1. Navigate to `C:\temp\LacerteOptionsTool\Backups\[TIMESTAMP]\`
2. Review `manifest.json` for change details
3. Copy backup files back to `C:\Lacerte\[YY]tax\OPTION[YY]\`

---

## Best Practices

### Pre-Deployment Checklist
1. **Close Lacerte** on all workstations
2. **Backup existing OPTION[YY] folder** manually
3. **Verify network drive access** from the machine running script
4. **Test with one user** before applying to all
5. **Run during off-hours** to avoid conflicts

### Deployment Strategies

#### Server Migration
1. Map new server to same drive letter as old
2. Copy all data from old server to new
3. Run script with "All Users (A)" option
4. All paths updated without needing to reconfigure each workstation

#### New Tax Year Setup
1. Install new Lacerte year
2. Launch once to create option files
3. Run script with "Master Only (Y)" option
4. New users inherit correct paths automatically

#### Multi-Office Management
- Standardize drive letters across all locations
- Document UNC paths for each office
- Create office-specific script versions with appropriate defaults
- Maintain separate backup archives per location

---

## Technical Notes

### Year Notation
- **[YY]** = Two-digit year (2024 → 24)
- **[Y]** = Single-digit year (2024 → 4)
- Used in folder names: `24tax`, `OPTION24`
- Used in file names: `OPMaster.w4`, `OPT001.w4`

### INI File Format
Option files use INI format with sections and key-value pairs:
```ini
[IND]
1=L:\24TAX\IDATA
1395=L:\24TAX\SHARED\K1

[PAR]
1=L:\24TAX\PDATA
1395=L:\24TAX\SHARED\K1
```

### Module Section Mapping
| Section | Module | Data Folder | K1 Path Key |
|---------|--------|-------------|-------------|
| [IND] | Individual | IDATA | 1395 |
| [PAR] | Partnership | PDATA | 1395 |
| [COR] | Corporate | CDATA | N/A |
| [SCO] | S-Corporation | SDATA | 1395 |
| [FID] | Fiduciary | FDATA | 1395 |
| [EXM] | Exempt Organization | RDATA | N/A |
| [EST] | Estate | TDATA | N/A |
| [GFT] | Gift | NDATA | N/A |
| [BFT] | Benefit Plan | BDATA | N/A |

---

## Support and Contribution

### Reporting Issues
When reporting issues, include:
- Lacerte version and tax year
- PowerShell version (`$PSVersionTable`)
- Complete error message from console
- Relevant section from log file
- Whether using network or local installation

### Version History
- **v6.0 (Current)** - Production release
  - Full backup system with SHA256 verification
  - Comprehensive error handling and logging
  - Network drive auto-discovery
  - Support for all tax modules
  - Dry run preview mode

---

## License and Disclaimer

This script is provided as-is for Lacerte tax software administrators. 

**Important:** This tool modifies Lacerte configuration files. Always maintain backups before use. The authors assume no responsibility for data loss or configuration issues. Use at your own risk.

Not affiliated with or endorsed by Intuit Inc. or Lacerte Software.

---

## Author Notes

Developed for enterprise Lacerte deployments requiring consistent data path configuration across multiple users and workstations. The script specifically addresses the common scenario of server migrations where drive mappings need to be updated for all users simultaneously.

The tool modifies only the minimum necessary settings (data paths) while preserving all other user preferences, making it safe for production use when proper precautions are taken.