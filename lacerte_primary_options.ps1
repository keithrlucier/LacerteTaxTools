<# 
Set-Lacerte-PrimaryOptions-Paths.ps1  (WinPS 5.1 compatible)

- Prompts for Tax Year and Drive Letter (editable defaults below).
- Option files are located at C:\Lacerte\YYtax\OPTIONYY (e.g., C:\Lacerte\24tax\OPTION24)
- Data paths are set to DriveLetter:\YYTAX (e.g., L:\24TAX)
- DRY RUN prints current Primary Options paths from OPMaster.wY (if present) like:
    Active options path
    C:\Lacerte\24tax\OPTION24
    Individual
    L:\24TAX\IDATA
    L:\24TAX\SHARED\K1
    ...
- Confirm: Y = update OPMaster only | A = update all users (OPMaster + OPT*.wY) | N = cancel.
- Logs:   C:\temp\LacerteOptionsTool\Logs\LacerteOptionsTool_<timestamp>.log
- Backups for each CHANGED file:
    C:\temp\LacerteOptionsTool\Backups\<timestamp>\Lacerte_<YY>tax_OPTION<YY>\  (+ manifest.json)

Tax module mapping:
  Individual  -> IDATA + K1
  Partnership -> PDATA + K1
  Corporate   -> CDATA
  S-Corp      -> SDATA + K1
  Fiduciary   -> FDATA + K1
  Exempt Org. -> RDATA
  Estate      -> TDATA
  Gift        -> NDATA
  Benefit     -> BDATA
#>

#region ======= Editable defaults ==================================================
$DefaultYear            = 2024
$DefaultDriveLetter     = 'L'       # just the letter; user can change at prompt
$DefaultProceedChoice   = 'A'       # A=All users, Y=Master only, N=Cancel
$ToolRoot               = 'C:\temp\LacerteOptionsTool'   # logs + backups
#endregion ========================================================================

#------------------------ Logging helpers ----------------------------------------
$global:RunStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$global:LogDir   = Join-Path $ToolRoot 'Logs'
$global:LogFile  = Join-Path $LogDir ("LacerteOptionsTool_{0}.log" -f $RunStamp)

function Initialize-ToolDirs {
    $dirs = @($ToolRoot, $global:LogDir)
    foreach ($d in $dirs) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS','DEBUG')] [string]$Level = 'INFO',
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'u'), $Level, $Message
    Add-Content -Path $global:LogFile -Value $line
    switch ($Level) {
        'ERROR'   { $Color = 'Red' }
        'WARN'    { $Color = 'Yellow' }
        'SUCCESS' { $Color = 'Green' }
        'DEBUG'   { $Color = 'DarkGray' }
        default   { if ($Color -eq [ConsoleColor]::Gray) { $Color = 'White' } }
    }
    Write-Host $Message -ForegroundColor $Color
}

function Get-AvailableDriveLetters {
    $letters = [char[]]([char]'C'..[char]'Z') | ForEach-Object { $_.ToString() }
    $existing = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Name
    $list = foreach ($l in $letters) {
        if ($existing -contains $l) { "{0}:" -f $l }
    }
    return ($list | Sort-Object)
}

function Read-ChoiceWithDefault {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string]$Default
    )
    $resp = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($resp)) { return $Default }
    return $resp
}

function Resolve-YearMarkers {
    param([Parameter(Mandatory)][int]$Year)
    $yy = $Year % 100
    $wy = $Year % 10
    return [pscustomobject]@{ YY = $yy; WY = $wy }
}

function Get-FileSha256Hex {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try { return (Get-FileHash -Algorithm SHA256 -Path $Path).Hash } catch { return $null }
}

function Select-DisplayValue {
    param([string]$Value, [string]$IfMissing = 'Unknown')
    if ([string]::IsNullOrWhiteSpace($Value)) { return $IfMissing } else { return $Value }
}

function Try-DiscoverUNCFromSmbMapping {
    param([Parameter(Mandatory)][string]$Letter)
    try {
        $map = Get-SmbMapping -LocalPath "$($Letter):" -ErrorAction SilentlyContinue
        if ($map) { return $map.RemotePath }
    } catch {}
    return $null
}

function Try-DiscoverUNCFromRegistry {
    param([Parameter(Mandatory)][string]$Letter)
    $regPath = "HKCU:\Network\$Letter"
    if (Test-Path $regPath) {
        try {
            $rem = (Get-ItemProperty -Path $regPath -Name RemotePath -ErrorAction Stop).RemotePath
            if ($rem) { return $rem }
        } catch {}
    }
    return $null
}

