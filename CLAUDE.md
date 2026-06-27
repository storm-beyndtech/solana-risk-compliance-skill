# Solana On-Chain Risk & Compliance Intelligence — agent configuration

This project installs an on-chain risk & compliance intelligence skill for Solana.

When a task involves token risk, wallet/counterparty screening, securities/AML/
Travel Rule questions, stablecoin or local crypto regulation, compliant token design,
or investigating a scam/exploit/suspicious address on Solana, consult
`skill/SKILL.md` and route to the relevant sub-skill.

Every risk/compliance claim must point to an observable on-chain fact. The sub-skills
say *what* to check; `skill/onchain-data-layer.md` says *how* to fetch it on the 2026
stack (RPC methods, Helius DAS, Token-2022 parsing, Yellowstone gRPC, and keyless
QuickNode x402 agentic RPC). Ground findings there; if a fact could not be fetched,
report it as unknown, never as clean.

Always apply the two cross-cutting rules:
- `rules/human-in-the-loop.md` — produce findings and recommendations; defer final
  legal, compliance, and trust decisions to a human.
- `rules/calibrated-language.md` — label every finding confirmed / probable /
  possible, and never present inference as observation.

This skill provides advisory triage only. It is not legal, financial, or investment
advice.
