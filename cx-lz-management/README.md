# cx-lz-management (AVM ALZ)


## What this is

This folder contains the **management baseline** landing zone configuration (Management Group hierarchy + policy/archetype wiring) built on the AVM pattern module:

- `Azure/avm-ptn-alz/azurerm`

It’s intended to live as **one folder in a larger repo** that will also hold other landing zone components over time.

## State / generated files

This repo is designed to be **safe to publish**. Do **not** commit Terraform state.

Recommended options:

- Use a local backend during development (configured via a local-only `backend.tf` that is not committed), or
- Use a secure remote backend (e.g., Azure Storage) for team use.

### Important constraint

The AVM ALZ module currently requires **Terraform CLI >= 1.12**.

Your current CLI was previously detected as 1.10.3, so `terraform init` will fail until Terraform is upgraded.

## Architecture

This stack mirrors the upstream AVM **`examples/default`** pattern:

- It uses a local library override in `./lib` (via the `alz` provider) so we can customize the architecture definition over time.
- It deploys the AVM **"alz"** architecture.

- `architecture_name = "alz"`
- `parent_resource_id` defaults to the current authenticated tenant id (deploy under tenant root) unless you explicitly set it.


## ⚠️ IMPORTANT: hardcoded IDs

This folder is currently configured to be **locally executable for this demo environment**, which means it includes **hardcoded tenant/subscription GUIDs** in files like:

- `providers.tf`
- `main.tf`

Before sharing this repo/folder outside the team (or with a customer), you should remove or parameterize those values.


## Running locally

1. Ensure Terraform CLI is **>= 1.12**.
2. Configure backend settings appropriately (local backend for dev, or remote backend for team use).
3. Run init/plan/apply from within this folder.

## Configuration (do not commit)

Create a `terraform.tfvars` file locally (and keep it out of git) to provide environment-specific values like subscription IDs:

- `tenant_id` (optional)
- `subscription_placement`

## Next steps

Once Terraform is upgraded, the intended rollout is:

1. Management groups (default ALZ architecture)
2. Policy assets + archetypes
3. Policy assignment modifications (enforcement, identity, non-compliance messages, overrides, selectors)
4. Policy role assignments (including "assign permissions" behavior)
5. Custom role definitions
