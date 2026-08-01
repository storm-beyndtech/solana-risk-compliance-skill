# Worked Examples — Real On-Chain Reads

These are **real, reproducible** runs of the skill's first-principles method against live
Solana mainnet, using only **public, keyless infrastructure** (the public RPC and the
free DexScreener API) — no API key, and **not** the optional RugBurn engine. The point:
the methodology in `skill/onchain-data-layer.md` + `skill/token-risk.md` stands on its
own and produces verifiable facts.

> Captured 2026-06-27 against `https://api.mainnet-beta.solana.com`. On-chain values
> (supply, market, holders) change over time; re-run the commands to refresh. Every
> command below is copy-pasteable.

The examples also show the part that separates this from a naive rug-scanner: the **same
structural fact yields opposite verdicts depending on context**, and a check that can't
run is reported as *unknown*, never *clean* (`rules/calibrated-language.md`).

---

## Example 1 — BONK: clean structural config (real read)

```bash
curl -s https://api.mainnet-beta.solana.com -X POST -H "Content-Type: application/json" \
 -d '{"jsonrpc":"2.0","id":1,"method":"getAccountInfo",
      "params":["DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",{"encoding":"jsonParsed"}]}'
```
**Observed:**
```
program (owner): TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA   (classic SPL Token)
mintAuthority:   null      ← renounced; supply cannot be inflated
freezeAuthority: null      ← renounced; holders cannot be frozen
decimals:        5
```
Market (free DexScreener, largest pool):
```bash
curl -s "https://api.dexscreener.com/latest/dex/tokens/DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263"
```
```
Meteora pool · liquidity $107.5M · vol24h $20.0M · buys 69 / sells 46
VolumeChurn = 20.0M / 107.5M = 0.19x   (far below the ~50x wash threshold → no wash signal)
BuySellSym  = 1 - |69-46|/115 = 0.80   (two-sided, not the ~1.0 of self-trading)
```
**Verdict (token-risk.md):**
```
Verdict: LOW structural risk (medium confidence)
Confirmed: Mint & freeze authority both renounced (null) — no supply-inflation or
  freeze primitive. Classic SPL Token program (no Token-2022 extensions to abuse).
Confirmed: Deep liquidity ($107M), low VolumeChurn (0.19x), two-sided flow — no wash signal.
Unknown (not cleared): Full owner-graph not resolved in this keyless demo —
  getTokenLargestAccounts returned HTTP 429 (rate-limited) and true concentration needs a
  Helius DAS key to collapse token-accounts → owners. Reported as UNKNOWN, not "well
  distributed."
Next: "LOW" is not "safe" — it means no adverse structural/behavioral signal was
  observed in what we could read. Resolve holders via DAS before relying on distribution.
```
This is the honest shape: strong clean facts, **and** an explicit gap that lowers
confidence rather than being papered over.

---

## Example 2 — USDC: the calibration case (real read)

```bash
curl -s https://api.mainnet-beta.solana.com -X POST -H "Content-Type: application/json" \
 -d '{"jsonrpc":"2.0","id":1,"method":"getAccountInfo",
      "params":["EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",{"encoding":"jsonParsed"}]}'
```
**Observed:**
```
program (owner): TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
mintAuthority:   BJE5MMbqXjVwjAF7oxwPYXnTXDyspzZyt4vwenNw5ruG   ← PRESENT
freezeAuthority: 7dGbd2QZcCKcTndnHcTL8q7SMVXAkp688NTQYwrRCrar   ← PRESENT
decimals:        6
```
A naive scanner flags "active mint + freeze authority" as Critical. The skill does **not**:
```
Verdict: LOW risk — lawful stablecoin exception (high confidence)
Confirmed: Mint and freeze authority are present and controlled by Circle's issuance
  authorities. For a fixed-supply memecoin this would be a Critical dilution + honeypot
  flag; for a regulated, redeemable USD stablecoin, mint authority IS the product
  (issuance/redemption) and freeze authority is a required compliance control (sanctions).
Calibration: the verdict turns on WHAT THE TOKEN CLAIMS TO BE and WHO holds the
  authority — not the raw flag. (token-risk.md Layer 1 note; regulatory.md GENIUS Act.)
```
This is the discipline that keeps the skill out of "confident-but-wrong" territory.

