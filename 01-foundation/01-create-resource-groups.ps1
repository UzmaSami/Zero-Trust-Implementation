# ============================================
# Script: create-resource-groups.ps1
# Purpose: Create Zero Trust foundation
#          resource groups and structure
# Author: Uzma Sami
# Date: May 2026
# ============================================

Connect-AzAccount

$location = "uksouth"

Write-Host @"
╔══════════════════════════════════════════╗
║   Zero Trust Implementation              ║
║   Author: Uzma Sami | AZ-104 | AZ-500   ║
║   Starting Foundation Setup...           ║
╚══════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Create resource groups per pillar
$resourceGroups = @(
    @{
        Name     = "rg-zt-identity"
        Purpose  = "Identity Pillar"
    },
    @{
        Name     = "rg-zt-network"
        Purpose  = "Network Pillar"
    },
    @{
        Name     = "rg-zt-data"
        Purpose  = "Data Pillar"
    },
    @{
        Name     = "rg-zt-visibility"
        Purpose  = "Visibility Pillar"
    }
)

foreach ($rg in $resourceGroups) {
    New-AzResourceGroup `
        -Name $rg.Name `
        -Location $location `
        -Tag @{
            Project     = "Zero-Trust"
            Pillar      = $rg.Purpose
            Engineer    = "Uzma Sami"
            CreatedDate = (Get-Date -Format "yyyy-MM-dd")
            Framework   = "NIST-Zero-Trust"
        } | Out-Null

    Write-Host "✅ Created: $($rg.Name)" `
        -ForegroundColor Green
}

Write-Host "`n✅ All resource groups created!" `
    -ForegroundColor Green

