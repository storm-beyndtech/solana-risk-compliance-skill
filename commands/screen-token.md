---
name: screen-token
description: Screen a Solana token/mint for rug and manipulation risk.
---

# /screen-token <mint_address>

Run a full token risk screen. Load `skill/token-risk.md`, gather the observable
facts (mint/freeze authority, liquidity status, holder concentration, deployer
lineage, trading behavior), apply the nine-pattern checklist, and return a
calibrated verdict in the standard assessment shape. Defer the final call to the
user per `rules/human-in-the-loop.md`.
