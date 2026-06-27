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

Re-run any command to verify. Evidence over assertion, on real chain state.
