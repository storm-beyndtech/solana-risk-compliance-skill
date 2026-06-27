# Compliant Token Design (Token-2022)

Help a builder design a token whose compliance posture is intentional, using the
Token-2022 (Token Extensions) program. The same extensions that enable compliance can
also build honeypots, so this sub-skill works in both directions: design compliant
issuance, and recognize when an extension is being used against holders (feeds back into
`token-risk.md`). For *how* to enumerate extensions on an existing mint, see
`onchain-data-layer.md` §4.

## Core idea

Token-2022 (program `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb`) adds opt-in
extensions configured at mint creation, TLV-encoded after the base mint account. Each
has a legitimate compliance use and a potential abuse. Always reason about **who holds
the authority** and **what they can do to a holder against their will**.

## Key extensions, their compliance meaning, and the abuse to screen for

- **Transfer Hook** — runs a custom program on every transfer. *Legitimate:* enforce
  allowlist/denylist, sanctions screening, jurisdiction gating at transfer time.
  *Abuse:* a hook that reverts on sells is a honeypot. **Always inspect the hook
  program** (its ID is in the extension state) — read what it actually does before
  judging.
- **Permanent Delegate** — a standing authority that can transfer or burn **any**
  holder's tokens. *Legitimate:* regulated issuers needing court-ordered clawback.
  *Abuse:* a rug/seizure primitive. If present and pointed at a non-protocol address,
  disclose loudly; in a screen it is a **confirmed** structural risk.
- **Default Account State (frozen)** — new token accounts start frozen until the issuer
  thaws them. *Legitimate:* KYC-gated assets where holders must be approved first.
  *Abuse:* selective freezing / non-sellable tokens.
- **Confidential Transfer** — encrypts balances/amounts while preserving auditability for
  permitted parties. *Legitimate:* privacy with regulator/auditor access. *Consideration:*
  reduces third-party transparency; **incompatible with Transfer Hook** (a hook needs to
  read amounts a confidential transfer hides) — plan sequencing, not simultaneity.
- **Transfer Fee** — a fee skimmed on transfer, withheld and harvestable by a config
  authority. *Legitimate:* protocol economics. *Abuse:* excessive or **mutable** fees
  that trap value — check the rate, the max, and who can change it.
- **Non-Transferable ("soulbound")** — tokens can't move after issuance. *Legitimate:*
  credentials, attestations, KYC badges. Note it: a "token" that can't be sold is not a
  market asset.
- **Interest-Bearing / Scaled UI Amount** — the displayed (UI) amount scales by a rate or
  multiplier while the raw amount is unchanged. *Legitimate:* rebasing/yield display.
  *Screen note:* UI amount ≠ raw balance — don't read economic weight off the scaled
  figure.
- **Mint Close Authority** — allows closing the mint account. Note who holds it.
- **Metadata / Metadata Pointer** — on-chain, verifiable token metadata (or a pointer to
  it). *Use it* — it reduces impersonation risk and is the clean alternative to mutable
  off-chain metadata.

## Designing a compliant token (workflow)

1. **Clarify the regulatory target first** (`regulatory.md`): security, stablecoin,
   utility token, KYC-gated RWA? The answer dictates which controls are appropriate —
   e.g. a payment stablecoin touching US persons now falls under the **GENIUS Act**
   permitted-issuer regime (see `regulatory.md`).
2. **Choose the *minimum* extensions** that meet the obligation. Every privileged
   authority is attack surface and a trust cost to holders.
3. **Decide authority custody explicitly** — who holds mint / freeze / permanent-delegate
   / transfer-fee-config / hook authority, and under what governance. Single-key control
   of seizure or freeze powers is a red flag even when well-intentioned (prefer
   multisig/threshold).
4. **Plan for disclosure** — holders should be able to discover, from on-chain metadata
   and docs, exactly what powers exist over their tokens.
5. **Plan authority retirement** — which authorities get renounced after launch, and when.
6. **Mind incompatibilities** — some extensions can't coexist (e.g. Confidential Transfer
   + Transfer Hook; Non-Transferable conflicts with anything assuming transfers). Decide
   the set up front; extensions are fixed at mint creation.

## Screening direction (the inverse)

When assessing someone else's Token-2022 mint, **enumerate every active extension**
(`onchain-data-layer.md` §4) and ask "what can the issuer do to a holder without
consent?" Surface permanent delegate, default-frozen state, and hostile transfer hooks
as **confirmed** structural risks in the `token-risk.md` verdict.

## Output

```
# Token design — compliance posture
- Regulatory target: <security / stablecoin / utility / RWA>
- Extensions chosen: <list, each with the obligation it satisfies>
- Authorities: <who holds what, governance, retirement plan>
- Incompatibilities resolved: <which pairs were avoided/sequenced and why>
- Holder-facing disclosures: <what holders can verify on-chain>
- Residual risks / trade-offs: <what powers remain and why>
Human sign-off required on: authority custody and any seizure/freeze powers.
```