---

## Example 3 — PYUSD: Token-2022 permanent delegate, in context (real read)

```bash
curl -s https://api.mainnet-beta.solana.com -X POST -H "Content-Type: application/json" \
 -d '{"jsonrpc":"2.0","id":1,"method":"getAccountInfo",
      "params":["2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo",{"encoding":"jsonParsed"}]}'
```
**Observed (Token-2022 — extensions enumerated):**
```
program (owner): TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb   (Token-2022)
extensions: mintCloseAuthority, permanentDelegate, transferFeeConfig,
            confidentialTransferMint, confidentialTransferFeeConfig, transferHook,
            metadataPointer, tokenMetadata
```
**The teaching point — same fact, opposite verdict by context:**
```
Verdict: structural risk = CONTEXT-DEPENDENT
- permanentDelegate is a STANDING authority to transfer/burn any holder's tokens.
  • On an anonymous memecoin → HARD ABORT: a seizure/rug primitive, no legitimate need.
  • On PYUSD (PayPal/Paxos regulated stablecoin) → the LAWFUL clawback control a
    regulated issuer needs for court orders/fraud reversal. Disclosed, expected, in policy.
- transferHook present → must inspect the hook program (compliance gating vs. honeypot);
  "has a hook" ≠ malicious.
- confidentialTransfer present → reduces third-party transparency; note it (and it is
  incompatible with transfer hooks in general — here both appear because the mint config
  scopes them; flag for a human to reconcile).
Calibration: enumerate every extension, then ask "what can the issuer do to a holder
  without consent, and is that lawful for THIS token's claimed purpose?" (token-2022-compliance.md)
```
A scanner that hard-aborts on `permanentDelegate` alone would wrongly condemn a regulated
stablecoin; one that ignores it would miss the #1 rug primitive on a memecoin. The skill
reads the fact **and** the context.

---

## Example 4 — Rug-capable configuration: the abort path (illustrative composite)

To show the abort path without accusing any named live project, this is a **labeled
illustrative composite** of the nine patterns as they co-occur in a real rug — the exact
facts the method would observe, written in calibrated language (observed configuration,
**not** a prediction of intent).

```
Observed (hypothetical mint, anon deployer):
  program:          Token-2022
  mintAuthority:    <deployer>            ← live supply tap
  extension:        permanentDelegate=<deployer>   ← seizure primitive (HARD ABORT)
  LP:               Raydium, unlocked, deployer-held, $180k   ← pullable (trapdoor)
  holders (DAS):    top owner 41% (fresh, unfunded, non-infra)  ← shadow whale
  deployer cohort:  6 prior mints, 4 abandoned (funding-cluster traced)  ← serial pattern
  market:           VolumeChurn 73x, BuySellSym 0.98           ← wash fingerprint

Verdict: CRITICAL — abort (high confidence)
Confirmed rug mechanics: permanentDelegate seizure primitive AND live mint authority AND
  pullable LP. Any one is disqualifying; together they are a rug-capable configuration.
Behavioral corroboration: 41% shadow concentration, serial-rugger funding cluster, 73x
  wash churn. Clean chart is irrelevant — the structure is the evidence.
Action: do not trust / do not list / do not route. (Auto-refuse is safe; a human is never
  asked to "approve" a permanent-delegate seizure primitive on an anon token.)
```

---

## Example 5 — Deployer self-trade extraction: what a graduation-rate check misses (labeled illustrative composite, real methodology)

Like Example 4, this is a **labeled illustrative composite** — not accusing any named
live project — but the mechanism, numbers, and query shape are real and reproducible
against Dune (`onchain-data-layer.md` §5); the specific wallet is withheld here per
`rules/human-in-the-loop.md` and published separately, with attribution, once a human
signed off on it.

**The setup:** a high-volume deployer (thousands of pump.fun mints, sub-1% graduation
rate) reads on every existing aggregate as harmless spam — zero honeypots, zero unlocked
LP, 0% "rugged" on a third-party cohort metric. A naive read stops there: low
graduation rate + no honeypot flags = spam bot, not a rugger.

