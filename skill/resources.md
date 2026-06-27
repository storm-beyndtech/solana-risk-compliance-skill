# Resources

Data sources, tooling, and integration notes for the compliance skill. Kept current to
the 2026 stack; stale references make a skill read as slop. The concrete *how* lives in
`onchain-data-layer.md` — this is the reference index.

## On-chain access

- **Keyed RPC (account/mint/tx state):** Helius, Triton, QuickNode. Needed for mint/freeze
  authority, holders, balances, transactions.
- **Keyless agentic RPC (autonomous agents):** **QuickNode x402** — `@quicknode/x402-solana`
  builds an RPC/WebSocket client from a Solana keypair, no API key, pay-per-request in
  USDC. Free tier 1M credits/mo per wallet; devnet-USDC testing; alpha (no SLA).
  Docs: https://www.quicknode.com/docs/build-with-ai/x402-payments · protocol:
  https://www.x402.org
- **DAS / token holders:** **Helius DAS** — `getTokenAccounts` (by mint → owners/holders,
  1000/page, paginate), `getAsset`, `getAssetsByOwner`, `searchAssets`; supports SPL +
  Token-2022 fungibles. https://www.helius.dev/docs/das-api
- **Geyser / gRPC streaming (real-time):** **Yellowstone gRPC** for live monitoring of
  transfers and program activity when an investigation needs the live edge.
- **Explorers (verification):** Solscan, Solana Explorer, SolanaFM — independently confirm
  anchor facts during investigations.
- **Token/market context (free):** DexScreener (https://docs.dexscreener.com),
  GeckoTerminal (https://www.geckoterminal.com/dex-api), Birdeye, Solana Tracker — for
  liquidity, holders, trade history, buys/sells, pair age. Treat third-party "risk
  scores" as inputs, not truth.

## Token standard references

- **Token-2022 / Token Extensions** docs (extension semantics, ExtensionType set):
  https://solana.com/docs/tokens/extensions · https://www.solana-program.com/docs/token-2022/extensions
- SPL Token program ID `Tokenkeg…`; Token-2022 program ID `TokenzQd…`.

## Compliance / sanctions references

- **OFAC SDN list** (including published crypto addresses) for sanctions screening.
- Reputable community blocklists for scam-linked addresses — always check provenance
  before treating a list entry as conclusive.
- KYT/intelligence vendors building agent suites in this lane (context, not dependency):
  Chainalysis, TRM Labs, Elliptic, Sardine, Range.

## Regulatory primary sources (route specifics to counsel)

- **US — GENIUS Act** (enacted Jul 18 2025; in implementation): Congress.gov S.1582;
  OCC/Treasury/FinCEN implementing rules (OCC NPRM, 2026).
- **EU — MiCA** (stablecoin titles in force since mid-2024): ESMA/EBA technical standards.
- **Nigeria — SEC Rules on Digital Assets; CBN guidelines** (IMTO, payment licensing);
  cNGN / Africa Stablecoin Consortium documentation.

## Optional RugBurn engine integration

This skill is **self-contained**; the methodology above stands alone. If a
RugBurn-compatible risk API is available it can *amplify* the first-principles checks
with calibrated behavioral scores, deployer-reputation lookups, and clustering.

- Configure an endpoint and key via env (e.g. `RUGBURN_API_URL`, `RUGBURN_API_KEY`);
  never hardcode secrets in the skill.
- When present, call it for deployer reputation and behavioral signals, then present
  results with the same evidence-led, calibrated discipline used everywhere else.
- When absent, fall back to the observable checks in each sub-skill. **The engine is an
  amplifier, never a dependency** — its absence never blocks the skill.

## A note on third-party scores

Any external score (including an engine's) is an input to your judgment, not a verdict to
parrot. Always be able to point to the underlying on-chain evidence, and label confidence
yourself per `rules/calibrated-language.md`.