function Try-DiscoverUNCFromNetUse {
    param([Parameter(Mandatory)][string]$Letter)
    $out = net use | Out-String
    if ($out -match ("(?m)^\s*{0}:\s+\\\\[^\s]+" -f [regex]::Escape($Letter))) {
        $ln = $matches[0]
        if ($ln -match "\\\\[^\s]+") { return $matches[0].Trim() }
    }
    return $null
}

function Ensure-DriveAvailableOrMap {
    param([Parameter(Mandatory)][string]$Letter)
    $L = $Letter.TrimEnd(':')
    if (Get-PSDrive -Name $L -ErrorAction SilentlyContinue) { return "$($L):\" }

    # Attempt to discover UNC the letter should point to
    $unc = Try-DiscoverUNCFromSmbMapping -Letter $L
    if (-not $unc) { $unc = Try-DiscoverUNCFromRegistry -Letter $L }
    if (-not $unc) { $unc = Try-DiscoverUNCFromNetUse -Letter $L }

    if (-not $unc) {
        $uncInput = Read-Host "Drive $($L): not found. Enter UNC path to map (e.g., \\server\share) or press Enter to cancel"
        if ([string]::IsNullOrWhiteSpace($uncInput)) { throw "Drive $($L): not found and no UNC provided." }
        $unc = $uncInput
    }

    try {
        New-PSDrive -Name $L -PSProvider FileSystem -Root $unc -Scope Global -Persist -ErrorAction Stop | Out-Null
        if (Get-PSDrive -Name $L -ErrorAction SilentlyContinue) { 
            Write-Log ("Mapped {0}: to {1} for this session." -f $L, $unc) 'SUCCESS'
            return "$($L):\"
        }
    } catch {
        throw ("Unable to map {0}: to {1}. {2}" -f $L, $unc, $_)
    }
}

function Discover-OptionPath {
    param(
        [Parameter(Mandatory)][int]$YY,
        [Parameter(Mandatory)][string]$NewDataRoot
    )
    $candidates = @()
    $candidates += ("C:\Lacerte\{0}tax\OPTION{0}" -f $YY.ToString('00'))
    $candidates += (Join-Path $NewDataRoot ("OPTION{0}" -f $YY.ToString('00')))

    foreach ($cand in $candidates) {
        if (Test-Path -LiteralPath $cand -PathType Container) { return $cand }
    }
    # default to the first candidate if none exist yet
    return $candidates[0]
}

# Parse INI file to get current path for a module's data folder
function Get-CurrentModulePath {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Section,  # e.g., IND, PAR, COR
        [Parameter(Mandatory)][string]$Key       # e.g., "1" for data path, "1395" for K1
    )
    if ($Text -match "(?ms)\[$Section\].*?(?:^|\r?\n)$Key=([^\r\n]+)") {
        return $matches[1].Trim()
    }
    return $null
}

