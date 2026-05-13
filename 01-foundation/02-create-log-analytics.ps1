# ============================================
# Script: create-log-analytics.ps1
# Purpose: Central logging workspace for
#          ALL Zero Trust pillars
# ============================================

Connect-AzAccount

$rgName        = "rg-zt-visibility"
$location      = "uksouth"
$workspaceName = "law-zt-uzmasami-2026"

Write-Host "Creating Zero Trust Log Analytics..." `
    -ForegroundColor Cyan

$workspace = New-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -Location $location `
    -Sku "PerGB2018" `
    -RetentionInDays 90 `
    -Tag @{
        Purpose = "ZeroTrust-Logging"
        Pillar  = "Visibility"
    }

Write-Host "✅ Workspace created!" -ForegroundColor Green
Write-Host "Name: $($workspace.Name)" -ForegroundColor Cyan
Write-Host "ID:   $($workspace.CustomerId)" -ForegroundColor Cyan

# Save workspace details
@{
    WorkspaceName = $workspace.Name
    WorkspaceId   = $workspace.CustomerId
    ResourceGroup = $rgName
} | ConvertTo-Json |
    Out-File ".\workspace-details.json"

Write-Host "✅ Workspace details saved!" -ForegroundColor Green

