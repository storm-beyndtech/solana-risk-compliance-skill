# Wallet & Counterparty Risk Screening

Assess whether a wallet, deployer, or counterparty is safe to trust before you
integrate it, accept its funds, route to it, or list its asset. This is the
"know your transaction" (KYT) behavioral layer, distinct from token screening. For
*how* to pull the transaction graph, see `onchain-data-layer.md` §5.

## When to use

- Before accepting a deposit or partnership from an unknown wallet.
- Before integrating a protocol whose admin/treasury wallet you can identify.
- As part of investigating an incident (`investigation.md` calls back here).
- When a token screen (`token-risk.md`) surfaces a deployer worth profiling.

## What to observe (and how)

Build a picture from on-chain facts, then label confidence.

1. **Funding lineage.** `getSignaturesForAddress(addr)` → find the inbound SOL transfer
   that funded the wallet → recurse 1–3 hops upstream to the source. Funding from a
   mixer, a sanctioned address, or a known serial-rugger cluster is a strong adverse
   signal. A wallet whose *only* funding is one transfer from a fresh bridge withdrawal,
   minutes before a "partnership," behaves nothing like an established treasury.
2. **Sanctions / blocklist exposure.** Screen the address **and its close
   counterparties** against the **OFAC SDN** crypto-address list and reputable
   blocklists. Direct or one-hop exposure to a sanctioned address is a **hard flag** and
   a regulatory matter — route to `regulatory.md`. Always check the provenance of any
   community blocklist before treating an entry as conclusive.
3. **Mixer / bridge exposure.** Interaction with tumbler/mixer programs, or funds
   arriving fresh off a bridge with no prior history, raises laundering risk. Identify
   bridges and mixers by **program ID** against a maintained registry
   (`onchain-data-layer.md` §5) — "off a bridge" is rarely conclusive alone, but it
   resets the wallet's observable history to near-zero, which is itself a fact to state.
4. **Behavioral profile.** Age (first signature timestamp), transaction cadence, and
   counterparty diversity. Distinguish an established, diversified actor from a
   single-purpose wallet spun up for this interaction.
5. **Cluster membership.** Is this wallet one of many under common control — shared
   funding source, synchronized activity, common withdrawal target? Cluster the related
   set (`onchain-data-layer.md` §5) **before** judging any single address. Clustering
   shows *likely* common control, **not proven identity**.
6. **Outflow destinations.** Where does value leave to? Repeated outflows to
   abandoned-token deployers, scam-linked addresses, or a single consolidation wallet
   are telling. Note where outflows hit a CEX deposit address — the on-chain trail
   typically ends there.

## Producing a verdict

- **Block / do-not-trust** — Confirmed sanctions exposure, or direct serial-scam cluster
  membership. State the specific link and the hop distance.
- **High caution** — Mixer-funded with no legitimate history, or one-hop from a flagged
  address.
- **Review** — Thin or fresh profile; not adverse, but unproven. Say exactly what you'd
  want to see to clear it.
- **Clear (observed)** — Established, diverse, no adverse links found. Always note the
  limits of what you checked (hops traversed, lists used, anything unobserved).

## Discipline

Wallet attribution is **probabilistic**. Clustering heuristics group *likely* common
control, not proven identity. Never assert a real-world identity from on-chain data
alone, and never state sanctions/legal conclusions as settled — surface them as flags
for a human and, where relevant, licensed counsel (`rules/human-in-the-loop.md`,
`rules/calibrated-language.md`).

## Example

**Input:** "Someone wants to send 40 SOL to seed our pool — safe to accept? <addr>"

**Output (shape):**
```
Verdict: HIGH caution (medium confidence)
Confirmed: Wallet first signature 3 days ago; sole funding (52 SOL) arrived from a
  Wormhole withdrawal (bridge program ID matched) with no prior on-chain history.
Probable: One counterparty of the funder (one hop) appears on a community scam
  blocklist; list provenance unverified — worth confirming before relying on it.
Unobserved: No OFAC SDN match on the address or its direct counterparties (checked).
Regulatory: knowingly accepting funds one hop from a flagged source — see regulatory.md
  on AML / sanctions posture before proceeding.
Next: Don't accept blind. A human decides; request the sender's prior on-chain history
  or an alternative funding source to clear the flag.
```
