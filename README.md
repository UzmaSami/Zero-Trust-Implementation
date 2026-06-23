#  Zero Trust Implementation
## Azure Zero Trust Architecture — NIST SP 800-207
## Archirecture
![Architecture](docs/architecture.png)

Architecting a NIST-Aligned Zero Trust Environment in Azure
By Uzma Sami (AZ-104, AZ-500) | May 2026

"Never trust, always verify." It is an industry mantra, but operationalizing it within a live cloud environment requires moving beyond buzzwords into strict, code-driven engineering.

This repository details my approach to building a fully automated, strictly governed Zero Trust Architecture in Microsoft Azure, aligned with the NIST SP 800-207 framework. This project isn't just about deploying resources; it's about shifting the paradigm from perimeter-based security to resource-centric, identity-driven micro-segmentation.

The Challenge: The Death of the Perimeter
In modern cloud environments, the traditional corporate network perimeter is obsolete. Threat actors no longer "break in"—they log in. During my threat modeling and architecture planning, I identified several critical vulnerabilities inherent in standard cloud deployments:

Standing Privileges: Administrators retaining 24/7 high-level access, expanding the blast radius of a compromised credential.

Flat Networks: Virtual networks that allow lateral movement by default, meaning a single compromised endpoint can pivot to critical databases.

Public-Facing PaaS: Data stores and secrets managers (like Azure Key Vault) exposed to the public internet, relying solely on access policies rather than network boundaries.

Fragmented Visibility: Telemetry scattered across multiple services, making it impossible to detect an active intrusion or map lateral movement in real-time.

The Solution: A Pillar-Based Zero Trust Deployment
To solve these challenges, I engineered a 7-phase automated PowerShell deployment that reconstructs the environment based on explicit verification, least privileged access, and an "assume breach" mentality.

Here is how the architecture systematically dismantles the challenges outlined above.

1. Identity: The New Perimeter
You cannot have Zero Trust without absolute confidence in the identity requesting access.

Conditional Access Enforcement: I deployed 5 strict Conditional Access policies to block legacy authentication, mandate MFA, assess sign-in risk, and enforce device compliance before granting access to the control plane.

Eradicating Standing Access: Utilizing Privileged Identity Management (PIM), all administrative roles are configured for time-bound, Just-In-Time (JIT) access requiring explicit approval.

2. Network: Default-Deny Micro-segmentation
I replaced the flat network concept with a highly segmented Virtual Network (vnet-zerotrust-uksouth).

Intentional Routing: Subnets are strictly divided by function (Identity, Workloads, Data, Management, Endpoints).

Zero Trust NSGs: Every subnet is bound by Network Security Groups operating on a strict "Deny All" default. Workloads can only communicate if an explicit rule is written and justified. Lateral movement is mathematically blocked by default.

3. Data: Securing the Crown Jewels
Data exfiltration often happens through misconfigured PaaS services.

Darkening the Key Vault: I provisioned an Azure Key Vault and completely disabled public network access.

Private Connectivity: Internal access is securely routed via Private Endpoints and localized Private DNS Zones. To prevent configuration drift, I engineered a secondary PowerShell loop script that continuously enforces the block on public access across all Key Vaults in the data resource group.

4. Visibility: Assuming Breach
Zero Trust requires assuming that the environment is already compromised.

Unified Telemetry: A centralized Log Analytics workspace (law-zt-uzmasami-2026) in uksouth acts as the brain of the operation.

Proactive Defense: Microsoft Sentinel and Microsoft Defender for Cloud are automatically enabled across all resource tiers (VMs, SQL, App Services, Key Vaults) with diagnostic logging bound directly to the central workspace for immediate threat hunting.

Continuous Verification: The Executive Dashboard
Security is only as good as its verifiability. I didn't just want to deploy this infrastructure; I needed to prove its efficacy.

Phases 6 and 7 of this project consist of a custom-built automated verification engine. The script evaluates the live Azure environment, queries the configurations of the identity, network, data, and visibility pillars, and calculates a Zero Trust Maturity Score (0-100%).

It then exports this data, generating a structured HTML Dashboard that maps the current implementation directly against the NIST SP 800-207 framework. This provides a tangible, executive-level view of our security posture.

💻 Technical Implementation & Deployment
For security engineers looking to replicate or review the automation, the deployment is structured sequentially.

Prerequisites
Active Microsoft Azure Subscription.

Global Administrator or Privileged Role Administrator rights (for PIM/Conditional Access).

Azure PowerShell module (Az).

Execution
Clone the repository and execute the phases sequentially. Ensure each script completes and validates before moving to the next pillar.

PowerShell
## 1. Authenticate
Connect-AzAccount
Set-AzContext -SubscriptionId "<Your-Subscription-ID>"

## 2. Deploy Foundation & Telemetry
.\Phase1-Foundation.ps1

## 3. Secure Identity (PIM & Conditional Access)
.\Phase2-Identity.ps1

## 4. Micro-segment Network
.\Phase3-Network.ps1

## 5. Lock Down Data (Private Link & Key Vault)
.\Phase4-Data.ps1

## 6. Enable Threat Protection
.\Phase5-Visibility.ps1

## 7. Generate NIST Compliance Dashboard
.\Phase6-7-VerificationAndReporting.ps1
