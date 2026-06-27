# Forensic Investigation

A disciplined method for investigating a scam, exploit, drain, or suspicious address on
Solana, and producing a defensible writeup. The discipline is what separates a real
investigation from speculation. Apply `rules/calibrated-language.md` throughout; pull
the graph with the methods in `onchain-data-layer.md` §5–6.

## The six-step method

### 1. Source and scope

Pin down exactly what is alleged and by whom. What is the claimed incident (drain, rug,
exploit, impersonation)? What is the primary on-chain anchor — the victim wallet, the
exploited program, the suspect token, or a specific transaction signature? Define the
time window (slots/timestamps). Do not widen scope until the core is established.

### 2. Verify the anchor facts

Independently confirm the basics **on-chain** before building any theory:
`getTransaction(sig, {maxSupportedTransactionVersion:0, jsonParsed})` to confirm the
transactions exist and the amounts/assets/instructions are what's claimed; check
timestamps and slots line up. **Cross-reference a second source** — Solscan, Solana
Explorer, or SolanaFM (`onchain-data-layer.md` §6). If a claimed fact doesn't verify,
that discrepancy is itself a finding.

### 3. Establish the baseline

Reconstruct the normal state *before* the incident: balances, authorities, relationships.
Capture authority configurations **as they were** (mint/freeze/upgrade/permanent-delegate)
since they may change after — use a pre-incident slot via historical RPC, or the last
known-good transaction. You cannot characterize what changed without the starting point.

### 4. Ask the four forensic questions

For the core event, answer each with evidence pulled from the tx graph:
- **What moved?** Which assets, how much, in which transactions (parse System + SPL
  transfers from `getTransaction` instructions + `meta.pre/postTokenBalances`).
- **Who controlled it?** Which authorities/signers enabled the movement — a live mint/
  freeze authority, a permanent delegate, an upgrade authority, a phished signer.
- **How was it possible?** The mechanism — an authority still live, a program flaw, a
  social-engineered signature, an oracle/price manipulation, a honeypot transfer hook.
- **Where did it go?** Trace outflow hop by hop (`getSignaturesForAddress` → next tx):
  swaps (DEX), bridges (by program ID), consolidation wallets, and CEX deposit
  addresses. Note where the trail goes cold and **why** (e.g. CEX off-ramp, cross-chain
  bridge, mixer). For a still-active drain, stream with **Yellowstone gRPC (Geyser)**
  rather than polling.

### 5. Apply calibrated language

Separate what you *observed* from what you *infer*. "The funds moved to X" (observed) is
different from "X is the attacker" (inference). Label every conclusion confirmed /
probable / possible. Wallet control is **not** proven identity — resist naming a culprit
beyond the evidence (`rules/calibrated-language.md`).

### 6. Structure the writeup

Publish in a fixed, skimmable structure so the reasoning is auditable:

```
# <Incident> — Forensic Findings
## Summary        (what happened, one paragraph, calibrated)
## Timeline       (slot/time-ordered, with tx signatures)
## Mechanism      (how it was possible — the four questions answered)
## Fund flow      (where value went; where the trail ends and why)
## Attribution    (only what evidence supports; label confidence explicitly)
## Open questions (what remains unverified and what would resolve it)
```

## Cross-skill calls

- Profiling the suspect/destination wallets → `wallet-counterparty-risk.md`.
- If the vehicle was a malicious token → `token-risk.md`.
- If findings imply sanctions or reporting duties → `regulatory.md`, then a human.

## Discipline

The fastest way to discredit an investigation is to over-claim. A narrow, evidenced,
calibrated report that says "trail ends at a Binance deposit address; identity not
determinable on-chain" is stronger and more useful than a confident accusation the
evidence can't carry. Hand attribution conclusions to a human before they are published
or acted on (`rules/human-in-the-loop.md`).
