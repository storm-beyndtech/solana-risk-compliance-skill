# Token Risk Screening

Score a Solana token/mint for rug-pull and manipulation risk. The goal is a
calibrated verdict backed by **observable evidence**, not a yes/no guess. For *how*
to fetch each fact (RPC methods, DAS, market APIs), see `onchain-data-layer.md`; this
file is *what to check and how to judge it*.

## Method

Work in two layers. Structural checks are necessary but not sufficient — a token can
pass every static check and still be run by a predatory operator. Always combine both
layers and weight behavioral signals heavily.

### Layer 1 — Structural (the token's configuration)

Observe these from the mint account and associated state. Each is a fact you can point
to (`onchain-data-layer.md` §1–4).

1. **Mint authority** — `getAccountInfo(mint, jsonParsed)` → `info.mintAuthority`. Non-
   `null` ⇒ supply can be inflated at will (**confirmed** dilution risk). `null` ⇒
   renounced. Report the actual address/state, and whether the read succeeded.
2. **Freeze authority** — `info.freezeAuthority`. Non-`null` ⇒ issuer can freeze holder
   accounts, including blocking sells (the Solana honeypot equivalent). **Check the
   program owner too**: a Token-2022 mint shifts the nuance to its extensions (§4 /
   `token-2022-compliance.md`).
3. **Token-2022 extensions** (if owner is the Token-2022 program) — enumerate them
   (`info.extensions`). Surface as **confirmed** structural risk: `permanentDelegate`
   to a non-protocol address (seizure of any holder's tokens), `defaultAccountState:
   frozen`, and a `transferHook` whose program reverts on sells. Read what the hook
   *does* — "has a hook" alone is not malicious.
4. **Liquidity status** — identify the pool (Raydium/Orca/Meteora), the LP mint, and
   **who holds the LP tokens**: burned (incinerator), locked (locker PDA + unlock
   time), or deployer-held (pullable → classic rug). Distinguish "LP unlocked",
   "LP locked", and "no DEX LP yet" (bonding-curve, *unconfirmed* — cap, don't clear).
5. **Holder concentration** — the **real owner graph**, not top-20 token accounts.
   Helius DAS `getTokenAccounts` → collapse to owners → exclude infra (AMM vaults, CEX,
   PDAs, bridges) → largest-owner % and top-10 %. A handful of non-infra wallets holding
   the float = coordinated-dump risk. Distinguish genuine holders from the deployer's
   own clustered wallets (Layer 2).
6. **Supply vs. circulating** — large undistributed allocations controlled by one party
   are an overhang; note locks/vesting if any.

### Layer 2 — Behavioral (the operator and the flow)

This is where real edge lives. Static config lies; behavior is harder to fake. Computed
from the transaction graph and market data (`onchain-data-layer.md` §3, §5).

7. **Deployer reputation** — has this deployer, or wallets funded by the same source,
   launched-and-abandoned tokens before? Trace the deployer wallet's **funding lineage**
   (`getSignaturesForAddress` → inbound funder, recurse 1–3 hops). A serial rugger with a
   fresh clean contract is still high risk. **Resolve the true deployer first** — a
   launchpad authority PDA (e.g. pump.fun's mint-authority account) is not a person;
   don't pool unrelated tokens into a fake track record.
8. **Coordinated / sybil launch** — many fresh wallets funded from one source acquiring
   at launch is sybil setup, not organic demand. Cluster early buyers by shared funder
   and funding-time proximity to launch.
9. **Liquidity authenticity (wash)** — compute `VolumeChurn = volume / liquidityUSD`
   (> ~50x ⇒ capital cycling) and `BuySellSym = 1 - |buys-sells|/(buys+sells)` (→1.0 ⇒
   unnaturally two-sided). Look at **counterparties**, not just volume totals. Churn +
   high symmetry + few unique counterparties = wash.
10. **Sell-side friction (honeypot)** — can a normal holder actually sell? Authority-
    based blocks, default-frozen accounts, or a transfer hook that reverts on sale are
    honeypot tells. Where possible, confirm by simulating/observing a real sell path.

## The nine-pattern checklist (apply all, each labeled with confidence)

A token's risk is the union of these patterns:

1. Inflatable supply (mint authority live)
2. Freezable / non-sellable holders (freeze authority, default-frozen, or hostile transfer hook)
3. Pullable liquidity (LP unlocked + deployer-controlled)
4. Concentrated supply (top *owners* can dump the float)
5. Serial-rugger deployer (abandonment history on linked/funding-cluster wallets)
6. Sybil launch (coordinated fresh-wallet acquisition)
7. Wash-traded volume (churn + symmetry between related parties)
8. Honeypot mechanics (buys succeed, sells fail)
9. Seizure / hidden admin (permanent delegate, mutable program, privileged authority)

## Scoring

Translate findings into a calibrated verdict, not a false-precision number
(`rules/calibrated-language.md`):

- **Critical** — One or more *confirmed* rug mechanics present (live mint authority,
  pullable LP, working honeypot, permanent delegate to a non-protocol address). State
  the mechanism plainly.
- **High** — Confirmed structural risk *plus* an adverse behavioral signal (e.g.
  concentrated supply + serial-rugger / funding-cluster deployer).
- **Elevated** — Probable concerns, no confirmed mechanic; specify exactly what would
  confirm them.
- **Low** — Clean structural config and no adverse behavioral signal *observed*. "Low"
  is **not** "safe" — state what you could and could not observe, and which `…Known`
  checks were partial (e.g. holders sampled, AMM unresolved).

## Example

**Input:** "Is this token safe? <mint>"

**Output (shape):**
```
Verdict: HIGH risk (high confidence)
Confirmed: Mint authority still set to <addr> (getAccountInfo) — supply can be inflated.
Confirmed: Real owner graph (DAS, infra-excluded) — top 5 owners hold 71%; 4 were
  funded by the deployer's funding wallet <addr> within the same hour (clustered, not
  organic).
Probable: VolumeChurn 73x with buy/sell symmetry 0.98 in the first 2h between those
  wallets — likely wash. Counterparty set is tiny.
Unobserved: LP lock unresolved (pool program not decoded) — treated as unknown, not safe.
Regulatory: none for a risk read; if you plan to list/route this asset see regulatory.md.
Next: Do not treat distribution as organic. A human decides on listing; re-screen if
  mint authority is renounced and LP is verifiably locked.
```

Never answer "is it safe" with a bare yes/no. Give the **mechanism**, the **evidence**
(with the method that observed it), the **confidence**, and defer the final call to a
human per `rules/human-in-the-loop.md`.
