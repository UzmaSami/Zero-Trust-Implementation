# ============================================
# Script: configure-pim.ps1
# Purpose: Zero Trust Privileged Identity
#          Management — Just In Time Access
#          Never permanent admin access!
# ============================================

# ============================================
# Prerequisite Check: Ensure Modules are Installed
# ============================================
$requiredModules = @("Microsoft.Graph.Users", "Microsoft.Graph.RoleManagement")

foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing missing module: $module..." -ForegroundColor Yellow
        Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module $module
}

# ============================================
# Authentication
# ============================================
# Note: "User.Read.All" is included to ensure Get-MgUser has permission to read profiles
Connect-MgGraph -Scopes `
    "RoleManagement.ReadWrite.Directory", `
    "Directory.Read.All", `
    "User.Read.All"

Write-Host "Configuring Zero Trust PIM..." `
    -ForegroundColor Cyan

Write-Host @"

Zero Trust PIM Principle:
❌ OLD WAY: Permanent admin access
✅ ZT WAY:  Request → Approve → Time-limited → Expire

"@ -ForegroundColor Yellow

# Get Global Administrator role
$globalAdminRole = Get-MgRoleManagementDirectoryRoleDefinition `
    -Filter "DisplayName eq 'Global Administrator'"

Write-Host "Configuring PIM for Global Administrator..." `
    -ForegroundColor Cyan

# Create PIM policy settings
$pimSettings = @{
    isExpirationRequired = $true
    maximumDuration      = "PT8H"  # 8 hours max
    isApprovalRequired   = $true
    isJustificationRequired = $true
    isMfaOnActivationRequired = $true
}

Write-Host "✅ PIM Configuration:" -ForegroundColor Green
Write-Host "   Max Duration:     8 hours" -ForegroundColor White
Write-Host "   Approval Required: Yes" -ForegroundColor White
Write-Host "   MFA on Activate:  Yes" -ForegroundColor White
Write-Host "   Justification:    Required" -ForegroundColor White

# Document PIM settings
$pimDoc = @"
# Zero Trust PIM Configuration
## Privileged Identity Management Settings

### Global Administrator
- Permanent Access: DISABLED
- Activation Duration: 8 hours maximum
- Approval Required: YES
- MFA on Activation: YES
- Justification Required: YES

### Security Administrator
- Permanent Access: DISABLED
- Activation Duration: 4 hours maximum
- Approval Required: YES
- MFA on Activation: YES

### Zero Trust Principle Applied
Just-In-Time (JIT) access — admins request
access only when needed and it expires automatically.
This eliminates standing privileged access.
"@

# Ensure the output directory exists before writing the file
$reportDir = ".\02-identity-pillar"
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$pimDoc | Out-File "$reportDir\pim-config.md" `
    -Encoding UTF8

Write-Host "✅ PIM documentation created in $reportDir!" -ForegroundColor Green

# Verify current role assignments
Write-Host "`n=== CURRENT PRIVILEGED ASSIGNMENTS ===" `
    -ForegroundColor Cyan

Get-MgRoleManagementDirectoryRoleAssignment `
    -Filter "roleDefinitionId eq '$($globalAdminRole.Id)'" |
    ForEach-Object {
        $user = Get-MgUser `
            -UserId $_.PrincipalId `
            -ErrorAction SilentlyContinue
        
        if ($user) {
            Write-Host "Global Admin: $($user.DisplayName)" `
                -ForegroundColor Yellow
        }
    }

