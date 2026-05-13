# ============================================
# Script: generate-zt-report.ps1
# Purpose: Beautiful Zero Trust maturity
#          assessment report
# ============================================

Connect-AzAccount

$reportDate = Get-Date -Format "yyyy-MM-dd HH:mm"

# Load scores
$scores = @{}
if (Test-Path ".\zt-scores.json") {
    $scores = Get-Content ".\zt-scores.json" |
        ConvertFrom-Json -AsHashtable
}

$overallScore  = $scores["Overall"] ?? 0
$identityScore = $scores["Identity"] ?? 0
$networkScore  = $scores["Network"] ?? 0
$dataScore     = $scores["Data"] ?? 0
$visScore      = $scores["Visibility"] ?? 0

$scoreColor = switch ($overallScore) {
    {$_ -ge 80} {"#3fb950"}
    {$_ -ge 60} {"#e3b341"}
    default     {"#ff7b72"}
}

$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Zero Trust Implementation Report</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Segoe UI', Arial;
               background: #0d1117; color: #e6edf3;
               padding: 40px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: linear-gradient(
                      135deg, #1f6feb, #388bfd);
                  padding: 30px; border-radius: 16px;
                  margin-bottom: 25px; }
        .header h1 { font-size: 26px; }
        .header p { opacity: 0.85; font-size: 13px;
                    margin-top: 5px; }
        .score-section { display: grid;
                         grid-template-columns: 200px 1fr;
                         gap: 20px; margin-bottom: 25px; }
        .score-circle { background: #161b22;
                        border: 4px solid $scoreColor;
                        border-radius: 50%; width: 180px;
                        height: 180px; display: flex;
                        flex-direction: column;
                        align-items: center;
                        justify-content: center; }
        .score-number { font-size: 52px; font-weight: 700;
                        color: $scoreColor; }
        .score-label { font-size: 12px; color: #8b949e; }
        .pillar-grid { display: grid;
                       grid-template-columns: repeat(4,1fr);
                       gap: 15px; }
        .pillar-card { background: #161b22;
                       border: 1px solid #30363d;
                       border-radius: 10px; padding: 20px;
                       text-align: center; }
        .pillar-score { font-size: 36px; font-weight: 700; }
        .pillar-name { font-size: 13px; color: #8b949e;
                       margin-top: 5px; }
        h2 { color: #388bfd; border-left: 4px solid #1f6feb;
             padding-left: 12px; margin: 25px 0 15px; }
        .principles-grid { display: grid;
                           grid-template-columns: repeat(3,1fr);
                           gap: 15px; margin-bottom: 25px; }
        .principle-card { background: #161b22;
                          border: 1px solid #1f6feb;
                          border-radius: 10px; padding: 20px; }
        .principle-card h3 { color: #388bfd; font-size: 14px;
                             margin-bottom: 10px; }
        .principle-card p { font-size: 12px; color: #8b949e;
                            line-height: 1.6; }
        table { width: 100%; border-collapse: collapse;
                background: #161b22; border-radius: 10px;
                overflow: hidden; margin-bottom: 20px; }
        th { background: #1f6feb; color: white; padding: 12px;
             font-size: 13px; text-align: left; }
        td { padding: 10px 12px; font-size: 12px;
             border-bottom: 1px solid #21262d; }
        .badge-green { background: #1a4731; color: #3fb950;
                       padding: 3px 10px; border-radius: 20px;
                       font-size: 11px; }
        .badge-red { background: #4d1919; color: #ff7b72;
                     padding: 3px 10px; border-radius: 20px;
                     font-size: 11px; }
        footer { margin-top: 40px; text-align: center;
                 color: #8b949e; font-size: 11px;
                 padding-top: 20px;
                 border-top: 1px solid #21262d; }
    </style>
</head>
<body>
<div class='container'>

    <div class='header'>
        <h1>🔒 Zero Trust Implementation Report</h1>
        <p>Engineer: Uzma Sami | AZ-104 | AZ-500</p>
        <p>Framework: NIST Zero Trust Architecture</p>
        <p>Assessment Date: $reportDate</p>
        <p>Region: UK South</p>
    </div>

    <div class='score-section'>
        <div class='score-circle'>
            <div class='score-number'>$overallScore%</div>
            <div class='score-label'>ZT Maturity Score</div>
        </div>
        <div class='pillar-grid'>
            <div class='pillar-card'>
                <div class='pillar-score'
                     style='color:$scoreColor'>
                    $identityScore%
                </div>
                <div class='pillar-name'>
                    🔑 Identity Pillar
                </div>
            </div>
            <div class='pillar-card'>
                <div class='pillar-score'
                     style='color:$scoreColor'>
                    $networkScore%
                </div>
                <div class='pillar-name'>
                    🌐 Network Pillar
                </div>
            </div>
            <div class='pillar-card'>
                <div class='pillar-score'
                     style='color:$scoreColor'>
                    $dataScore%
                </div>
                <div class='pillar-name'>
                    💾 Data Pillar
                </div>
            </div>
            <div class='pillar-card'>
                <div class='pillar-score'
                     style='color:$scoreColor'>
                    $visScore%
                </div>
                <div class='pillar-name'>
                    📊 Visibility Pillar
                </div>
            </div>
        </div>
    </div>

    <h2>🎯 Zero Trust Principles Implemented</h2>
    <div class='principles-grid'>
        <div class='principle-card'>
            <h3>🔑 Verify Explicitly</h3>
            <p>Always authenticate and authorize
            based on all available data points:
            identity, location, device, service,
            workload and data classification.</p>
        </div>
        <div class='principle-card'>
            <h3>🔒 Least Privilege Access</h3>
            <p>Limit user access with just-in-time
            and just-enough-access, risk-based
            adaptive policies and data protection
            against outside attack vectors.</p>
        </div>
        <div class='principle-card'>
            <h3>💥 Assume Breach</h3>
            <p>Minimize blast radius and segment
            access. Verify end-to-end encryption
            and use analytics to get visibility,
            drive threat detection and improve.</p>
        </div>
        <div class='principle-card'>
            <h3>🌐 Network Micro-segmentation</h3>
            <p>Deny all by default. Explicit allow
            only. Each workload in its own segment.
            No lateral movement possible without
            explicit permission.</p>
        </div>
        <div class='principle-card'>
            <h3>🔐 Data Encryption</h3>
            <p>Encrypt everything at rest and
            in transit. No public endpoints.
            All data access via private network
            only with full audit logging.</p>
        </div>
        <div class='principle-card'>
            <h3>📊 Continuous Monitoring</h3>
            <p>Monitor all traffic, all access,
            all changes. Sentinel + Defender for
            Cloud provide 360-degree visibility
            across all pillars 24/7.</p>
        </div>
    </div>

    <h2>✅ Controls Implemented</h2>
    <table>
        <tr>
            <th>Pillar</th>
            <th>Control</th>
            <th>Status</th>
            <th>ZT Principle</th>
        </tr>
        <tr>
            <td>Identity</td>
            <td>MFA for ALL users</td>
            <td><span class='badge-green'>✅ Active</span></td>
            <td>Verify Explicitly</td>
        </tr>
        <tr>
            <td>Identity</td>
            <td>Legacy Auth Blocked</td>
            <td><span class='badge-green'>✅ Blocked</span></td>
            <td>Verify Explicitly</td>
        </tr>
        <tr>
            <td>Identity</td>
            <td>High Risk Sign-ins Blocked</td>
            <td><span class='badge-green'>✅ Blocked</span></td>
            <td>Assume Breach</td>
        </tr>
        <tr>
            <td>Identity</td>
            <td>PIM — JIT Admin Access</td>
            <td><span class='badge-green'>✅ Configured</span></td>
            <td>Least Privilege</td>
        </tr>
        <tr>
            <td>Identity</td>
            <td>Device Compliance Required</td>
            <td><span class='badge-green'>✅ Active</span></td>
            <td>Verify Explicitly</td>
        </tr>
        <tr>
            <td>Network</td>
            <td>Micro-segmentation (5 segments)</td>
            <td><span class='badge-green'>✅ Active</span></td>
            <td>Assume Breach</td>
        </tr>
        <tr>
            <td>Network</td>
            <td>Deny-All NSG Rules</td>
            <td><span class='badge-green'>✅ Active</span></td>
            <td>Least Privilege</td>
        </tr>
        <tr>
            <td>Network</td>
            <td>No Public Endpoints</td>
            <td><span class='badge-green'>✅ Enforced</span></td>
            <td>Assume Breach</td>
        </tr>
        <tr>
            <td>Data</td>
            <td>Key Vault — Private Only</td>
            <td><span class='badge-green'>✅ Private</span></td>
            <td>Least Privilege</td>
        </tr>
        <tr>
            <td>Data</td>
            <td>Soft Delete + Purge Protection</td>
            <td><span class='badge-green'>✅ Enabled</span></td>
            <td>Assume Breach</td>
        </tr>
        <tr>
            <td>Data</td>
            <td>Private DNS Zones</td>
            <td><span class='badge-green'>✅ Active</span></td>
            <td>Verify Explicitly</td>
        </tr>
        <tr>
            <td>Visibility</td>
            <td>Microsoft Sentinel</td>
            <td><span class='badge-green'>✅ Active</span></td>
            <td>Assume Breach</td>
        </tr>
        <tr>
            <td>Visibility</td>
            <td>Defender for Cloud</td>
            <td><span class='badge-green'>✅ All Plans</span></td>
            <td>Assume Breach</td>
        </tr>
        <tr>
            <td>Visibility</td>
            <td>Centralized Log Analytics</td>
            <td><span class='badge-green'>✅ Active</span></td>
            <td>Assume Breach</td>
        </tr>
    </table>

    <footer>
        Zero Trust Implementation Report |
        Uzma Sami | AZ-104 | AZ-500 |
        $reportDate | UK South<br>
        Framework: NIST SP 800-207 Zero Trust Architecture
    </footer>
</div>
</body>
</html>
"@

$reportPath = ".\zt-report-$(Get-Date -Format 'yyyyMMdd').html"
$html | Out-File $reportPath -Encoding UTF8
Start-Process $reportPath

Write-Host "✅ Zero Trust report generated!" `
    -ForegroundColor Green

