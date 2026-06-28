# Solana On-Chain Risk & Compliance Intelligence

**An agentic on-chain risk & compliance team for Solana builders — as a Claude Code / Codex skill.**

> Screen any token or wallet, gate a launch against real regulation, and run a forensic
> investigation — every finding tied to an observable on-chain fact, under human-in-the-loop
> oversight. Boots keyless on free infra. MIT. Built to slot into the [Solana AI Kit](https://github.com/solanabr/solana-ai-kit).

---

Most teams shipping on Solana have **no compliance function**. They launch tokens, accept
deposits, integrate counterparties, and route value with no one screening for fraud, no one
checking regulatory exposure, and no disciplined way to investigate when something goes
wrong. The fraud & compliance leaders (Sardine, Elliptic, TRM) now ship *suites of intelligent
agents* for exactly this. **This skill brings that pattern to the builder — on Solana, open source.**

It turns a coding agent into a three-person risk team:

| Role | What it does |
|---|---|
| 🛡️ **Risk Analyst** | Screens tokens & wallets for rug, manipulation, honeypot, and counterparty risk — behavioral, not just static config. |
| ⚖️ **Compliance Architect** | Triages securities / AML / Travel Rule exposure and jurisdictional regimes (US GENIUS Act, EU MiCA, Nigeria SEC/CBN, cNGN), and designs compliant Token-2022 issuance. |
| 🔍 **Investigator** | Runs a disciplined six-step forensic method on scams, exploits, and drains — fund-flow tracing, clustering, sanctions screening. |

…all under explicit **human-in-the-loop oversight** with **calibrated-language** discipline
(confirmed / probable / possible), so it stays advisory infrastructure — not the
confident-but-wrong "AI slop" the ecosystem is drowning in.

```
┌──────────────────────────────────────────────────────────────────────┐
│              solana-risk-compliance  (Claude Code skill)               │
│                                                                        │
│   SKILL.md  ─ router / progressive disclosure ─┐                       │
│                                                ▼                       │
│   ┌─────────────┬──────────────────┬─────────────────┬─────────────┐  │
│   │ token-risk  │ wallet/counter-  │  regulatory     │investigation│  │
│   │ (9 patterns)│ party (KYT)      │ (securities/AML)│ (forensics) │  │
│   └─────────────┴──────────────────┴─────────────────┴─────────────┘  │
│   ┌─────────────────────────────┐  ┌──────────────────────────────┐   │
│   │ token-2022-compliance       │  │ rules: human-in-the-loop +   │   │
│   │ (compliant issuance design) │  │        calibrated-language   │   │
│   └─────────────────────────────┘  └──────────────────────────────┘   │
│                         │ every claim grounds on ▼                     │
│   ┌────────────────────────────────────────────────────────────────┐  │
│   │ onchain-data-layer  — HOW to fetch any fact on the 2026 stack:  │  │
│   │ RPC · Helius DAS · Token-2022 TLV · sim-sell honeypot probe ·   │  │
│   │ fund-flow tracing · Yellowstone gRPC · keyless QuickNode x402   │  │
│   └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
                 │ optional amplifier (never required) ▼
        RugBurn-compatible risk API — behavioral scores, deployer reputation
```

> **Extends** [solana-dev-skill](https://github.com/solana-foundation/solana-dev-skill) —
> an addon for the compliance / risk / forensics layer; core program & frontend work is delegated.

## See it work (real, keyless, reproducible)

[**EXAMPLES.md**](EXAMPLES.md) runs the method against **live mainnet** with public RPC + free
DexScreener — no API key, no engine:

| Token | What the read shows | Why it matters |
|---|---|---|
| **BONK** | `mintAuthority: null`, `freezeAuthority: null`, churn `0.19×` | clean structural config — and the holder gap honestly marked *unknown* (a real `429`) |
| **USDC** | mint + freeze authority **present** | a naive scanner screams "Critical"; the skill reads the lawful stablecoin exception |
| **PYUSD** | Token-2022 with **`permanentDelegate` + `transferHook`** | the *same* fact is a hard-abort on an anon memecoin but lawful clawback for a regulated issuer — **context decides** |

That calibration — reading the fact **and** its context — is what separates risk intelligence
from a flag-spitting scanner.

## What it catches & does

**Token risk (9 manipulation patterns + honeypot):**
mint authority live · freeze authority armed · **permanent-delegate seizure** · supply
concentration / shadow whales · wash trading & volume churn · unlocked / deployer-held LP ·
bonding-curve graduation exit · sudden LP removal · serial-rugger deployer cohorts ·
**honeypot sellability** (proven by a simulated sell, not guessed).

**Wallet & counterparty (KYT):**
sanctions screening (OFAC SDN) · mixer / bridge / scam exposure · funding-lineage &
cluster analysis · deployer profiling — before you accept funds or integrate.

**Regulatory triage:**
securities / Howey · AML / Bank Secrecy Act / MSB · Travel Rule · stablecoin regimes
(US GENIUS Act) · EU MiCA · Nigeria SEC/CBN & cNGN — obligations surfaced before launch.

**Forensic investigation:**
six-step method · hop-by-hop fund-flow tracing to CEX/bridge off-ramps · wallet clustering ·
point-in-time reconstruction from transaction history · evidence-led, auditable writeups.

**Compliant issuance:**
Token-2022 extension design (permanent delegate, transfer hook, default-frozen, transfer fee,
confidential transfer, metadata) for KYC-gated / regulated tokens — the right control for the goal.

## Sub-skills (progressive disclosure)

Loaded only when the task needs them — token-efficient by design.

| Sub-skill | Purpose | Key methods |
|---|---|---|
| `skill/onchain-data-layer.md` | **How to fetch any fact** on the 2026 stack | `getAccountInfo`, Helius DAS, Token-2022 TLV, `simulateTransaction`, `getSignaturesForAddress`, Yellowstone gRPC, x402 |
| `skill/token-risk.md` | Rug & manipulation screening | authorities, holder graph, LP custody, wash math, honeypot probe |
| `skill/wallet-counterparty-risk.md` | KYT-style wallet vetting | sanctions, exposure, funding lineage, clustering |
| `skill/regulatory.md` | Securities / AML / Travel Rule + US/EU/NG regimes | obligation triage, jurisdiction routing |
| `skill/investigation.md` | Six-step forensic method | fund-flow tracing, clustering, attribution |
| `skill/token-2022-compliance.md` | Compliant issuance with Token Extensions | extension selection & risk |
| `skill/resources.md` | Data sources, tooling, optional engine | provider links |

## Agents

Spawn a specialist for multi-step work; each composes several sub-skills under one role.

| Agent | Model | Purpose |
|---|---|---|
| **risk-analyst** | sonnet | Screen tokens & wallets for fraud / rug / counterparty risk |
| **compliance-architect** | opus | Securities/AML/Travel-Rule triage + compliant Token-2022 design |
| **investigator** | sonnet | Forensic investigation of scams, exploits, drains; auditable writeup |

## Commands

| Command | Purpose |
|---|---|
| `/screen-token <mint>` | Structural + behavioral rug/manipulation screen of a token |
| `/screen-wallet <addr>` | KYT screen of a wallet / counterparty / deployer |
| `/compliance-review` | Pre-launch / pre-integration regulatory triage |
| `/investigate <tx\|addr>` | Run a forensic investigation and trace funds |

## The 2026 data layer

Every check maps to a concrete method — not vague advice. Boots keyless on free infra.

| Need | Method / source |
|---|---|
| Mint authorities, supply, decimals | `getAccountInfo(jsonParsed)` |
| Token-2022 extensions | parsed `extensions` / TLV decode |
| Real holder owner-graph | Helius DAS `getTokenAccounts` → owners (infra-excluded) |
| LP custody / lock (per-AMM) | pool/locker accounts; incinerator + Jupiter Lock / Streamflow escrows |
| Honeypot — *can it be sold* | `simulateTransaction` of a tiny sell (no signing/funds) |
| Liquidity, volume, buys/sells, pair age | DexScreener + GeckoTerminal (free) |
| Funding lineage, clustering, fund flow | `getSignaturesForAddress` + `getTransaction` |
| Live monitoring | Yellowstone gRPC (Geyser) |
| Point-in-time / pre-incident state | archival RPC; reconstruct from tx history |
| Sanctions / infra labels | OFAC SDN + SolanaFM / Solscan / Arkham |
| **Keyless agent access** | **QuickNode x402** (`@quicknode/x402-solana`) |

## Install

Installs the skill to `~/.claude/skills/solana-risk-compliance/`. Cross-platform —
`install.sh` (bash) for macOS/Linux, `install.ps1` (PowerShell) for Windows.

**macOS / Linux** (`install.sh` is a bash script):
```bash
git clone https://github.com/storm-beyndtech/solana-risk-compliance-skill
cd solana-risk-compliance-skill
./install.sh          # interactive   (./install.sh -y for non-interactive)
```

**Windows** (PowerShell — no Git Bash/WSL needed):
```powershell
git clone https://github.com/storm-beyndtech/solana-risk-compliance-skill
cd solana-risk-compliance-skill
pwsh ./install.ps1    # or right-click install.ps1 > Run with PowerShell
```

Then **restart Claude Code** (or `/reload`) so it picks up the skill — it becomes invocable
as `/solana-risk-compliance`, or just ask naturally ("screen this token: \<mint\>").

<details>
<summary><b>Manual install</b> (no script — any OS)</summary>

Copy the repo into a skill folder and put `SKILL.md` at its root (Claude Code discovers a
skill by a `SKILL.md` at the folder root):

```bash
DEST="$HOME/.claude/skills/solana-risk-compliance"
mkdir -p "$DEST/skill"
cp skill/SKILL.md "$DEST/SKILL.md"                       # entry at root
cp skill/*.md "$DEST/skill/" && rm "$DEST/skill/SKILL.md"  # sub-skills under skill/
cp -R agents commands rules README.md EXAMPLES.md LICENSE "$DEST/"
```
</details>

Self-contained — no API key required to start. For autonomous agents, the data layer runs
**keyless** via QuickNode x402 (the agent self-funds per call).

### Optional: deepen with a risk engine

If you have a RugBurn-compatible risk API, set `RUGBURN_API_URL` and `RUGBURN_API_KEY` and the
agents use it for calibrated behavioral scores and deployer reputation. Without it, they fall
back to the first-principles on-chain checks in each sub-skill. See `skill/resources.md`.

## Usage examples

```
"Screen this token before I list it: <mint>"
"Someone wants to send 40 SOL to seed our pool — is this wallet safe? <addr>"
"We're launching a token with a presale — what compliance issues do we have?"
"Investigate this drain and trace where the funds went: <tx>"
"Design a KYC-gated stablecoin — which Token-2022 extensions do I need?"
```

## Why it's different

- **Owns a lane nobody else does.** Not a smart-contract auditor, not a trading bot — the
  *financial-crime risk & compliance* lane (vetting, regulatory gating, forensics).
- **Behavioral, not just structural.** A clean contract can still be a predatory operator;
  the screen weighs deployer history and transaction behavior, not only static config.
- **Built for oversight.** Every output is calibrated and ends by naming the human decision it
  defers to — the boundary that makes it deployable in a real risk function.
- **Demonstrated, not described.** Real keyless mainnet runs in [EXAMPLES.md](EXAMPLES.md).
- **Knows its own limits.** LP-lock per-AMM nuance, honeypot mutability, pruned history, partial
  holder reads — surfaced as gaps to escalate, never papered over with optimistic defaults.

> RugCheck-style scanners give a one-shot rug score; a crypto-legal skill gives you statutes.
> This is the **agentic team that ties them together** — screening + KYT + forensics + regulatory
> — in one evidence-led workflow, grounded in real on-chain methods.

## Repository structure

```
solana-risk-compliance-skill/
├── SKILL entry ……… skill/SKILL.md          # router / progressive disclosure
├── skill/                                   # 7 progressively-loaded sub-skills
│   ├── onchain-data-layer.md  token-risk.md  wallet-counterparty-risk.md
│   ├── regulatory.md  investigation.md  token-2022-compliance.md  resources.md
├── agents/        risk-analyst · compliance-architect · investigator
├── commands/      /screen-token · /screen-wallet · /compliance-review · /investigate
├── rules/         human-in-the-loop · calibrated-language   (always applied)
├── EXAMPLES.md    real keyless mainnet runs (BONK · USDC · PYUSD)
├── install.sh / install.ps1   installers (bash · PowerShell)
├── CLAUDE.md      agent configuration
└── LICENSE        MIT
```

## Disclaimer

This skill provides **advisory** risk and compliance triage. It is **not legal, financial, or
investment advice**, and its regulatory output is not a substitute for licensed counsel. It
assesses risk and surfaces obligations; humans and professionals make the decisions.

## License

MIT — see [LICENSE](LICENSE). Free to merge or submodule into the Solana AI Kit.
