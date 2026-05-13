# ============================================
# Script: create-nsg-rules.ps1
# Purpose: Zero Trust NSGs — DENY ALL by
#          default, EXPLICIT allow only
#          This is the core ZT network principle
# ============================================

# Fixed authentication warning for Cloud Shell
Connect-AzAccount -UseDeviceAuthentication

$rgName   = "rg-zt-network"
$location = "uksouth"

Write-Host "Creating Zero Trust NSGs..." `
    -ForegroundColor Cyan

Write-Host @"
Zero Trust NSG Principle:
DENY ALL by default
ONLY explicitly approved traffic allowed
Every connection verified individually
"@ -ForegroundColor Yellow

# ---- WORKLOAD NSG ----
Write-Host "`nCreating Workload NSG..." -ForegroundColor Yellow

# Deny ALL inbound by default
$denyAllInbound = New-AzNetworkSecurityRuleConfig `
    -Name "ZT-Deny-All-Inbound" `
    -Description "ZERO TRUST: Deny all inbound — explicit allow required" `
    -Protocol * `
    -Direction Inbound `
    -Priority 4096 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange * `
    -Access Deny

# Allow only from identity subnet
$allowIdentity = New-AzNetworkSecurityRuleConfig `
    -Name "ZT-Allow-Identity-Subnet" `
    -Description "Zero Trust: Allow verified identity traffic only" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix "172.16.1.0/24" `
    -SourcePortRange * `
    -DestinationAddressPrefix "172.16.2.0/24" `
    -DestinationPortRange @("443", "80") `
    -Access Allow

# Allow Azure Monitor
$allowMonitor = New-AzNetworkSecurityRuleConfig `
    -Name "ZT-Allow-AzureMonitor" `
    -Description "Zero Trust: Allow monitoring — visibility pillar" `
    -Protocol * `
    -Direction Inbound `
    -Priority 200 `
    -SourceAddressPrefix "AzureMonitor" `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange * `
    -Access Allow

# Allow Defender for Cloud
$allowDefender = New-AzNetworkSecurityRuleConfig `
    -Name "ZT-Allow-Defender" `
    -Description "Zero Trust: Allow Defender scanning" `
    -Protocol * `
    -Direction Inbound `
    -Priority 300 `
    -SourceAddressPrefix "AzureSecurityCenter" `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange * `
    -Access Allow

# Deny ALL outbound by default
$denyAllOutbound = New-AzNetworkSecurityRuleConfig `
    -Name "ZT-Deny-All-Outbound" `
    -Description "ZERO TRUST: Deny all outbound — explicit allow required" `
    -Protocol * `
    -Direction Outbound `
    -Priority 4096 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange * `
    -Access Deny

# Allow HTTPS outbound only
$allowHTTPS = New-AzNetworkSecurityRuleConfig `
    -Name "ZT-Allow-HTTPS-Outbound" `
    -Description "Zero Trust: Allow HTTPS outbound only" `
    -Protocol Tcp `
    -Direction Outbound `
    -Priority 100 `
    -SourceAddressPrefix "172.16.2.0/24" `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange "443" `
    -Access Allow

# Allow Azure services outbound
$allowAzureOut = New-AzNetworkSecurityRuleConfig `
    -Name "ZT-Allow-Azure-Services-Out" `
    -Description "Zero Trust: Allow Azure service tags" `
    -Protocol * `
    -Direction Outbound `
    -Priority 200 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix "AzureCloud" `
    -DestinationPortRange * `
    -Access Allow

# Create Workload NSG
$workloadNSG = New-AzNetworkSecurityGroup `
    -Name "nsg-zt-workloads" `
    -ResourceGroupName $rgName `
    -Location $location `
    -SecurityRules @(
        $allowIdentity,
        $allowMonitor,
        $allowDefender,
        $denyAllInbound,
        $allowHTTPS,
        $allowAzureOut,
        $denyAllOutbound
    ) `
    -Tag @{
        Purpose   = "Zero-Trust-NSG"
        Principle = "Deny-All-Explicit-Allow"
    }

Write-Host "✅ Zero Trust Workload NSG created!" `
    -ForegroundColor Green

# ---- MANAGEMENT NSG — Strictest ----
Write-Host "`nCreating Management NSG..." `
    -ForegroundColor Yellow

$denyAllMgmtIn = New-AzNetworkSecurityRuleConfig `
    -Name "ZT-Deny-All-Management-Inbound" `
    -Description "ZERO TRUST: Management subnet deny all" `
    -Protocol * `
    -Direction Inbound `
    -Priority 4096 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange * `
    -Access Deny

# FIXED: Replaced "AzureBastionSubnet" string with the actual CIDR block
$allowBastionMgmt = New-AzNetworkSecurityRuleConfig `
    -Name "ZT-Allow-Bastion-Only" `
    -Description "Zero Trust: Only Bastion can reach management" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix "172.16.3.0/24" `
    -SourcePortRange * `
    -DestinationAddressPrefix "172.16.4.0/24" `
    -DestinationPortRange @("3389", "22") `
    -Access Allow

$mgmtNSG = New-AzNetworkSecurityGroup `
    -Name "nsg-zt-management" `
    -ResourceGroupName $rgName `
    -Location $location `
    -SecurityRules @(
        $allowBastionMgmt,
        $denyAllMgmtIn
    ) `
    -Tag @{
        Purpose   = "Zero-Trust-Management-NSG"
        Security  = "Maximum-Restriction"
    }

Write-Host "✅ Zero Trust Management NSG created!" `
    -ForegroundColor Green

# Apply NSGs to subnets
Write-Host "`nApplying NSGs to subnets..." `
    -ForegroundColor Yellow

$ztVnet = Get-AzVirtualNetwork `
    -Name "vnet-zerotrust-uksouth" `
    -ResourceGroupName $rgName

Set-AzVirtualNetworkSubnetConfig `
    -VirtualNetwork $ztVnet `
    -Name "snet-zt-workloads" `
    -AddressPrefix "172.16.2.0/24" `
    -NetworkSecurityGroup $workloadNSG |
    Set-AzVirtualNetwork | Out-Null

Write-Host "✅ Workload NSG applied!" -ForegroundColor Green

Set-AzVirtualNetworkSubnetConfig `
    -VirtualNetwork $ztVnet `
    -Name "snet-zt-management" `
    -AddressPrefix "172.16.4.0/24" `
    -NetworkSecurityGroup $mgmtNSG |
    Set-AzVirtualNetwork | Out-Null

Write-Host "✅ Management NSG applied!" -ForegroundColor Green

Write-Host "`n=== ZERO TRUST NSG SUMMARY ===" `
    -ForegroundColor Cyan
Write-Host "Workload NSG:   DENY ALL + Explicit Allow" `
    -ForegroundColor Green
Write-Host "Management NSG: DENY ALL + Bastion Only" `
    -ForegroundColor Green
Write-Host "Principle:      Never Trust Always Verify" `
    -ForegroundColor Cyan

