## Disclaimer

> [!IMPORTANT]
> This repository uses **Azure Verified Modules (AVM)** and is intended as a reference implementation.
> Any input values, defaults, and examples provided here are **samples only**.
>
> You are responsible for reviewing and adapting the configuration to meet your organization’s requirements (security, networking, naming, regions, compliance, etc.) before using it in any environment.

> [!NOTE]
> AVM modules may introduce changes over time (including breaking changes). The maintainers of this repository are not responsible for upstream module changes.
> For AVM-related bugs or feature requests, please raise issues with the relevant AVM module repository.

# msft-eslz-connectivity

## New (preferred) layout

This repo now supports a **single root Terraform configuration** driven entirely by environment-specific tfvars.

- `modules/`
	- `modules/vwan`: Virtual WAN (AVM)
	- `modules/fwpolicy`: Azure Firewall Policy + AKS egress baseline rules
	- `modules/vhub`: Virtual Hub (AVM) + optional secured hub Azure Firewall (AZFW_Hub)
- `environments/`
	- `environments/dev/backend.hcl` + `environments/dev/terraform.tfvars`
	- `environments/prod/backend.hcl` + `environments/prod/terraform.tfvars`

Key design points:
- All instances are **tfvars-driven** (`virtual_hubs` and `firewall_policies` are maps).
- vWAN is intended to be created **once** (typically in prod) and referenced from other envs.
- No subscription/tenant IDs are hardcoded in Terraform code; authentication is expected via Azure CLI / OIDC / `ARM_*` env vars.

Multi-subscription support:
- If your **hub resources** (vHub / Azure Firewall / Firewall Policy) and your **vWAN** live in different subscriptions, set:
	- `hub_subscription_id` / `hub_tenant_id`
	- `virtual_wan_subscription_id` / `virtual_wan_tenant_id` (optional; defaults to hub values)

Tip: keep IDs out of committed tfvars by passing them via environment variables, e.g. `TF_VAR_hub_subscription_id`.

Input conventions:
- Prefer **imports** over "create flags". If something already exists and you want Terraform to manage it, import it into the environment state.
- For migration/partial ownership:
	- Use `resource_groups` for RGs you want Terraform to manage.
	- Use `existing_resource_groups` for RGs you only want to data-lookup.
	- Use `virtual_wan` (managed) **or** `existing_virtual_wan` (lookup) — exactly one must be set.
	- Use `firewall_policies` for policies managed here; use `existing_firewall_policies` for lookup-only policies.

### How to run

From the repo root:

- Dev:
	- `terraform init -backend-config=environments/dev/backend.hcl`
	- `terraform plan -var-file=environments/dev/terraform.tfvars`
	- `terraform apply -var-file=environments/dev/terraform.tfvars`

- Prod:
	- `terraform init -backend-config=environments/prod/backend.hcl`
	- `terraform plan -var-file=environments/prod/terraform.tfvars`
	- `terraform apply -var-file=environments/prod/terraform.tfvars`

### State / migration notes

This refactor introduces **new state keys** under `msft-lz-connectivity/environments/{dev,prod}`.

If you already deployed resources using the legacy stack folders:
- Fastest path: **destroy legacy stacks**, then apply the new env configuration.
- No-downtime path: **import** existing resources into the new env state (requires careful mapping of resource IDs).

> Tip: the `resource_groups` input supports `create=false` so you can data-lookup existing RGs while migrating.

> Updated: the repo no longer uses `create=true/false`. Use `existing_resource_groups` (lookup) or import the RG into state if you want it managed.

## Legacy stack layout (kept for reference)

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

## Disclaimer

> [!IMPORTANT]
> This repository uses **Azure Verified Modules (AVM)** and is intended as a reference implementation.
> Any input values, defaults, and examples provided here are **samples only**.
>
> You are responsible for reviewing and adapting the configuration to meet your organization’s requirements (security, networking, naming, regions, compliance, etc.) before using it in any environment.

> [!NOTE]
> AVM modules may introduce changes over time (including breaking changes). The maintainers of this repository are not responsible for upstream module changes.
> For AVM-related bugs or feature requests, please raise issues with the relevant AVM module repository.

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
