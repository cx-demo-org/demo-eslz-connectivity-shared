# msft-eslz-connectivity

This repository was previously organized under a top-level folder named `msft-lz-connectivity/`.

As part of a repo restructure, the connectivity stacks were moved to the repository root:

- `msft-vwan-prod/`
- `msft-fwpolicy-dev/`
- `msft-vhub-dev/`
- `msft-fwpolicy-prod/`
- `msft-vhub-prod/`

Remote state keys were intentionally kept unchanged (still prefixed with `msft-lz-connectivity/`) to avoid any state migration.

This folder contains the Terraform stacks that make up the **Connectivity Landing Zone** used in this repo.

The design goal is:
- Deploy **one shared Virtual WAN** (vWAN)
- Deploy **two secured hubs** (vHubs) in separate resource groups (prod + dev)
- Manage **Azure Firewall Policy** independently from the hubs ("Option B"), so policy changes don’t cause hub re-deployments

All stacks are configured with a **local backend** and store state files outside the repo under:

- `C:/LocalApps/GithubWorkspaces/cx-statestore/<stack>/terraform.tfstate`

> Note: This repo follows a “one stack = one folder = one state file” approach.

## Stack layout

### `msft-vwan-prod/`
Creates the shared Virtual WAN.

- Uses the AVM submodule: `Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-wan`
- Outputs:
  - `virtual_wan_id`

The hubs attach to this vWAN by looking it up directly with `data.azurerm_virtual_wan`.

### `msft-vhub-prod/`
Creates the **prod** secured virtual hub and Azure Firewall (Hub SKU).

- Uses the AVM submodule: `Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm//modules/virtual-hub`
- Creates:
  - Resource group (prod hub RG)
  - Virtual Hub
  - Azure Firewall (`AZFW_Hub`)
- Looks up existing resources:
  - Virtual WAN (`data.azurerm_virtual_wan`)
  - Firewall policy (`data.azurerm_firewall_policy`)

### `msft-vhub-dev/`
Same as prod hub stack, but for **dev**.

### `msft-fwpolicy-prod/`
Owns the **Azure Firewall Policy** for the prod hub.

- Creates:
  - `azurerm_firewall_policy`
  - Rule collection groups (RCGs)
    - `baseline` (placeholder, priority 1000)
    - `aks-egress` (priority 200): baseline AKS outbound rules for UDR egress

This stack outputs:
- `firewall_policy_id`

The prod hub stack attaches this policy via `azurerm_firewall.firewall_policy_id`.

### `msft-fwpolicy-dev/`
Same as prod firewall policy stack, but for **dev**.

## How the stacks connect

- `msft-vwan-prod` is deployed first.
- `msft-vhub-prod` and `msft-vhub-dev` look up the existing vWAN directly (no dependency on terraform remote state).
- Each hub looks up its firewall policy directly.

## Recommended workflow

1. Deploy vWAN:
   - `msft-vwan-prod/`
2. Deploy policies:
   - `msft-fwpolicy-prod/`
   - `msft-fwpolicy-dev/`
3. Deploy hubs:
   - `msft-vhub-prod/`
   - `msft-vhub-dev/`
4. Iterating on egress rules should normally only require changing/applying the `msft-fwpolicy-*` stacks.

## Notes / gotchas

- Defaults in the AKS egress rules currently use `"*"` for `source_addresses` to keep initial bring-up simple.
  - Before routing real AKS node egress through the firewall, tighten `aks_egress_source_addresses` to your AKS node subnet CIDR(s).
- On Windows with Git Bash, `terraform import` can sometimes mangle Azure resource IDs due to path conversion. If you need imports again, we can repeat the earlier workaround we used during the Option B migration.
