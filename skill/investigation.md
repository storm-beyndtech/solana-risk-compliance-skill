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

**Investigating an operator, not a single incident.** When the subject is a deployer or
wallet suspected of a *repeated* behavior (not one drain), the anchor is the operator's
full population of assets, not one example. Scoping to a single token and generalizing
from it is the most common way this method fails — a single specimen can be an outlier
in either direction, and it invites exactly the pushback that should have been designed
out: *"you checked one, what did the others do?"* Pull the operator's complete recent
mint/deployment list (`onchain-data-layer.md` §5) before forming a theory, and test the
theory against all of it, not the first or most striking case.

### 2. Verify the anchor facts

Independently confirm the basics **on-chain** before building any theory:
`getTransaction(sig, {maxSupportedTransactionVersion:0, jsonParsed})` to confirm the
transactions exist and the amounts/assets/instructions are what's claimed; check
timestamps and slots line up. **Cross-reference a second source** — Solscan, Solana
Explorer, or SolanaFM (`onchain-data-layer.md` §6). If a claimed fact doesn't verify,
that discrepancy is itself a finding.

**Check third-party labels before concluding.** Before asserting a wallet is unlabeled,
novel, or has "no history," check whether a public source (Solscan tags, a maintained
scam/exploit list, a community blocklist) already carries a label for it. A missing
label is itself worth stating explicitly ("no third-party tag found as of \<date\>") —
it means the finding is new, not that the wallet is clean.

**Treat a cached or pre-aggregated reputation metric as a hypothesis, not ground truth.**
A platform's own cached rollup (a "reputation score," a "% rugged" cohort stat, a
dashboard number) was computed by *someone's* methodology, on a schedule, against a
specific definition of the underlying event. All three of those can be wrong for your
question: the cache can be **stale** (refreshed hours or a day behind the chain), and the
underlying metric can be **measuring the wrong quantity** (e.g. a "rugged" classifier
keyed to trading *stopping* will silently miss a token that crashed 70%+ and is still
trading — price collapse and trade cessation are different events). When a cached metric
materially shapes the verdict, re-derive it from a live primary source
(`onchain-data-layer.md` §5–6) before relying on it, and say plainly when you didn't.

### 3. Establish the baseline

Reconstruct the normal state *before* the incident: balances, authorities, relationships.
Capture authority configurations **as they were** (mint/freeze/upgrade/permanent-delegate)
since they may change after — use a pre-incident slot via historical RPC, or the last
known-good transaction. You cannot characterize what changed without the starting point.

**This is a temporal baseline — a pattern claim also needs a comparative one.** "Before
vs. after" tells you what changed for *this* subject. It does not tell you whether the
after-state is unusual. A metric that looks damning in isolation (heavy sell volume, a
concentrated holder, a volatile price) can be the ecosystem norm — most speculative
Solana tokens see sell-dominant volume and sharp drawdowns regardless of who deployed
them. Before calling a pattern distinctive, pull a small control group of comparable,
unrelated subjects (other tokens graduated in the same window, other wallets of the same
type) and compute the same metric for them. If the control group shows the same range,
the pattern is not evidence of anything specific to the subject — say so, retract the
claim, and look for what *is* distinctive instead of what merely looks damning at first
glance.

### 4. Ask the four forensic questions

For the core event, answer each with evidence pulled from the tx graph:
- **What moved?** Which assets, how much, in which transactions (parse System + SPL
  transfers from `getTransaction` instructions + `meta.pre/postTokenBalances`).
- **Who controlled it?** Which authorities/signers enabled the movement — a live mint/
  freeze authority, a permanent delegate, an upgrade authority, a phished signer. **Check
  whether the subject traded its own asset**: does the deployer/operator wallet itself
  appear as a buyer or seller of the token it deployed (`onchain-data-layer.md` §5,
  filter the trade/transfer graph by the subject's own address as counterparty)? A
  self-buy immediately at launch followed by a full exit within seconds-to-minutes is a
  distinct, mechanically identifiable signature — cheap to check, and structurally
  different from (and missed by) LP-lock checks, honeypot simulation, and any
  aggregate reputation score keyed to *outcomes* rather than the operator's own trades.
  If the amount round-trips (tokens bought ≈ tokens sold) and repeats identically across
  multiple deployments by the same wallet, that repetition — not any single instance —
  is the finding; confirm on at least a handful of the operator's other deployments
  before naming it a pattern.
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

**A prior published conclusion about a comparable specimen is not settled — it's a
claim to re-verify with this method, not a fact to cite.** Aggregate reputation metrics
and small samples both go stale, and an earlier writeup may have stopped at whatever
depth was affordable at the time (e.g. "we scanned 2 of this operator's 49 outcomes" is
an honest sample, not a census). If this investigation touches a subject with an
existing public conclusion, re-run steps 2–4 against it rather than importing the old
verdict — either it holds up under fresh, fuller evidence and is now better-supported,
or it doesn't and needs correcting in the open.

**Retract mid-investigation, out loud, when evidence changes the picture.** The
comparative baseline in step 3 exists specifically to falsify a pattern claim that
looked solid before the control group was checked. When that happens, say plainly what
the earlier claim got wrong and why — don't quietly narrow the claim or bury the
correction. A visible retraction, followed by the narrower thing that *does* hold up, is
the credibility-building move; a report that never had to correct itself typically means
the comparative check was skipped, not that the first read was right.
