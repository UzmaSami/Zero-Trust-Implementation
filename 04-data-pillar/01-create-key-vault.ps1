# ============================================================
# Script: create-keyvault.ps1
# Purpose: Zero Trust Data Pillar - Key Vault with Private Link
# Updated: May 2026
# ============================================================

# Use device auth for stable connection in Cloud Shell
Connect-AzAccount -UseDeviceAuthentication

$rgDataName = "rg-zt-data"
$rgNetName  = "rg-zt-network"
$location   = "uksouth"
$kvName     = "kv-zt-uzmasami-2026"

Write-Host "`n--- ZERO TRUST DATA PILLAR: KEY VAULT DEPLOYMENT ---" -ForegroundColor Cyan

# 1. Create Key Vault (Simplified for 2026 - RBAC/Soft-Delete Default)
try {
    Write-Host "Step 1: Creating Private Key Vault..." -ForegroundColor Yellow
    $keyVault = New-AzKeyVault `
        -Name $kvName `
        -ResourceGroupName $rgDataName `
        -Location $location `
        -Sku Standard `
        -SoftDeleteRetentionInDays 90 `
        -EnablePurgeProtection `
        -PublicNetworkAccess Disabled `
        -ErrorAction Stop

    Write-Host "✅ Key Vault Created Successfully (Public Access: DISABLED)" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED to create Key Vault: $($_.Exception.Message)" -ForegroundColor Red
    return # Exit if the foundation isn't built
}

# 2. Create Private Endpoint
try {
    Write-Host "`nStep 2: Creating Private Endpoint in Network VNet..." -ForegroundColor Yellow
    
    # Grab the networking details from your previous lab
    $ztVnet = Get-AzVirtualNetwork -Name "vnet-zerotrust-uksouth" -ResourceGroupName $rgNetName
    $peSubnet = $ztVnet.Subnets | Where-Object {$_.Name -eq "snet-zt-endpoints"}

    $kvConnection = New-AzPrivateLinkServiceConnection `
        -Name "plsc-zt-keyvault" `
        -PrivateLinkServiceId $keyVault.ResourceId `
        -GroupId "vault"

    $kvPE = New-AzPrivateEndpoint `
        -Name "pe-zt-keyvault" `
        -ResourceGroupName $rgNetName `
        -Location $location `
        -Subnet $peSubnet `
        -PrivateLinkServiceConnection $kvConnection `
        -ErrorAction Stop

    Write-Host "✅ Private Endpoint Created!" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED to create Private Endpoint: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# 3. Configure Private DNS (Your Fixed Logic)
try {
    Write-Host "`nStep 3: Configuring Private DNS..." -ForegroundColor Yellow
    $dnsZoneName = "privatelink.vaultcore.azure.net"
    
    # Check if zone exists
    $kvDNS = Get-AzPrivateDnsZone -Name $dnsZoneName -ResourceGroupName $rgNetName -ErrorAction SilentlyContinue
    if (!$kvDNS) {
        $kvDNS = New-AzPrivateDnsZone -Name $dnsZoneName -ResourceGroupName $rgNetName
    }

    # Link VNet (Removing the problematic 'False' parameter entirely)
    $link = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $dnsZoneName -ResourceGroupName $rgNetName -Name "link-zt-vnet-kv" -ErrorAction SilentlyContinue
    if (!$link) {
        New-AzPrivateDnsVirtualNetworkLink `
            -ZoneName $dnsZoneName `
            -ResourceGroupName $rgNetName `
            -Name "link-zt-vnet-kv" `
            -VirtualNetworkId $ztVnet.Id | Out-Null
    }

    # Add Private Endpoint to the DNS Group
    $kvDnsConfig = New-AzPrivateDnsZoneConfig -Name "privatelink-vaultcore-azure-net" -PrivateDnsZoneId $kvDNS.ResourceId
    
    New-AzPrivateDnsZoneGroup `
        -ResourceGroupName $rgNetName `
        -PrivateEndpointName "pe-zt-keyvault" `
        -Name "dzg-zt-keyvault" `
        -PrivateDnsZoneConfig $kvDnsConfig | Out-Null

    Write-Host "✅ Private DNS Fully Configured!" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED at DNS stage: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== DEPLOYMENT SUMMARY ===" -ForegroundColor Cyan
Write-Host "Vault Name:      $kvName"
Write-Host "Internal Access: snet-zt-endpoints ✅"
Write-Host "Identity:        RBAC Enabled ✅"
Write-Host "Network:         Private Link Only ✅"

