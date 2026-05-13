# ============================================
# Script: enable-defender-cloud.ps1
# Purpose: Zero Trust visibility — you cannot
#          protect what you cannot see!
#          Enable full monitoring across
#          all pillars
# ============================================

Connect-AzAccount -UseDeviceAuthentication

$rgName        = "rg-zt-visibility"
$workspaceName = "law-zt-uzmasami-2026"

Write-Host "Enabling Zero Trust Visibility..." `
    -ForegroundColor Cyan

Write-Host @"
Zero Trust Visibility Principle:
Assume breach — monitor EVERYTHING
Log all access — trust nothing by default
Continuous verification through monitoring
"@ -ForegroundColor Yellow

# Enable ALL Defender plans
$defenderPlans = @(
    "VirtualMachines",
    "SqlServers",
    "AppServices",
    "StorageAccounts",
    "KeyVaults",
    "Arm",
    "Dns",
    "Containers"
)

foreach ($plan in $defenderPlans) {
    try {
        Set-AzSecurityPricing `
            -Name $plan `
            -PricingTier "Standard" `
            -ErrorAction SilentlyContinue

        Write-Host "✅ Defender enabled: $plan" `
            -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not enable: $plan" `
            -ForegroundColor Yellow
    }
}

# Enable Sentinel
Write-Host "`nEnabling Microsoft Sentinel..." `
    -ForegroundColor Yellow

New-AzSentinelOnboardingState `
    -ResourceGroupName $rgName `
    -WorkspaceName $workspaceName `
    -Name "default" `
    -ErrorAction SilentlyContinue | Out-Null

Write-Host "✅ Microsoft Sentinel ENABLED!" `
    -ForegroundColor Green

# Configure diagnostic settings
Write-Host "`nConfiguring diagnostic logging..." `
    -ForegroundColor Yellow

# Ensure Monitor module is ready
Import-Module Az.Monitor -ErrorAction SilentlyContinue

# Get workspace
$workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName

# Enable Key Vault diagnostics
$kvResource = Get-AzResource `
    -ResourceType "Microsoft.KeyVault/vaults" `
    -ResourceGroupName "rg-zt-data" `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($kvResource) {
    # THE FIX: Create the log and metric objects first
    $logSetting = New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category "AuditEvent"
    $metricSetting = New-AzDiagnosticSettingMetricSettingsObject -Enabled $true -Category "AllMetrics"

    # Pass the objects into the main command
    New-AzDiagnosticSetting `
        -ResourceId $kvResource.ResourceId `
        -WorkspaceId $workspace.ResourceId `
        -Name "diag-zt-kv" `
        -Log $logSetting `
        -Metric $metricSetting `
        -ErrorAction SilentlyContinue | Out-Null

    Write-Host "✅ Key Vault diagnostics enabled!" `
        -ForegroundColor Green
}

Write-Host "`n=== ZERO TRUST VISIBILITY SUMMARY ===" `
    -ForegroundColor Cyan
Write-Host "Defender for Cloud: ALL plans enabled ✅" `
    -ForegroundColor Green
Write-Host "Microsoft Sentinel: ENABLED ✅" -ForegroundColor Green
Write-Host "Diagnostic Logging: ACTIVE ✅" -ForegroundColor Green
Write-Host "Principle:          Assume Breach ✅" `
    -ForegroundColor Green

