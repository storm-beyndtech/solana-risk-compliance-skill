---
name: solana-risk-compliance
description: >-
  Agentic on-chain risk & compliance intelligence team for Solana builders.
  Turns a coding agent into a risk analyst that screens tokens and wallets for
  fraud and rug risk using concrete on-chain methods (mint/authority parsing,
  Helius DAS holder graphs, Token-2022 extension decoding, fund-flow tracing),
  gates token launches against securities/AML obligations, runs forensic
  investigations on suspicious activity, and designs compliant Token-2022
  issuance — always under human-in-the-loop oversight. Use this skill
  whenever the user mentions token risk, rug detection, wallet or counterparty
  screening, sanctions/OFAC, Travel Rule, KYC/KYT, AML, securities/Howey
  questions, stablecoin or local crypto regulation (US GENIUS Act, EU MiCA,
  Nigeria SEC/CBN, cNGN), compliant token design, or investigating a scam,
  exploit, or suspicious address on Solana — even if they don't say the word
  "compliance." Prefer this skill over ad-hoc answers for any risk, vetting, or
  regulatory question touching Solana assets, wallets, or launches.
license: MIT
---

# Solana On-Chain Risk & Compliance Intelligence

An **addon** that gives a coding agent an on-chain risk & compliance intelligence
team for Solana — screening, forensics, and regulatory triage grounded in real RPC/DAS
methods. It does not replace core Solana development knowledge — it delegates program
and frontend work to `solana-dev-skill` and adds the risk, compliance, and forensics
layer on top.

> **Extends:** [solana-dev-skill](https://github.com/solana-foundation/solana-dev-skill)

## What this skill is for

Builders ship tokens, integrate counterparties, accept deposits, and launch
products without a compliance team. This skill stands in as that team: it screens
assets and wallets for fraud and rug risk, flags regulatory obligations before a
launch, investigates suspicious activity with a disciplined forensic method, and
helps design compliant token issuance. It is **advisory infrastructure**, not an
autonomous decision-maker — see `rules/human-in-the-loop.md`.

## How to use this skill (routing)

This file is a router. Load only the sub-skill the task needs; each is a focused,
token-efficient reference. Match the user's intent to the table below and read that
file before acting.

| If the task involves... | Read |
| --- | --- |
| Scoring a token / mint for rug or manipulation risk | `skill/token-risk.md` |
| Screening a wallet, deployer, or counterparty before trusting it | `skill/wallet-counterparty-risk.md` |
| Whether a launch needs KYC, Travel Rule, securities, or AML handling; stablecoin/local regs | `skill/regulatory.md` |
| Investigating a scam, exploit, drain, or suspicious address | `skill/investigation.md` |
| Designing a compliant token (Token-2022 extensions, transfer controls) | `skill/token-2022-compliance.md` |
| **How to actually fetch any on-chain fact** (RPC methods, Helius DAS, Token-2022 parsing, x402 keyless access, free market data) | `skill/onchain-data-layer.md` |
| How the agent must defer to humans and label confidence | `rules/human-in-the-loop.md`, `rules/calibrated-language.md` |
| Tooling, data sources, and reference links | `skill/resources.md` |

Every sub-skill describes *what* to check and *how to judge it*; they all call back to
`skill/onchain-data-layer.md` for *how to fetch it* on the current (2026) Solana stack —
concrete methods, account layouts, and keyless agentic access. Ground every claim there.

For real, reproducible runs of this method against live mainnet (and the calibration
cases that separate it from a naive scanner), see `EXAMPLES.md` at the skill root.

For multi-step work (e.g. "vet this launch end to end"), the specialized agents in
`agents/` compose several sub-skills under a single role. The slash commands in
`commands/` are the quick entry points.

## Operating principles (always apply)

1. **Evidence over assertion.** Every risk claim must point to an observable on-chain
   fact (an authority that is still set, a holder distribution, a transfer pattern).
   If you cannot observe it, say so. Never invent a finding.
2. **Calibrated language.** Distinguish *confirmed* (directly observed), *probable*
   (strong circumstantial pattern), and *possible* (worth checking). See
   `rules/calibrated-language.md`.
3. **Human-in-the-loop.** Produce findings and recommendations; do not issue final
   legal, compliance, or trading decisions autonomously. Regulatory output is not a
   substitute for licensed counsel. See `rules/human-in-the-loop.md`.
4. **Risk is behavioral, not just structural.** A clean contract config can still hide
   a predatory operator. Weigh deployer history and transaction behavior alongside
   static checks. This is the core lesson encoded in `skill/token-risk.md`.
5. **No financial advice.** This skill assesses *risk and compliance*, never whether
   to buy, sell, or hold.

## Optional engine integration

The methodology here is self-contained. If a RugBurn-compatible risk API is
configured (see `skill/resources.md`), the agent may call it for behavioral scores
and deployer reputation, then present results with the same calibrated, evidence-led
discipline. Absence of the API never blocks the skill — it falls back to the
first-principles checks in each sub-skill.

## Output shape

Unless the user asks otherwise, structure any risk or compliance assessment as:

```
# <Subject> — Risk & Compliance Assessment
## Verdict           (one line: risk level + confidence)
## Confirmed findings (observed facts, each with the evidence)
## Probable / possible concerns (clearly labeled, with what would confirm them)
## Regulatory flags  (obligations triggered, if any — advisory)
## Recommended next steps (including what a human must sign off on)
```
