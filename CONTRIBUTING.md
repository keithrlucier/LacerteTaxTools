# Contributing to Lacerte Primary Options Path Manager

First off, thank you for considering contributing to the Lacerte Primary Options Path Manager! This tool helps tax professionals manage their Lacerte software configurations, and your contributions can make a real difference in their daily workflows.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Pull Requests](#pull-requests)
- [Development Guidelines](#development-guidelines)
  - [PowerShell Coding Standards](#powershell-coding-standards)
  - [Testing Requirements](#testing-requirements)
  - [Documentation Standards](#documentation-standards)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Development Setup](#development-setup)
- [Release Process](#release-process)

---

## Code of Conduct

### Our Pledge

We are committed to providing a friendly, safe, and welcoming environment for all contributors, regardless of experience level, gender identity and expression, sexual orientation, disability, personal appearance, body size, race, ethnicity, age, religion, nationality, or other similar characteristics.

### Expected Behavior

- Be respectful and considerate in your communication
- Accept constructive criticism gracefully
- Focus on what is best for the community and end users
- Show empathy towards other community members

### Unacceptable Behavior

- Harassment, discrimination, or derogatory comments
- Personal attacks or insults
- Publishing others' private information without permission
- Any conduct that could reasonably be considered inappropriate in a professional setting

---

## Getting Started

1. **Fork the repository** to your GitHub account
2. **Clone your fork** locally: `git clone https://github.com/YOUR-USERNAME/lacerte-options-manager.git`
3. **Create a branch** for your changes: `git checkout -b feature/your-feature-name`
4. **Make your changes** following our guidelines
5. **Test thoroughly** in a safe environment
6. **Commit your changes** with clear messages
7. **Push to your fork** and submit a pull request

---

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report, please check existing issues to avoid duplicates. When creating a bug report, include:

#### Required Information:
- **Lacerte version and tax year** (e.g., Lacerte 2024, Tax Year 2024)
- **PowerShell version** - Run `$PSVersionTable` and include the output
- **Windows version** (e.g., Windows 10 Pro 22H2, Windows Server 2019)
- **Network configuration** (local vs. network drives, UNC paths if relevant)
- **Complete error message** and stack trace if applicable
- **Relevant log file excerpts** from `C:\temp\LacerteOptionsTool\Logs\`

#### Bug Report Template:
```markdown
**Environment:**
- Lacerte Version: [e.g., 2024]
- Tax Year: [e.g., 2024]
- PowerShell Version: [paste $PSVersionTable output]
- Windows Version: [e.g., Windows 10 Pro]
- Network Setup: [local/network/hybrid]

**Description:**
[Clear description of the bug]

**Steps to Reproduce:**
1. [First step]
2. [Second step]
3. [...]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Error Messages/Logs:**
```
[Paste relevant errors or log excerpts]
```

**Additional Context:**
[Any other relevant information]
```

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Use case description** - Why is this enhancement needed?
- **Current workaround** (if any)
- **Proposed solution** with expected behavior
- **Alternative solutions** you've considered
- **Impact assessment** - Who would benefit and how?

### Pull Requests

1. **Ensure your code follows our PowerShell standards** (see below)
2. **Update documentation** for any changed functionality
3. **Add comments** for complex logic
4. **Test in multiple scenarios** (single user, multi-user, network drives)
5. **Update README.md** if you've added features
6. **Reference any related issues** in your PR description

#### PR Checklist:
- [ ] Code follows PowerShell best practices
- [ ] Tested on PowerShell 5.1+
- [ ] Tested with actual Lacerte installation
- [ ] Updated relevant documentation
- [ ] Added/updated error handling
- [ ] Logging is comprehensive
- [ ] Backup mechanism tested
- [ ] No hardcoded paths (except defaults)
- [ ] Works with network drives

---

## Development Guidelines

### PowerShell Coding Standards

#### General Principles:
- **Compatibility**: Maintain PowerShell 5.1 compatibility (no PS Core-only features)
- **Safety First**: Always implement dry-run capability for destructive operations
- **Comprehensive Logging**: Every significant action should be logged
- **Error Handling**: Use try-catch blocks; never fail silently
- **User Feedback**: Provide clear, actionable messages

#### Naming Conventions:
```powershell
# Functions: Verb-Noun (approved PowerShell verbs)
function Get-LacerteOptionPath { }
function Set-ModulePath { }
function Update-OptionFile { }

# Variables: PascalCase for globals, camelCase for locals
$global:LogFile = "..."
$localVariable = "..."

# Parameters: PascalCase
param([string]$UserName, [int]$TaxYear)

# Constants: UPPERCASE with underscores (in hashtables)
$CONFIG = @{
    DEFAULT_YEAR = 2024
    MAX_RETRIES = 3
}
```

#### Code Structure:
```powershell
#region ======= Section Name =======
# Code block
#endregion ========================

# Function documentation
<#
.SYNOPSIS
    Brief description
.DESCRIPTION
    Detailed description
.PARAMETER ParameterName
    Parameter description
.EXAMPLE
    Usage example
#>
function Function-Name {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RequiredParam,
        
        [string]$OptionalParam = "Default"
    )
    
    # Implementation
}
```

#### Error Handling Pattern:
```powershell
try {
    # Risky operation
    $result = Some-Operation
    Write-Log "Operation successful: $result" 'SUCCESS'
} catch {
    Write-Log "Operation failed: $_" 'ERROR'
    # Graceful fallback or rethrow if critical
    throw
}
```

### Testing Requirements

#### Before Submitting:

1. **Environment Testing:**
   - [ ] Windows 10/11 with PowerShell 5.1
   - [ ] Windows Server 2016/2019/2022 (if applicable)
   - [ ] Local drive configuration (C:\Lacerte)
   - [ ] Network drive configuration (mapped drives)
   - [ ] UNC path configuration

2. **Scenario Testing:**
   - [ ] Fresh Lacerte installation (no existing options)
   - [ ] Existing single-user setup
   - [ ] Multi-user environment
   - [ ] Mixed local/network configuration
   - [ ] Drive mapping scenarios
   - [ ] Permission-restricted environments

3. **Feature Testing:**
   - [ ] Dry run mode shows correct preview
   - [ ] Backup creation and verification
   - [ ] Logging completeness and accuracy
   - [ ] All tax modules update correctly
   - [ ] K1 path configuration
   - [ ] Rollback capability (if applicable)

#### Test Data Safety:
- **NEVER test on production data**
- Create test Lacerte installations
- Use virtual machines when possible
- Document your test environment in PR

### Documentation Standards

#### Code Comments:
```powershell
# Single line comment for simple explanations

<#
Multi-line comment block for complex logic
explaining the why, not just the what
#>

# TODO: Items needing future attention
# FIXME: Known issues requiring fixes
# HACK: Temporary workarounds (explain why)
# NOTE: Important information for maintainers
```

#### README Updates:
- Update version number if applicable
- Add new features to feature list
- Update system requirements if changed
- Add examples for new functionality
- Update troubleshooting section for known issues

---

## Commit Message Guidelines

Follow the conventional commits specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types:
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Formatting, missing semicolons, etc.
- **refactor**: Code restructuring without changing functionality
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates

### Examples:
```
feat(backup): add SHA256 verification for backup integrity

Implemented SHA256 hashing for all backed-up files to ensure
data integrity. Manifest now includes pre and post hashes.

Closes #42
```

```
fix(network): improve UNC path discovery for unmapped drives

Added fallback methods using registry and net use command
when SMB mapping detection fails.

Fixes #38
```

---

## Development Setup

### Prerequisites

1. **Windows Development Environment:**
   - Windows 10/11 or Windows Server 2016+
   - PowerShell 5.1 or higher
   - Git for Windows

2. **Lacerte Software (for testing):**
   - At least one version of Lacerte installed
   - Test data files (non-production)
   - Network share access (for network testing)

3. **Recommended Tools:**
   - Visual Studio Code with PowerShell extension
   - Git GUI client (optional)
   - PSScriptAnalyzer for code analysis

### Setting Up Development Environment

```powershell
# 1. Clone the repository
git clone https://github.com/YOUR-USERNAME/lacerte-options-manager.git
cd lacerte-options-manager

# 2. Create development branch
git checkout -b feature/your-feature

# 3. Set up test environment variables (optional)
$env:LACERTE_TEST_PATH = "C:\Lacerte\Test"
$env:LACERTE_TEST_YEAR = 2024

# 4. Install PSScriptAnalyzer (recommended)
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser

# 5. Run code analysis
Invoke-ScriptAnalyzer -Path .\lacerte_primary_options.ps1
```

### Testing Your Changes

```powershell
# 1. Run in dry-run mode first
.\lacerte_primary_options.ps1
# Choose N at confirmation to see dry run only

# 2. Test with verbose logging
$VerbosePreference = "Continue"
.\lacerte_primary_options.ps1

# 3. Check logs
Get-Content C:\temp\LacerteOptionsTool\Logs\*.log -Tail 50
```

---

## Release Process

### Version Numbering

We use semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes or significant rewrites
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes and minor improvements

### Release Checklist

1. [ ] All tests pass
2. [ ] Documentation updated
3. [ ] CHANGELOG.md updated
4. [ ] Version number updated in script header
5. [ ] README.md version badge updated
6. [ ] Create GitHub release with notes
7. [ ] Tag release with version number

---

## Questions or Need Help?

- Check existing [issues](https://github.com/YOUR-ORG/lacerte-options-manager/issues)
- Review [documentation](README.md)
- Post in [discussions](https://github.com/YOUR-ORG/lacerte-options-manager/discussions)
- Contact maintainers through issue comments

---

## Recognition

Contributors will be recognized in:
- The README.md contributors section
- GitHub's contributor graph
- Release notes for significant contributions

Thank you for helping make the Lacerte Primary Options Path Manager better for everyone!

---

*Last updated: January 2025*