**Step 1 (scope as an operator, not one token) + step 2 (verify, don't trust the
cache):** one graduated token was pulled for a first look and showed real signal — high
trade volume, a concentrated top holder, a sharp price drawdown, and the token had gone
completely silent hours ago (checked live against Dune's trade tape — the platform's own
cached "0% rugged" cohort stat was a day stale and never caught up to this specific
crash). Generalizing from that one token would have been the failure mode step 1 warns
about, so the check was widened to **all** of the operator's recent graduated mints.

**Step 3 (comparative baseline) — catches an overclaim:** every graduated mint showed
sell volume exceeding buy volume, some heavily. Read in isolation this looked like
proof of systematic extraction. A control group of 30 unrelated, arbitrary graduated
mints was pulled and showed the *same* range — from zero sells up to a 9x sell/buy skew
on tokens with no connection to this operator. Sell-dominant volume over a token's life
is normal pump.fun decay, not a distinguishing signal. **The volume-skew claim was
wrong and was retracted before being written up as a finding.**

**Step 4 (who controlled it — self-trade check) — the actual mechanism:** pulling the
deployer's own trades against its own mints (not just aggregate volume) showed something
the volume metric couldn't: on every graduated mint checked, the deployer bought a fixed
token amount in the same second as mint creation, then sold that exact amount back
across several transactions within 6–13 seconds, for more than it paid, every time.
Confirmed identical (own fixed signature amount, own timing band) across 17 of 17
mints checked for this operator, and separately confirmed as the same mechanism — a
different fixed signature — on a second, previously-published "spam bot" specimen (17/17
and 19/20 respectively). One instance would be a lucky early buyer; the same amount and
timing window repeating on every launch is a script.

```
Verdict: the "spam, not a rugger" read was incomplete — CRITICAL self-dealing mechanism
  (high confidence), not confirmed by any existing aggregate
Confirmed: deployer buys a fixed token amount at T+0s on every launch, exits the full
  amount within 6–13s, profits every time; repeats identically across the tested sample.
Retracted: raw sell>buy volume skew across the graduated cohort — falsified by a
  comparative baseline against unrelated tokens; not included in the finding.
Why every existing check missed it: not a honeypot (anyone can trade), not an
  LP-pull (pre-AMM bonding-curve token supply), not caught by graduation-rate or
  cohort-rug-% scoring (both are keyed to the token's eventual OUTCOME; this extraction
  is complete before the outcome is decided).
Next: name the pattern as a first-class signal (self-buy-then-exit within N seconds of
  the deployer's own mint, repeated across ≥3 deployments) rather than folding it into
  existing honeypot/LP-pull/graduation-rate checks, none of which are shaped to catch it.
```

---

## What these examples prove

1. **It runs keyless on real data.** Mint authorities, Token-2022 extensions, and market
   signals were all read live with public endpoints and no API key — exactly the path an
   autonomous agent uses (and the same calls run over QuickNode x402 for paid, keyless
   agent access; `onchain-data-layer.md` §0).
2. **It's calibrated, not naive.** USDC and PYUSD show the same structural flags that
   condemn a memecoin being correctly read as lawful in context. That judgment is the
   difference between risk intelligence and a flag-spitting scanner.
3. **Gaps stay honest.** The rate-limited holder read became an explicit *unknown* that
   lowered confidence — never a silent "clean."
4. **The optional engine only amplifies.** A RugBurn-compatible API would add calibrated
   behavioral scores, deployer-cohort reputation, and live invalidation — but every
   verdict above was reached without it.
5. **A pattern claim needs a control group, and self-trading needs its own check.**
   Example 5 shows the method catching its own overclaim (volume skew, falsified by a
   comparative baseline) while surfacing the finding that actually held up (a self-trade
   script invisible to every outcome-keyed metric) — the discipline in
   `investigation.md` §3–4 exists because both mistakes are easy to make from a single
   compelling specimen.

Re-run any command to verify. Evidence over assertion, on real chain state.
