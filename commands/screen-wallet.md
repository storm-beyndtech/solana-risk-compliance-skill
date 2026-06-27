---
name: screen-wallet
description: Screen a Solana wallet / counterparty / deployer for trust risk.
---

# /screen-wallet <address>

Run a counterparty risk screen. Load `skill/wallet-counterparty-risk.md`, trace
funding lineage, check sanctions/blocklist and mixer/bridge exposure, profile
behavior, and cluster related wallets. Return a calibrated verdict and the human
decision it defers to.
