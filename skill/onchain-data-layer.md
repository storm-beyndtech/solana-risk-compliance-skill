# On-Chain Data Layer (the infra every sub-skill stands on)

Every risk, compliance, and forensic claim in this skill must point to an **observable on-chain fact**. This file is *how you actually observe it* on the 2026 Solana stack — the concrete RPC methods, account layouts, DAS calls, streaming, and free data sources. The other sub-skills describe *what* to check and *how to judge it*; they call back here for *how to fetch it*.

Rule of the layer: **what you could not fetch is `unknown`, never `clean`.** A timed-out RPC call is "unobserved," not "renounced." Carry that distinction into every verdict (`rules/calibrated-language.md`).

---

## 0. Access: keyed RPC vs keyless agentic RPC (x402)

Two ways to reach Solana data. Pick by whether a human or an autonomous agent is running.

**Keyed RPC (human/server):** any reliable provider — Helius, Triton, QuickNode. Standard JSON-RPC over an API key. Use for interactive screens and back-end services.

**Keyless agentic RPC — QuickNode x402 (autonomous agents):** an agent should not be blocked on a human pasting an API key. The [x402 protocol](https://www.x402.org) (the dormant `HTTP 402 Payment Required` code, standardized by Coinbase) lets a client pay per request from its own wallet instead of holding a provisioned secret. QuickNode's `@quicknode/x402-solana` builds an x402-enabled RPC/WebSocket client **directly from a Solana keypair — no account, no API key, just a USDC-funded wallet**.

```ts
// Keyless Solana RPC from a keypair — the agent pays per call in USDC.
import { createX402SolanaClient } from "@quicknode/x402-solana"; // verify current API
const rpc = createX402SolanaClient({ keypair, network: "mainnet" });
const mint = await rpc.getAccountInfo(MINT, { encoding: "jsonParsed" }).send();
```

- **Free tier:** 1,000,000 API credits / month per wallet (1 RPC request = 1 credit); test free on devnet USDC.
- **Status (2026):** alpha — functional, but no production SLA, and the client API is still moving (treat the snippet as illustrative; verify against current `@quicknode/x402-solana` docs).

**Default:** a **keyed RPC** (Helius/Triton/QuickNode) is the right default for interactive
screens and production services. **x402 is the keyless *option* for autonomous agents** —
when no human is present to provision a key, it lets the agent self-fund per call; given
its alpha status, gate it behind a configured spend cap and fall back to a keyed endpoint
for anything uptime-critical.

> Whichever access you use, the *methods* below are identical — x402 just changes the auth, not the JSON-RPC surface.

---

## 1. Mint state — authorities, supply, decimals (patterns 1, 2, 9)

The fastest, highest-signal read. Fetch the mint account parsed.

```ts
// getAccountInfo with jsonParsed decodes the SPL Mint for you.
const r = await rpc.getAccountInfo(MINT, { encoding: "jsonParsed" }).send();
const info = r.value?.data?.parsed?.info;        // { mintAuthority, freezeAuthority, supply, decimals, isInitialized }
const owner = r.value?.owner;                    // program owner — SPL Token vs Token-2022 (see §4)
```

Read directly:
- `mintAuthority` — if non-`null`, supply can be inflated at will (**confirmed** dilution risk). `null` = renounced.
- `freezeAuthority` — if non-`null`, the issuer can freeze holder token accounts (the Solana honeypot primitive).
- `owner` — `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA` = classic SPL Token; `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb` = **Token-2022** → enumerate extensions (§4) before trusting it.

`MintStateKnown = false` if the call failed → report "unresolved," not "revoked."

---

## 2. Holders — the real owner graph (patterns 4, 6)

Naive tools read `getTokenLargestAccounts` (top-20 **token accounts**) — which operators game by splitting one position across many accounts. You want **owners**, deduped, infra excluded.

```ts
// Helius DAS: page every token account for the mint, collapse to owners.
// POST https://mainnet.helius-rpc.com/?api-key=...  (or keyless via x402)
{ "jsonrpc":"2.0","id":"h","method":"getTokenAccounts",
  "params": { "mint": MINT, "limit": 1000, "cursor": <next> } }   // paginate until empty
```

1. Page all token accounts (1000/page; follow the cursor). DAS covers SPL **and** Token-2022 fungibles.
2. Group by `owner`, sum balances → true per-owner share.
3. **Exclude infra owners before measuring concentration** — AMM pool vaults, CEX cold wallets, protocol PDAs, bridge accounts (see §5 registries). Including the Raydium vault makes every token look "concentrated."
4. Compute largest-owner %, top-10 %, and a dispersion measure (HHI).

Fallbacks: no DAS key → `getTokenLargestAccounts` gives the top-20 token accounts only → mark `HolderDistribution = partial`; never report "well distributed" from a sample. (`getProgramAccounts` on the token program with a mint filter also enumerates accounts but is heavier.)

---

## 3. Liquidity & market — is the liquidity real, and pullable? (patterns 3, 7)

Liquidity authenticity is part on-chain (the pool + LP token custody) and part market data.

- **Pools / LP custody:** identify the AMM pool (Raydium, Orca Whirlpools, Meteora), the LP mint, and **who holds the LP tokens** — burned (to incinerator), locked (in a known locker PDA, with an unlock time), or held by the deployer (pullable → classic rug). Read via `getAccountInfo`/`getProgramAccounts` on the pool program, or a market API for the convenience layer.
- **Market context (free, no key):** [DexScreener](https://docs.dexscreener.com), [GeckoTerminal](https://www.geckoterminal.com/dex-api), Birdeye, Solana Tracker — price, liquidity USD, 24h volume, **buys/sells counts**, pair age, number of markets. Use **two** independent sources for anything you weight heavily.
- **Three states, never conflated:** LP **locked/burned** (commitment) · LP **unlocked & deployer-held** (trapdoor) · **no DEX LP yet** (bonding-curve / pre-graduation — *unconfirmed*, cap don't clear). Treat "couldn't resolve the AMM" as `LPStatus = unknown`, not "locked."

**Wash / churn computation** (pattern 7), from market data:
```
VolumeChurn  = volume(window) / liquidityUSD           // > ~50x ⇒ capital cycling, wash signal
BuySellSym   = 1 - |buys - sells| / (buys + sells)     // → 1.0 ⇒ unnaturally two-sided (self-trading)
```
Churn alone can be real volatility; churn **and** high symmetry **and** few unique counterparties is a wash fingerprint.

---

## 4. Token-2022 extensions — enumerate before trusting (patterns 2, 9; design in `token-2022-compliance.md`)

If the mint's program owner is Token-2022, the risk lives in its **extensions** (TLV-encoded after the base mint).

```ts
// jsonParsed surfaces extensions; or decode TLV with @solana/spl-token getMintExtensions.
const ext = info?.extensions; // e.g. [{ extension: "permanentDelegate", state: { delegate } },
                              //        { extension: "transferHook", state: { programId, authority } },
                              //        { extension: "transferFeeConfig", ... },
                              //        { extension: "defaultAccountState", state: { accountState: "frozen" } }, ...]
```

What to surface (full semantics in `token-2022-compliance.md`):
- **`permanentDelegate`** set to a non-protocol address → standing authority to transfer/burn **any** holder's tokens. Seizure primitive — **confirmed** structural risk.
- **`transferHook`** → inspect the hook program; a hook that reverts on sells is a honeypot. "Has a hook" ≠ malicious — read what it does.
- **`defaultAccountState: frozen`** → new accounts start frozen (KYC-gating, or selective non-sellability).
- **`transferFeeConfig`** → fee on transfer; check rate and whether it's mutable / capped.
- **`confidentialTransfer`** → amounts encrypted; reduces third-party transparency (note in screens; incompatible with transfer hooks).

`ExtensionsKnown = false` if you couldn't decode → say so; don't assume "none."

---

## 5. Transaction graph — funding lineage, clustering, fund flow (wallet & investigation)

The behavioral layer. Walk SOL/token movement around a wallet.

```ts
const sigs = await rpc.getSignaturesForAddress(ADDR, { limit: 1000 }).send(); // newest-first, paginate w/ before
const tx   = await rpc.getTransaction(sig, { maxSupportedTransactionVersion: 0, encoding: "jsonParsed" }).send();
// Parse System transfers (SOL in/out) and SPL transfers from tx.transaction.message.instructions + meta.
```

Primitives the sub-skills reuse:
- **Funding lineage** — for a wallet, find the inbound SOL transfer that funded it; recurse 1–3 hops upstream to the source. Many "independent" early buyers sharing one funder, funded minutes before launch = a sybil/sniper ring.
- **Clustering** — group wallets by shared funder, synchronized activity, or common withdrawal target. Heuristic = *likely* common control, **not** proven identity.
- **Fund flow** (investigations) — trace outflow hop by hop; note swaps (DEX), bridges, and CEX deposit addresses where the trail goes cold.

**Real-time edge:** for live monitoring (an active drain, launch sniping), use **Yellowstone gRPC (Geyser)** to stream account/transaction updates instead of polling — sub-second, far cheaper than tight `getSignaturesForAddress` loops.

**Known-entity registries (for exclusion & attribution).** An address being a *bridge*,
*CEX*, *AMM vault*, or *mixer* changes its meaning entirely, so label before you judge.
Concrete sources (free first, then commercial):
- **Sanctions:** OFAC SDN list with published crypto addresses — `treasury.gov` /
  `sanctionslist.ofac.treas.gov` (downloadable; the authoritative source). Mirror it locally.
- **Address labels (free):** **SolanaFM** account labels, **Solscan** account tags/labels,
  and **Arkham Intelligence** entity labels — for CEX deposit wallets, bridges, and
  protocol treasuries. Cross-check; no single labeler is complete.
- **Program IDs (deterministic, maintain a local allow/exclude map):** AMM pools
  (Raydium, Orca Whirlpools, Meteora), bridges (Wormhole, deBridge, Allbridge), and the
  incinerator/burn address `1nc1nerator11111111111111111111111111111111`. These are
  fixed program/account IDs — hardcode them; they don't need a labeler.
- **Commercial intelligence (deeper coverage):** Chainalysis, TRM Labs, Elliptic, Range —
  attribution/cluster data when a case warrants it.
- **Community scam blocklists:** useful but **verify provenance** before treating an entry
  as conclusive (`wallet-counterparty-risk.md`).

> A label is an *input*, not a verdict — and "unlabeled" means *unknown*, not *safe*.
> Treat any labeled fact you can't independently corroborate as `probable`, not `confirmed`.

---

## 6. Independent verification (investigations)

Never build a theory on one source. Cross-confirm anchor facts on an explorer — [Solscan](https://solscan.io), [Solana Explorer](https://explorer.solana.com), [SolanaFM](https://solana.fm) — slots, timestamps, amounts, program IDs. If a claimed fact doesn't verify on a second source, that discrepancy is itself a finding.

---

## Quick reference — fact → method → source

| Fact you need | Method / source | Sub-skill |
|---|---|---|
| Mint / freeze authority, supply | `getAccountInfo(jsonParsed)` on mint | token-risk, investigation |
| Token-2022 extensions | parsed `extensions` / TLV decode | token-2022-compliance, token-risk |
| Real holder owner-graph | Helius DAS `getTokenAccounts` (paginate→owners) | token-risk |
| Top-20 fallback | `getTokenLargestAccounts` | token-risk (partial) |
| Liquidity, volume, buys/sells, pair age | DexScreener + GeckoTerminal (free) | token-risk |
| LP custody / lock | pool program accounts / market API | token-risk |
| Funding lineage, clustering, fund flow | `getSignaturesForAddress` + `getTransaction` | wallet, investigation |
| Live monitoring | Yellowstone gRPC (Geyser) | investigation |
| Sanctions / infra labels | OFAC SDN + entity registries | wallet, regulatory |
| Anchor verification | Solscan / Explorer / SolanaFM | investigation |
| Keyless agent access | QuickNode x402 (`@quicknode/x402-solana`) | all (autonomous) |

Optional amplifier (never a dependency): a RugBurn-compatible risk API for calibrated behavioral scores, deployer reputation, and clustering — see `resources.md`. Present its output with the same evidence-led, calibrated discipline; always be able to point to the underlying on-chain fact yourself.
