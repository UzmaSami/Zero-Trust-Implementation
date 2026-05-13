# ============================================
# Script: create-zt-vnet.ps1
# Purpose: Zero Trust network — micro
#          segmented, deny by default,
#          explicit verification required
# ============================================

Connect-AzAccount

$rgName   = "rg-zt-network"
$location = "uksouth"

Write-Host "Creating Zero Trust Network..." `
    -ForegroundColor Cyan

Write-Host @"

Zero Trust Network Principle:
❌ OLD: Flat network — trust internal traffic
✅ ZT:  Micro-segmented — verify ALL traffic

"@ -ForegroundColor Yellow

# Create Zero Trust VNet
# Smaller, segmented, purpose-built
$ztVnet = New-AzVirtualNetwork `
    -Name "vnet-zerotrust-uksouth" `
    -ResourceGroupName $rgName `
    -Location $location `
    -AddressPrefix "172.16.0.0/16" `
    -Tag @{
        Purpose   = "Zero-Trust-Network"
        Principle = "Never-Trust-Always-Verify"
        Engineer  = "Uzma Sami"
    }

Write-Host "✅ Zero Trust VNet created!" `
    -ForegroundColor Green

# Create micro-segmented subnets
# Each workload type gets its OWN subnet
$subnets = @(
    @{
        Name   = "snet-zt-identity"
        Prefix = "172.16.1.0/24"
        Purpose = "Identity services only"
    },
    @{
        Name   = "snet-zt-workloads"
        Prefix = "172.16.2.0/24"
        Purpose = "Application workloads"
    },
    @{
        Name   = "snet-zt-data"
        Prefix = "172.16.3.0/24"
        Purpose = "Data services only"
    },
    @{
        Name   = "snet-zt-management"
        Prefix = "172.16.4.0/24"
        Purpose = "Management — restricted"
    },
    @{
        Name   = "snet-zt-endpoints"
        Prefix = "172.16.5.0/24"
        Purpose = "Private endpoints"
    }
)

foreach ($subnet in $subnets) {
    $subnetConfig = New-AzVirtualNetworkSubnetConfig `
        -Name $subnet.Name `
        -AddressPrefix $subnet.Prefix `
        -PrivateEndpointNetworkPoliciesFlag "Disabled"

    $ztVnet.Subnets.Add($subnetConfig)

    Write-Host "✅ Subnet: $($subnet.Name) — $($subnet.Prefix)" `
        -ForegroundColor Green
}

# Apply subnets to VNet
$ztVnet | Set-AzVirtualNetwork | Out-Null

Write-Host "`n✅ All micro-segments created!" `
    -ForegroundColor Green

