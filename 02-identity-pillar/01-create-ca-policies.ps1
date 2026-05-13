# ============================================
# Script: create-ca-policies.ps1
# Purpose: Zero Trust Conditional Access
#          policies — Never trust always verify
# ============================================

Connect-MgGraph -Scopes `
    "Policy.Read.All", `
    "Policy.ReadWrite.ConditionalAccess"

Write-Host "Creating Zero Trust CA Policies..." `
    -ForegroundColor Cyan

# ---- ZT Policy 1: Require MFA Always ----
Write-Host "`n[1/5] ZT-CA-001: Always Require MFA..." `
    -ForegroundColor Yellow

$ztMFA = @{
    DisplayName = "ZT-CA-001: Always Verify — Require MFA"
    State       = "enabledForReportingButNotEnforced"
    Conditions  = @{
        Users = @{
            IncludeUsers = @("All")
        }
        Applications = @{
            IncludeApplications = @("All")
        }
        ClientAppTypes = @("all")
    }
    GrantControls = @{
        Operator        = "OR"
        BuiltInControls = @("mfa")
    }
}

New-MgIdentityConditionalAccessPolicy `
    -BodyParameter $ztMFA | Out-Null

Write-Host "✅ ZT-CA-001 created!" -ForegroundColor Green

# ---- ZT Policy 2: Block Legacy Auth ----
Write-Host "`n[2/5] ZT-CA-002: Block Legacy Auth..." `
    -ForegroundColor Yellow

$ztLegacy = @{
    DisplayName = "ZT-CA-002: Block Legacy Authentication"
    State       = "enabled"
    Conditions  = @{
        Users = @{
            IncludeUsers = @("All")
        }
        Applications = @{
            IncludeApplications = @("All")
        }
        ClientAppTypes = @(
            "exchangeActiveSync",
            "other"
        )
    }
    GrantControls = @{
        Operator        = "OR"
        BuiltInControls = @("block")
    }
}

New-MgIdentityConditionalAccessPolicy `
    -BodyParameter $ztLegacy | Out-Null

Write-Host "✅ ZT-CA-002 created!" -ForegroundColor Green

# ---- ZT Policy 3: Block High Risk ----
Write-Host "`n[3/5] ZT-CA-003: Block High Risk Signins..." `
    -ForegroundColor Yellow

$ztHighRisk = @{
    DisplayName = "ZT-CA-003: Block High Risk Sign-ins"
    State       = "enabled"
    Conditions  = @{
        Users = @{
            IncludeUsers = @("All")
        }
        Applications = @{
            IncludeApplications = @("All")
        }
        SignInRiskLevels = @("high")
    }
    GrantControls = @{
        Operator        = "OR"
        BuiltInControls = @("block")
    }
}

New-MgIdentityConditionalAccessPolicy `
    -BodyParameter $ztHighRisk | Out-Null

Write-Host "✅ ZT-CA-003 created!" -ForegroundColor Green

# ---- ZT Policy 4: Require Compliant Device ----
Write-Host "`n[4/5] ZT-CA-004: Require Compliant Device..." `
    -ForegroundColor Yellow

$ztDevice = @{
    DisplayName = "ZT-CA-004: Verify Device — Require Compliance"
    State       = "enabledForReportingButNotEnforced"
    Conditions  = @{
        Users = @{
            IncludeUsers = @("All")
        }
        Applications = @{
            IncludeApplications = @("All")
        }
    }
    GrantControls = @{
        Operator        = "OR"
        BuiltInControls = @(
            "compliantDevice",
            "mfa"
        )
    }
}

New-MgIdentityConditionalAccessPolicy `
    -BodyParameter $ztDevice | Out-Null

Write-Host "✅ ZT-CA-004 created!" -ForegroundColor Green

# ---- ZT Policy 5: Admin MFA Always ----
Write-Host "`n[5/5] ZT-CA-005: Admin Always MFA..." `
    -ForegroundColor Yellow

$adminRoles = @(
   "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
   "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

)

$ztAdminMFA = @{
    DisplayName = "ZT-CA-005: Admin Verify — Always MFA"
    State       = "enabled"
    Conditions  = @{
        Users = @{
            IncludeRoles = $adminRoles
        }
        Applications = @{
            IncludeApplications = @("All")
        }
    }
    GrantControls = @{
        Operator        = "OR"
        BuiltInControls = @("mfa")
    }
}

New-MgIdentityConditionalAccessPolicy `
    -BodyParameter $ztAdminMFA | Out-Null

Write-Host "✅ ZT-CA-005 created!" -ForegroundColor Green

# Summary
Write-Host "`n=== ZERO TRUST CA POLICIES ===" `
    -ForegroundColor Cyan
Get-MgIdentityConditionalAccessPolicy |
    Select-Object DisplayName, State |
    Format-Table -AutoSize