# === INI-aware updating of module data/K1 paths ===
function Update-OptionFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][hashtable]$ModuleMap,   # Module info with sections
        [Parameter(Mandatory)][string]$NewDataRoot,    # e.g., L:\24TAX
        [Parameter(Mandatory)][string]$NewK1Path,      # e.g., L:\24TAX\SHARED\K1
        [Parameter(Mandatory)][string]$BackupDir,      # per-run backup root for OPTIONYY
        [Parameter(Mandatory)][ref]$ManifestList       # [ref] to a list to append change records
    )

    $bytes = [IO.File]::ReadAllBytes($Path)
    $enc   = [System.Text.Encoding]::Default
    $text  = $enc.GetString($bytes)
    $original = $text

    $lines = $text -split "\r?\n", -1
    $sectionIndex = @{}
    for ($i=0; $i -lt $lines.Count; $i++) {
        $ln = $lines[$i]
        if ($ln -match '^\[(.+?)\]\s*$') {
            $sec = $matches[1]
            $sectionIndex[$sec] = $i
        }
    }

    foreach ($module in $ModuleMap.Values) {
        $sec = $module.Section
        $folder = $module.Folder
        $newPath = (Join-Path $NewDataRoot $folder)
        $needK1 = [bool]$module.K1

        if (-not $sectionIndex.ContainsKey($sec)) {
            $lines += @("", "[$sec]", "1=$newPath")
            if ($needK1) { $lines += @("1395=$NewK1Path") }
            $sectionIndex[$sec] = $lines.Count - 1
            continue
        }

        $idx = $sectionIndex[$sec] + 1
        $found1 = $false
        $foundK1 = $false
        while ($idx -lt $lines.Count) {
            $cur = $lines[$idx]
            if ($cur -match '^\[') { break } # next section
            if ($cur -match '^\s*1\s*=') { $lines[$idx] = "1=$newPath"; $found1 = $true }
            elseif ($needK1 -and $cur -match '^\s*1395\s*=') { $lines[$idx] = "1395=$NewK1Path"; $foundK1 = $true }
            $idx++
        }
        if (-not $found1) {
            $insertPos = $sectionIndex[$sec] + 1
            $lines = $lines[0..($insertPos-1)] + @("1=$newPath") + $lines[$insertPos..($lines.Count-1)]
            foreach ($k in @($sectionIndex.Keys)) {
                if ($sectionIndex[$k] -ge $insertPos) { $sectionIndex[$k]++ }
            }
        }
        if ($needK1 -and -not $foundK1) {
            $insertPos = $sectionIndex[$sec] + 1
            $lines = $lines[0..($insertPos-1)] + @("1395=$NewK1Path") + $lines[$insertPos..($lines.Count-1)]
            foreach ($k in @($sectionIndex.Keys)) {
                if ($sectionIndex[$k] -ge $insertPos) { $sectionIndex[$k]++ }
            }
        }
    }

    $newText = ($lines -join "`r`n")
    if ($newText -ne $original) {
        $preHash  = Get-FileSha256Hex -Path $Path
        $destName = Split-Path $Path -Leaf
        $bkPath   = Join-Path $BackupDir $destName

        if ($PSCmdlet.ShouldProcess($Path, "Backup original and write updated content")) {
            if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
            Copy-Item -LiteralPath $Path -Destination $bkPath -Force
            [IO.File]::WriteAllBytes($Path, $enc.GetBytes($newText))
            $postHash = Get-FileSha256Hex -Path $Path

            $record = [pscustomobject]@{
                File            = $Path
                Backup          = $bkPath
                PreHashSHA256   = $preHash
                PostHashSHA256  = $postHash
                TimeUtc         = (Get-Date).ToUniversalTime().ToString('u')
            }
            $ManifestList.Value.Add($record) | Out-Null
            return $true
        }
    }
    return $false
}

#=============================== MAIN ============================================
Initialize-ToolDirs
Write-Log "=== Lacerte Options Tool run $RunStamp ===" 'INFO' 'Cyan'

