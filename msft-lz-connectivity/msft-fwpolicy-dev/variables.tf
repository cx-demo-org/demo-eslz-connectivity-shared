variable "location" {
  description = "Azure region for the Firewall Policy."
  type        = string
  default     = "southeastasia"
}

variable "resource_group_name" {
  description = "Resource group containing the secured hub and firewall policy. In Option B we reuse the hub RG."
  type        = string
  default     = "msft-vhub-dev-rg"
}

variable "firewall_policy_name" {
  description = "Azure Firewall Policy name."
  type        = string
  default     = "msft-vhub-dev-firewall-policy"
}

variable "tags" {
  description = "Tags applied to the firewall policy."
  type        = map(string)
  default = {
    environment = "dev"
    workload    = "msft-fwpolicy"
  }
}

variable "admin_ssh_source_cidrs" {
  description = "Source CIDRs allowed to SSH (TCP/22) to resources behind the dev hub firewall. Set to your public IP in CIDR form, e.g. ['203.0.113.10/32']."
  type        = list(string)
  default     = []
}

variable "aks_egress_source_addresses" {
  description = "Source CIDRs for AKS node pools when using UDR egress (e.g., node subnet CIDR). Use ['*'] only for quick testing."
  type        = list(string)
  default     = ["*"]
}

variable "aks_egress_fqdns" {
  description = "FQDNs required for AKS + platform services (Defender/Monitoring) when routing egress via Azure Firewall."
  type        = list(string)
  default = [
    # AKS/Microsoft Container Registry (MCR)
    "mcr.microsoft.com",
    "*.data.mcr.microsoft.com",
    "*.blob.core.windows.net",

    # Azure Resource Manager + AAD (cluster operations)
    "management.azure.com",
    "login.microsoftonline.com",
    "graph.microsoft.com",

    # Monitoring / Log Analytics agent ingestion (wildcards kept broad; tighten if you pin workspace / region)
    "*.ods.opinsights.azure.com",
    "*.oms.opinsights.azure.com",
    "*.monitoring.azure.com",

    # Defender for Cloud (security agent/telemetry)
    "*.securitycenter.windows.com"
  ]
}

variable "aks_egress_network_allow" {
  description = "Network allow rules required for AKS node operation (DNS/NTP etc.)."
  type = object({
    dns_servers     = list(string)
    ntp_servers     = list(string)
    extra_tcp_fqdns = list(string)
  })
  default = {
    # DNS usually resolved via on-prem/central DNS; set explicitly if needed.
    dns_servers = ["*"]
    # NTP is required; default allows any. You can tighten to a specific NTP server set.
    ntp_servers = ["*"]
    # Optional: destinations you want as TCP/443 network rules rather than app rules.
    extra_tcp_fqdns = []
  }
}
