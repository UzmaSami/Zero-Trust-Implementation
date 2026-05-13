# ============================================
# Script: verify-zero-trust.ps1
# Purpose: Verify ALL Zero Trust pillars
#          are correctly implemented
#          Score each pillar 0-100%
# ============================================

Connect-AzAccount
Connect-MgGraph -Scopes "Policy.Read.All"

Write-Host @"
╔══════════════════════════════════════════╗
║   Zero Trust Verification Report        ║
║   Author: Uzma Sami | AZ-104 | AZ-500  ║
╚══════════════════════════════════════════╝
"@ -ForegroundColor Cyan

$pillarScores = @{}

# ---- IDENTITY PILLAR ----
Write-Host "`n[PILLAR 1] IDENTITY" -ForegroundColor Cyan

$identityChecks = 0
$identityPassed = 0

# Check CA Policies
$caPolicies = Get-MgIdentityConditionalAccessPolicy
$identityChecks++
if ($caPolicies.Count -ge 3) {
    $identityPassed++
    Write-Host "  ✅ CA Policies: $($caPolicies.Count) configured" `
        -ForegroundColor Green
} else {
    Write-Host "  ❌ CA Policies: Insufficient" `
        -ForegroundColor Red
}

# Check MFA policy exists
$mfaPolicy = $caPolicies |
    Where-Object {
        $_.GrantControls.BuiltInControls `
        -contains "mfa"
    }
$identityChecks++
if ($mfaPolicy) {
    $identityPassed++
    Write-Host "  ✅ MFA Policy: Active" -ForegroundColor Green
} else {
    Write-Host "  ❌ MFA Policy: Missing" -ForegroundColor Red
}

# Check legacy auth block
$legacyBlock = $caPolicies |
    Where-Object {
        $_.GrantControls.BuiltInControls `
        -contains "block" -and
        $_.Conditions.ClientAppTypes `
        -contains "other"
    }
$identityChecks++
if ($legacyBlock) {
    $identityPassed++
    Write-Host "  ✅ Legacy Auth: BLOCKED" -ForegroundColor Green
} else {
    Write-Host "  ❌ Legacy Auth: Not blocked" -ForegroundColor Red
}

$pillarScores["Identity"] = [math]::Round(
    ($identityPassed / $identityChecks) * 100
)

# ---- NETWORK PILLAR ----
Write-Host "`n[PILLAR 2] NETWORK" -ForegroundColor Cyan

$networkChecks = 0
$networkPassed = 0

$nsgs = Get-AzNetworkSecurityGroup `
    -ResourceGroupName "rg-zt-network" `
    -ErrorAction SilentlyContinue

$networkChecks++
if ($nsgs.Count -ge 2) {
    $networkPassed++
    Write-Host "  ✅ NSGs: $($nsgs.Count) deployed" `
        -ForegroundColor Green
} else {
    Write-Host "  ❌ NSGs: Insufficient" -ForegroundColor Red
}

# Check deny all rules
$denyAllNSG = $nsgs |
    Where-Object {
        $_.SecurityRules |
        Where-Object {
            $_.Access -eq "Deny" -and
            $_.SourceAddressPrefix -eq "*" -and
            $_.Priority -ge 4000
        }
    }
$networkChecks++
if ($denyAllNSG) {
    $networkPassed++
    Write-Host "  ✅ Deny-All Rules: Configured" `
        -ForegroundColor Green
} else {
    Write-Host "  ❌ Deny-All Rules: Missing" `
        -ForegroundColor Red
}

# Check VNet micro-segmentation
$vnet = Get-AzVirtualNetwork `
    -Name "vnet-zerotrust-uksouth" `
    -ResourceGroupName "rg-zt-network" `
    -ErrorAction SilentlyContinue

$networkChecks++
if ($vnet -and $vnet.Subnets.Count -ge 4) {
    $networkPassed++
    Write-Host "  ✅ Micro-segmentation: $($vnet.Subnets.Count) segments" `
        -ForegroundColor Green
} else {
    Write-Host "  ❌ Micro-segmentation: Insufficient" `
        -ForegroundColor Red
}

$pillarScores["Network"] = [math]::Round(
    ($networkPassed / $networkChecks) * 100
)

# ---- DATA PILLAR ----
Write-Host "`n[PILLAR 3] DATA" -ForegroundColor Cyan

$dataChecks = 0
$dataPassed = 0

$kvs = Get-AzKeyVault -ErrorAction SilentlyContinue
$dataChecks++
if ($kvs.Count -gt 0) {
    $dataPassed++
    Write-Host "  ✅ Key Vault: $($kvs.Count) configured" `
        -ForegroundColor Green
} else {
    Write-Host "  ❌ Key Vault: Missing" -ForegroundColor Red
}

# Check public access disabled
$privateKVs = $kvs |
    Where-Object {
        $_.PublicNetworkAccess -eq "Disabled"
    }
$dataChecks++
if ($privateKVs.Count -eq $kvs.Count -and
    $kvs.Count -gt 0) {
    $dataPassed++
    Write-Host "  ✅ No Public KV Access: Verified" `
        -ForegroundColor Green
} else {
    Write-Host "  ❌ Public Access: Still enabled" `
        -ForegroundColor Red
}

# Check Private Endpoints
$pes = Get-AzPrivateEndpoint `
    -ResourceGroupName "rg-zt-network" `
    -ErrorAction SilentlyContinue
$dataChecks++
if ($pes.Count -gt 0) {
    $dataPassed++
    Write-Host "  ✅ Private Endpoints: $($pes.Count) active" `
        -ForegroundColor Green
} else {
    Write-Host "  ❌ Private Endpoints: Missing" `
        -ForegroundColor Red
}

$pillarScores["Data"] = [math]::Round(
    ($dataPassed / $dataChecks) * 100
)

# ---- VISIBILITY PILLAR ----
Write-Host "`n[PILLAR 4] VISIBILITY" -ForegroundColor Cyan

$visChecks = 0
$visPassed = 0

# Check Log Analytics
$workspaces = Get-AzOperationalInsightsWorkspace
$visChecks++
if ($workspaces.Count -gt 0) {
    $visPassed++
    Write-Host "  ✅ Log Analytics: Active" -ForegroundColor Green
} else {
    Write-Host "  ❌ Log Analytics: Missing" -ForegroundColor Red
}

# Check Defender
$defenderPlans = Get-AzSecurityPricing |
    Where-Object {$_.PricingTier -eq "Standard"}
$visChecks++
if ($defenderPlans.Count -ge 3) {
    $visPassed++
    Write-Host "  ✅ Defender Plans: $($defenderPlans.Count) enabled" `
        -ForegroundColor Green
} else {
    Write-Host "  ❌ Defender Plans: Insufficient" `
        -ForegroundColor Red
}

# Check Sentinel
$sentinelEnabled = $false
foreach ($ws in $workspaces) {
    $sentinel = Get-AzSentinelOnboardingState `
        -ResourceGroupName $ws.ResourceGroupName `
        -WorkspaceName $ws.Name `
        -Name "default" `
        -ErrorAction SilentlyContinue
    if ($sentinel) {$sentinelEnabled = $true}
}

$visChecks++
if ($sentinelEnabled) {
    $visPassed++
    Write-Host "  ✅ Sentinel: ENABLED" -ForegroundColor Green
} else {
    Write-Host "  ❌ Sentinel: Not enabled" -ForegroundColor Red
}

$pillarScores["Visibility"] = [math]::Round(
    ($visPassed / $visChecks) * 100
)

# ---- OVERALL SCORE ----
$overallScore = [math]::Round(
    ($pillarScores.Values |
    Measure-Object -Average).Average
)

Write-Host "`n========================================" `
    -ForegroundColor Cyan
Write-Host "ZERO TRUST MATURITY SCORES" -ForegroundColor Cyan
Write-Host "========================================" `
    -ForegroundColor Cyan

foreach ($pillar in $pillarScores.Keys) {
    $score = $pillarScores[$pillar]
    $color = if ($score -ge 80) {"Green"} `
             elseif ($score -ge 60) {"Yellow"} `
             else {"Red"}
    Write-Host "$pillar Pillar: $score%" `
        -ForegroundColor $color
}

Write-Host "----------------------------------------" `
    -ForegroundColor Gray
Write-Host "Overall ZT Score: $overallScore%" `
    -ForegroundColor $(
        if ($overallScore -ge 80) {"Green"}
        elseif ($overallScore -ge 60) {"Yellow"}
        else {"Red"}
    )
Write-Host "========================================" `
    -ForegroundColor Cyan

# Save scores
$pillarScores["Overall"] = $overallScore
$pillarScores | ConvertTo-Json |
    Out-File ".\zt-scores.json"

Write-Host "`n✅ Scores saved to zt-scores.json!" `
    -ForegroundColor Green