try {
    # ----- Prompt user for Year and Drive Letter --------------------------------
    $yearInput = Read-ChoiceWithDefault -Prompt "Enter Lacerte Tax Year (e.g. 2024)" -Default $DefaultYear
    $tmp = 0
    if (-not [int]::TryParse($yearInput, [ref]$tmp)) { throw "Year must be an integer, got '$yearInput'." }
    $Year  = [int]$yearInput
    $marks = Resolve-YearMarkers -Year $Year
    $YY    = $marks.YY
    $WY    = $marks.WY

    $drives = Get-AvailableDriveLetters
    Write-Host "`nAvailable drives: $($drives -join ', ')" -ForegroundColor DarkCyan
    Write-Log ("Available drives: {0}" -f ($drives -join ', ')) 'DEBUG'

    $driveInput = Read-ChoiceWithDefault -Prompt ("Enter drive letter for {0}TAX" -f $YY.ToString('00')) -Default $DefaultDriveLetter

    # Ensure the drive exists (map if needed) BEFORE Join-Path
    $Root = Ensure-DriveAvailableOrMap -Letter $driveInput

    # Data paths configuration
    $YearFolder  = ("{0}TAX" -f $YY.ToString("00"))                         # e.g., 24TAX
    $NewDataRoot = Join-Path $Root $YearFolder                               # e.g., L:\24TAX (where tax data is stored)
    
    # Option files location (auto-discover: local C:\Lacerte\YYtax\OPTIONYY or L:\YYTAX\OPTIONYY)
    $OptionPath  = Discover-OptionPath -YY $YY -NewDataRoot $NewDataRoot
    $OPMaster    = Join-Path $OptionPath ("OPMaster.w{0}" -f $WY)
    $NewK1Path   = Join-Path $NewDataRoot "SHARED\K1"                        # K1 data path under data root

    Write-Log "Selected Year=$Year (YY=$YY,WY=$WY), Root=$Root, NewDataRoot=$NewDataRoot" 'INFO'
    Write-Log "Option files location: $OptionPath" 'INFO'

    # Tax modules with their INI section names
    $ModuleMap = @{
        'IND' = [pscustomobject]@{ Name='Individual';   Section='IND'; Folder='IDATA'; K1=$true  }
        'PAR' = [pscustomobject]@{ Name='Partnership';  Section='PAR'; Folder='PDATA'; K1=$true  }
        'COR' = [pscustomobject]@{ Name='Corporate';    Section='COR'; Folder='CDATA'; K1=$false }
        'SCO' = [pscustomobject]@{ Name='S-Corp';       Section='SCO'; Folder='SDATA'; K1=$true  }
        'FID' = [pscustomobject]@{ Name='Fiduciary';    Section='FID'; Folder='FDATA'; K1=$true  }
        'EXM' = [pscustomobject]@{ Name='Exempt Org.';  Section='EXM'; Folder='RDATA'; K1=$false }
        'EST' = [pscustomobject]@{ Name='Estate';       Section='EST'; Folder='TDATA'; K1=$false }
        'GFT' = [pscustomobject]@{ Name='Gift';         Section='GFT'; Folder='NDATA'; K1=$false }
        'BFT' = [pscustomobject]@{ Name='Benefit';      Section='BFT'; Folder='BDATA'; K1=$false }
    }

    # ----- DRY RUN --------------------------------------------------------------
    Write-Host "`n=== DRY RUN (no changes) ===" -ForegroundColor Yellow
    Write-Host "Active options path" -ForegroundColor Cyan
    Write-Host $OptionPath
    Write-Host ""
    Write-Log "DRY RUN: Active options path: $OptionPath" 'INFO'

    $currentText = $null
    if (Test-Path -LiteralPath $OPMaster -PathType Leaf) {
        try {
            $bytes = [IO.File]::ReadAllBytes($OPMaster)
            $enc   = [System.Text.Encoding]::Default
            $currentText = $enc.GetString($bytes)
        } catch {
            Write-Log ("OPMaster present but could not read: {0}" -f $_) 'WARN'
            Write-Warning "OPMaster.w$WY present but unreadable; showing 'Unknown' for current paths."
        }
    } else {
        Write-Log "OPMaster.w$WY not found at $OptionPath. Paths may show as Unknown." 'WARN'
        Write-Warning "OPMaster.w$WY not found at $OptionPath. Current paths below may show as 'Unknown'."
    }

    foreach ($key in $ModuleMap.Keys | Sort-Object) {
        $m = $ModuleMap[$key]
        $name    = $m.Name
        $section = $m.Section
        $folder  = $m.Folder
        $k1Flag  = [bool]$m.K1

        $currFolderPath = if ($currentText) { Get-CurrentModulePath -Text $currentText -Section $section -Key '1' } else { $null }
        $currK1         = if ($k1Flag -and $currentText) { Get-CurrentModulePath -Text $currentText -Section $section -Key '1395' } else { $null }
        $newFolderPath  = Join-Path $NewDataRoot $folder

        $dispFolder = Select-DisplayValue -Value $currFolderPath
        $dispK1     = Select-DisplayValue -Value $currK1

        Write-Host $name -ForegroundColor White
        Write-Host $dispFolder
        if ($k1Flag) { Write-Host $dispK1 }

        Write-Host (" -> will become: {0}" -f $newFolderPath) -ForegroundColor DarkGray
        if ($k1Flag) { Write-Host (" -> will become: {0}" -f $NewK1Path) -ForegroundColor DarkGray }
        Write-Host ""

        $logMsg = "DRY RUN: {0} :: current='{1}'" -f $name, $dispFolder
        if ($k1Flag) { $logMsg += (" | K1='{0}'" -f $dispK1) }
        $logMsg += (" | new='{0}'" -f $newFolderPath)
        if ($k1Flag) { $logMsg += (" | K1 new='{0}'" -f $NewK1Path) }
        Write-Log $logMsg 'DEBUG'
    }

    # ----- Confirm --------------------------------------------------------------
    $proceed = Read-ChoiceWithDefault -Prompt "Proceed? (Y=Master only, A=All users, N=Cancel)" -Default $DefaultProceedChoice
    switch ($proceed.ToUpperInvariant()) {
        'N' { Write-Log "User cancelled after dry run. No changes made." 'WARN'; Write-Host "Cancelled. No changes made." -ForegroundColor Yellow; return }
        'Y' { $applyAll = $false; Write-Log "Proceeding: Update OPMaster only." 'INFO' }
        'A' { $applyAll = $true;  Write-Log "Proceeding: Update OPMaster + all OPT*.w$WY (all users)." 'INFO' }
        default { Write-Log "Unrecognized proceed choice '$proceed'. Aborting with no changes." 'WARN'; Write-Host "Unrecognized choice. Aborting." -ForegroundColor Yellow; return }
    }

    # Ensure Lacerte program folder exists (create if missing so the run isn't aborted)
    if (-not (Test-Path $OptionPath)) {
        New-Item -ItemType Directory -Path $OptionPath -Force | Out-Null
        Write-Log "Lacerte options folder did not exist. Created: $OptionPath" 'WARN'
    }

    # ----- Build targets --------------------------------------------------------
    $targets = @()
    if (Test-Path -LiteralPath $OPMaster -PathType Leaf) { $targets += (Get-Item $OPMaster) }
    if ($applyAll) {
        $targets += Get-ChildItem -LiteralPath $OptionPath -Filter ("OPT*.w{0}" -f $WY) -File -ErrorAction SilentlyContinue
    }

    # ----- Backups root (per-run) ----------------------------------------------
    $BackupRunDir      = Join-Path (Join-Path $ToolRoot 'Backups') $RunStamp
    $BackupOptionYYDir = Join-Path $BackupRunDir ("Lacerte_{0}tax_OPTION{0}" -f $YY.ToString('00'))
    New-Item -ItemType Directory -Path $BackupOptionYYDir -Force | Out-Null
    Write-Log "Backups for changed files will be stored in: $BackupOptionYYDir" 'INFO'

    if ($targets.Count -eq 0) {
        Write-Log "No option files found under $OptionPath. Launch Lacerte $Year once to generate OPMaster/OPT files, then rerun." 'WARN'
        Write-Host "No option files found to update under '$OptionPath'." -ForegroundColor Yellow
        Write-Host "Tip: launch Lacerte $Year once so it creates OPMaster/OPT files in $OptionPath, then rerun this tool." -ForegroundColor DarkYellow
        Write-Host ("Log: {0}" -f $global:LogFile) -ForegroundColor Cyan
        return
    }

    # ----- Update ---------------------------------------------------------------
    $changed = 0
    $manifest = New-Object System.Collections.Generic.List[object]

    foreach ($t in $targets) {
        try {
            $did = Update-OptionFile `
                -Path $t.FullName `
                -ModuleMap $ModuleMap `
                -NewDataRoot $NewDataRoot `
                -NewK1Path $NewK1Path `
                -BackupDir $BackupOptionYYDir `
                -ManifestList ([ref]$manifest) `
                -WhatIf:$false

            if ($did) { 
                Write-Log ("Updated: {0}" -f $t.FullName) 'SUCCESS'
                Write-Host ("Updated: {0}" -f $t.Name) -ForegroundColor Green
                $changed++
            } else {
                Write-Log ("No changes needed: {0}" -f $t.FullName) 'INFO'
                Write-Host ("No changes needed: {0}" -f $t.Name) -ForegroundColor DarkYellow
            }
        } catch {
            Write-Log ("Failed to update '{0}': {1}" -f $t.FullName, $_) 'ERROR'
            Write-Warning "Failed to update '$($t.FullName)': $_"
        }
    }

    # ----- Manifest -------------------------------------------------------------
    if ($manifest.Count -gt 0) {
        $manifestPath = Join-Path $BackupOptionYYDir 'manifest.json'
        ($manifest | ConvertTo-Json -Depth 4) | Out-File -FilePath $manifestPath -Encoding UTF8
        Write-Log "Manifest written: $manifestPath" 'INFO'
    } else {
        Write-Log "No files changed; no backups created." 'WARN'
    }

    # ----- Summary --------------------------------------------------------------
    Write-Host ("Complete. Files updated: {0}" -f $changed) -ForegroundColor Cyan
    if ($changed -gt 0) { Write-Host ("Backups: {0}" -f $BackupOptionYYDir) -ForegroundColor Cyan }
    Write-Host ("Log: {0}" -f $global:LogFile) -ForegroundColor Cyan

    if ($applyAll) {
        Write-Host "Applied to OPMaster and all OPT*.w$WY (all users)." -ForegroundColor Cyan
    } else {
        Write-Host "Applied to OPMaster only (Primary Options). Users may inherit on next sync." -ForegroundColor Cyan
    }
}
catch {
    Write-Log ("Fatal error: {0}" -f $_) 'ERROR'
    Write-Error $_
}
