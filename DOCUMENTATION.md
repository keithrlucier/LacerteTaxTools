# Lacerte Data Path Configuration Tool - Technical Documentation

**Version 6.0** | PowerShell 5.1+ | Windows | Enterprise Deployment

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Technical Overview](#technical-overview)
3. [Detailed Functionality](#detailed-functionality)
4. [File Operations](#file-operations)
5. [Implementation Details](#implementation-details)
6. [Deployment Scenarios](#deployment-scenarios)
7. [Error Handling & Recovery](#error-handling--recovery)
8. [API Reference](#api-reference)

---

## Executive Summary

### Purpose
The Lacerte Data Path Configuration Tool is a PowerShell script designed to update data directory paths within Lacerte tax software option files. It addresses the common enterprise need to redirect data paths when migrating servers, changing drive mappings, or standardizing network configurations across multiple users.

### Scope of Changes
- **Modifies**: Data path entries (key=1) and K1 sharing paths (key=1395) only
- **Preserves**: All other user settings (~12,000 options per file remain untouched)
- **Target Files**: OPMaster.w[Y] and/or OPT*.w[Y] files in OPTION[YY] directory

### Critical Clarification
This tool does NOT set "primary options" for all users. It specifically updates data path configurations within option files while preserving all other user preferences.

---

## Technical Overview

### Architecture

```
┌─────────────────────────────────────┐
│         PowerShell Script           │
│    (Data Path Configuration Tool)   │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│     Lacerte Option Files (INI)      │
├─────────────────────────────────────┤
│ • OPMaster.w[Y] (Template)          │
│ • OPT001.w[Y] (User 1)              │
│ • OPT002.w[Y] (User 2)              │
│ • OPT*.w[Y] (Additional Users)      │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│    Data Directories (Network)       │
├─────────────────────────────────────┤
│ [DRIVE]:\[YY]TAX\                   │
│ ├── IDATA\  (Individual)            │
│ ├── PDATA\  (Partnership)           │
│ ├── CDATA\  (Corporate)             │
│ └── SHARED\K1\ (K1 Sharing)         │
└─────────────────────────────────────┘
```

### Option File Structure

Each option file contains approximately 12,000 settings in INI format:

```ini
[IND]
1=L:\24TAX\IDATA              # Data path (modified by script)
2=1                            # Other setting (preserved)
3=0                            # Other setting (preserved)
...
1395=L:\24TAX\SHARED\K1       # K1 path (modified by script)
1396=1                         # Other setting (preserved)
...
[11999 more settings across multiple sections]
```

---

## Detailed Functionality

### Core Functions

#### 1. Initialize-ToolDirs
**Purpose**: Creates necessary directory structure for logs and backups
```powershell
Creates:
C:\temp\LacerteOptionsTool\
├── Logs\
└── Backups\
```

#### 2. Resolve-YearMarkers
**Purpose**: Converts 4-digit year to Lacerte format markers
```powershell
Input:  2024
Output: YY=24 (folder names), WY=4 (file extensions)
Usage:  24tax folder, OPMaster.w4 file
```

#### 3. Ensure-DriveAvailableOrMap
**Purpose**: Validates drive availability or creates mapping
```powershell
Process:
1. Check if drive exists
2. If not, attempt UNC discovery:
   - SMB mappings (Get-SmbMapping)
   - Registry (HKCU:\Network\[Letter])
   - Net use command output
3. Prompt for manual UNC if auto-discovery fails
4. Create persistent mapping
```

#### 4. Update-OptionFile
**Purpose**: Core function that modifies INI files
```powershell
Operations:
1. Read file preserving encoding
2. Parse INI structure into sections
3. Update ONLY key=1 (data path) and key=1395 (K1 path)
4. Preserve all other keys unchanged
5. Create backup with SHA256 hash
6. Write updated file atomically
```

### Update Modes

| Mode | Command | Files Modified | Use Case |
|------|---------|----------------|----------|
| Master Only | Y | OPMaster.w[Y] | Setting defaults for new users |
| All Users | A | OPMaster.w[Y] + all OPT*.w[Y] | Immediate update for existing users |
| Cancel | N | None | Abort operation |

### Tax Module Configuration

| Module | INI Section | Data Folder | K1 Support | K1 Path Key |
|--------|------------|-------------|------------|-------------|
| Individual | [IND] | IDATA | Yes | 1395 |
| Partnership | [PAR] | PDATA | Yes | 1395 |
| Corporate | [COR] | CDATA | No | N/A |
| S-Corp | [SCO] | SDATA | Yes | 1395 |
| Fiduciary | [FID] | FDATA | Yes | 1395 |
| Exempt Org | [EXM] | RDATA | No | N/A |
| Estate | [EST] | TDATA | No | N/A |
| Gift | [GFT] | NDATA | No | N/A |
| Benefit Plan | [BFT] | BDATA | No | N/A |

---

## File Operations

### Read Operations

#### File Discovery
```powershell
# Option path discovery order:
1. C:\Lacerte\[YY]tax\OPTION[YY]\     # Standard local installation
2. [DRIVE]:\[YY]TAX\OPTION[YY]\       # Network installation
```

#### INI Parsing
```powershell
# Preserves original structure:
- Windows-1252 encoding (default)
- CRLF line endings
- Section order
- Comment lines
- Blank lines
```

### Write Operations

#### Backup Process
```powershell
For each file to be modified:
1. Calculate SHA256 hash of original
2. Copy to timestamped backup directory
3. Update original file
4. Calculate SHA256 hash of modified
5. Record in manifest.json
```

#### Manifest Structure
```json
{
  "File": "C:\\Lacerte\\24tax\\OPTION24\\OPMaster.w4",
  "Backup": "C:\\temp\\LacerteOptionsTool\\Backups\\20240315-143022\\Lacerte_24tax_OPTION24\\OPMaster.w4",
  "PreHashSHA256": "A1B2C3D4...",
  "PostHashSHA256": "E5F6G7H8...",
  "TimeUtc": "2024-03-15T14:30:22Z"
}
```

### Safety Mechanisms

1. **Dry Run Mode**: Always executes first, showing current vs. proposed paths
2. **Atomic Writes**: Uses [IO.File]::WriteAllBytes for reliable updates
3. **Encoding Preservation**: Maintains original file encoding
4. **Backup Verification**: SHA256 hashes ensure backup integrity
5. **Error Isolation**: Continues processing if single file fails

---

## Implementation Details

### PowerShell Compatibility

**Minimum Version**: 5.1
```powershell
Required Cmdlets:
- Get-PSDrive
- Get-FileHash
- Get-SmbMapping (Windows 8/Server 2012+)
- New-PSDrive
```

### Network Drive Discovery Methods

#### Method 1: SMB Mapping
```powershell
Get-SmbMapping -LocalPath "L:" -ErrorAction SilentlyContinue
Returns: \\server\share
```

#### Method 2: Registry
```powershell
Path: HKCU:\Network\L
Key: RemotePath
Returns: \\server\share
```

#### Method 3: Net Use
```powershell
Parse output of: net use
Pattern: L:\s+\\\\server\\share
```

### Character Encoding Handling

```powershell
# Read preserving original encoding
$bytes = [IO.File]::ReadAllBytes($Path)
$enc = [System.Text.Encoding]::Default  # Windows-1252
$text = $enc.GetString($bytes)

# Write preserving encoding
[IO.File]::WriteAllBytes($Path, $enc.GetBytes($newText))
```

---

## Deployment Scenarios

### Scenario 1: Server Migration

**Challenge**: Moving from Server2019 to Server2022, maintaining same drive letter

**Solution**:
```powershell
1. Map new server to same drive letter (L:)
2. Copy all tax data to new server
3. Run script with "All Users (A)" option
4. All workstations immediately use new server
```

**Result**: Zero reconfiguration needed on workstations

### Scenario 2: Drive Letter Standardization

**Challenge**: Mixed environment with different drive letters (L:, M:, S:)

**Solution**:
```powershell
1. Decide on standard drive letter (L:)
2. Run script on each workstation or terminal server
3. Select "All Users (A)" option
4. Script updates all user files to use L:
```

**Result**: Consistent configuration across organization

### Scenario 3: New Tax Year Setup

**Challenge**: Setting up 2025 tax year with correct paths

**Solution**:
```powershell
1. Install Lacerte 2025
2. Launch once to create option files
3. Run script selecting year 2025
4. Choose "Master Only (Y)" option
5. New users automatically get correct paths
```

**Result**: New users configured correctly from start

### Scenario 4: Multi-Office Deployment

**Challenge**: 5 offices with different servers but same structure

**Solution**:
```powershell
# Customize script per office:
Office A: $DefaultDriveLetter = 'L'  # \\ServerA\TaxData
Office B: $DefaultDriveLetter = 'L'  # \\ServerB\TaxData
Office C: $DefaultDriveLetter = 'L'  # \\ServerC\TaxData

# Deploy with same drive letter, different UNC paths
```

**Result**: Standardized setup across all locations

---

## Error Handling & Recovery

### Common Errors and Solutions

#### Error: "Drive L: not found"
**Cause**: Network drive not mapped
**Solution**: Script prompts for UNC path
```
Drive L: not found. Enter UNC path to map (e.g., \\server\share): \\TaxServer\TaxData
```

#### Error: "Access denied"
**Cause**: Insufficient permissions
**Solution**: 
```powershell
# Run as Administrator
Start-Process powershell -Verb RunAs
# Then execute script
```

#### Error: "OPMaster.w4 not found"
**Cause**: Lacerte never configured
**Solution**:
1. Launch Lacerte
2. Configure options manually once
3. File will be created
4. Re-run script

### Recovery Procedures

#### Restore from Backup
```powershell
# Locate backup
C:\temp\LacerteOptionsTool\Backups\[TIMESTAMP]\

# Review manifest.json for details
notepad manifest.json

# Copy files back
Copy-Item * -Destination C:\Lacerte\24tax\OPTION24\ -Force
```

#### Verify File Integrity
```powershell
# Check SHA256 hash
Get-FileHash -Algorithm SHA256 "OPMaster.w4"

# Compare with manifest
Compare to "PreHashSHA256" in manifest.json
```

### Logging

#### Log Levels
- **INFO**: Normal operations
- **WARN**: Non-critical issues
- **ERROR**: Failures requiring attention
- **SUCCESS**: Completed operations
- **DEBUG**: Detailed troubleshooting info

#### Log Location
```
C:\temp\LacerteOptionsTool\Logs\LacerteOptionsTool_YYYYMMDD-HHMMSS.log
```

#### Log Format
```
[2024-03-15 14:30:22Z] [INFO] Selected Year=2024 (YY=24,WY=4)
[2024-03-15 14:30:23Z] [SUCCESS] Updated: OPMaster.w4
[2024-03-15 14:30:24Z] [ERROR] Failed to update OPT003.w4: Access denied
```

---

## API Reference

### Main Functions

#### Write-Log
```powershell
Write-Log -Message <String> -Level <String> [-Color <ConsoleColor>]

Levels: INFO, WARN, ERROR, SUCCESS, DEBUG
Example: Write-Log "Processing file" "INFO"
```

#### Resolve-YearMarkers
```powershell
Resolve-YearMarkers -Year <Int32>

Returns: PSCustomObject with YY and WY properties
Example: Resolve-YearMarkers -Year 2024  # Returns @{YY=24; WY=4}
```

#### Update-OptionFile
```powershell
Update-OptionFile -Path <String> -ModuleMap <Hashtable> 
                  -NewDataRoot <String> -NewK1Path <String> 
                  -BackupDir <String> -ManifestList <Ref>

Returns: Boolean (true if modified, false if no changes needed)
```

### Script Variables

#### User-Configurable Defaults
```powershell
$DefaultYear         = 2024    # Default tax year
$DefaultDriveLetter  = 'L'      # Default drive letter
$DefaultProceedChoice = 'A'     # Default confirmation (A/Y/N)
$ToolRoot           = 'C:\temp\LacerteOptionsTool'
```

#### Internal Variables
```powershell
$global:RunStamp    # Timestamp for this execution
$global:LogDir      # Log directory path
$global:LogFile     # Current log file path
$ModuleMap          # Hashtable of tax modules
```

---

## Best Practices

### Pre-Deployment
1. **Backup First**: Always backup OPTION[YY] folder manually
2. **Test Environment**: Run in test environment first if available
3. **Off-Hours**: Deploy during non-business hours
4. **Close Lacerte**: Ensure all instances closed on all workstations
5. **Document Settings**: Record current drive mappings and UNC paths

### During Deployment
1. **Review Dry Run**: Carefully review proposed changes
2. **Start Small**: Test with "Master Only" before "All Users"
3. **Monitor Logs**: Watch for errors in real-time
4. **Verify Backups**: Confirm backup files created successfully

### Post-Deployment
1. **Test Access**: Verify users can access data
2. **Check Performance**: Ensure no network latency issues
3. **Review Logs**: Check for any warnings or errors
4. **Keep Backups**: Retain backups until verified stable
5. **Document Changes**: Update network documentation

---

## Appendix

### File Extension Reference
| Year | YY | WY | Folder | File Extension |
|------|----|----|--------|---------------|
| 2024 | 24 | 4 | 24tax | .w4 |
| 2025 | 25 | 5 | 25tax | .w5 |
| 2026 | 26 | 6 | 26tax | .w6 |

### Lacerte System Files (Not Modified)
- **NETDIR.w[Y]**: System file path configuration
- **OPINDEX**: User-to-file mapping
- **SETUP.INI**: Installation configuration
- Client data files (*.I[Y], *.P[Y], *.C[Y], etc.)

### Related Lacerte Paths
```
C:\Lacerte\[YY]tax\           # Program installation
C:\Lacerte\[YY]tax\OPTION[YY]\ # Option files (modified by script)
C:\Lacerte\[YY]tax\SETUP[YY]\  # Setup configuration (not modified)
[DRIVE]:\[YY]TAX\             # Data files (path updated by script)
```

---

## Version History

### Version 6.0 (Current)
- Production-ready release
- Complete backup system with SHA256 verification
- Network drive auto-discovery (3 methods)
- Comprehensive error handling
- Full logging system
- Support for all 9 tax modules
- Dry run preview mode
- Manifest generation for audit trail

---

## Support Information

### System Requirements
- Windows 7/Server 2008 R2 or later
- PowerShell 5.1 or later
- .NET Framework 4.5 or later
- Administrator rights (for drive mapping only)

### Compatibility
- Lacerte Tax Years: 2017-2025+
- Network Versions: Yes
- Standalone Versions: Yes
- Terminal Server: Yes
- Citrix/RDS: Yes

---

## Legal Notice

This tool is provided as-is without warranty. Not affiliated with or endorsed by Intuit Inc. or Lacerte Software. Users are responsible for maintaining appropriate backups and testing in their environment.

---

## Contact and Resources

For issues, updates, or contributions, refer to the project repository.

Last Updated: 2024
Script Version: 6.0
Documentation Version: 1.0