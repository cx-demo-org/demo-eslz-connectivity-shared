# CX Connectivity Virtual WAN Demo

This configuration provisions an Azure Virtual WAN and a single hub in the connectivity subscription `2f69b2b1-5fe0-487d-8c82-52f5edeb454e` by wrapping the [Azure Verified Module for ALZ Virtual WAN connectivity](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm/latest).

## Prerequisites

- Terraform 1.9+
- An existing resource group that will host the Virtual WAN and hub resources
- Appropriate permissions in the connectivity subscription
- Persistent local backend path `C:/LocalApps/GithubWorkspaces/cx-statestore/msft-vwan-prod/terraform.tfstate`

## Usage

1. Adjust `variables.tf` or provide overrides in a `terraform.tfvars` file. By default the deployment targets `cx-demo-connectivity-rg`; update `resource_group_name` if your environment uses a different resource group.
2. Initialize the workspace:
   ```bash
   terraform init
   ```
3. Review the plan:
   ```bash
   terraform plan
   ```
4. Apply the deployment:
   ```bash
   terraform apply
   ```

Optional booleans such as `deploy_firewall` or `deploy_bastion` can be toggled to bring additional connectivity components online in the hub.
