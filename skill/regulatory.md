# Regulatory Gating

Help a builder understand which obligations a launch or integration may trigger,
*before* they ship. This is advisory triage to surface issues and questions for
counsel — it is **not legal advice** and must never be presented as settled law.
See `rules/human-in-the-loop.md`.

## How to use

Identify what the user is doing (issuing a token, running a launchpad, accepting
deposits, building a stablecoin rail, routing payments), then walk the relevant
sections and produce a list of *flags and questions*, each with why it matters and
what a human/lawyer should confirm.

## 1. Securities exposure (token launches)

The core question regulators ask is whether the token is an investment contract.
The common test (US "Howey" framing, with analogues elsewhere) looks at: an
investment of money, in a common enterprise, with an expectation of profit, derived
from the efforts of others.

Flags that push toward "looks like a security":
- Marketing that promises returns, price appreciation, or yield from the team's work.
- Pre-sale / fundraising mechanics with allocations to a core team.
- Ongoing managerial effort by a central party that holders rely on for value.

Flags that push the other way (utility/consumptive use, decentralization) reduce but
do not eliminate exposure. Output: "this has securities-law exposure because X;
confirm with counsel in the relevant jurisdiction(s)."

## 2. AML / KYC / sanctions

Triggered when the user touches user funds or counterparties at scale (launchpad,
custody, on/off-ramp, payment routing):
- **Sanctions screening** — obligation to avoid transacting with sanctioned
  addresses/persons. Pair with `wallet-counterparty-risk.md`.
- **KYC** — identity verification duties attach to many money-handling activities,
  varying by jurisdiction and license.
- **KYT / monitoring** — ongoing transaction monitoring expectations.

## 3. Travel Rule

For transfers above jurisdictional thresholds between obliged entities (e.g.
VASP-to-VASP), originator and beneficiary information must travel with the
transaction. Flag when the user is building anything that moves value between
regulated parties; identify the threshold question and the data-handling obligation.

## 4. Stablecoins & jurisdictional regimes (2026 landscape)

Give current, high-level context and always route specifics to counsel:

- **US — GENIUS Act.** Federal framework for payment stablecoins, **enacted July 18,
  2025**. It generally **prohibits anyone other than a "permitted payment stablecoin
  issuer" from issuing a payment stablecoin in the US**; permitted issuers face reserve
  (1:1 high-quality liquid assets), disclosure, and AML/BSA obligations. As of mid-2026
  it is in the **implementation phase** — regulators (OCC/Treasury/FinCEN) have issued
  proposed rules (OCC NPRM comment period ran to May 1, 2026) and the OCC has
  conditionally chartered issuers (Circle, Paxos, others, Dec 2025). **Effective date:**
  the earlier of ~Jan 2027 (18 months post-enactment) or 120 days after final rules.
  Relevant if the user issues, distributes, or builds rails on USD stablecoins touching
  US persons — flag that "permitted issuer" status is now a gating question, not optional.
- **EU — MiCA.** Comprehensive regime; the stablecoin titles (EMTs / ARTs) have been in
  force since mid-2024 and the rest of MiCA since end-2024, so this is **live law**, not
  pending — "e-money tokens" / "asset-referenced tokens" carry issuer authorization,
  reserve, and disclosure duties, with caps on large non-euro EMT usage as a means of
  payment.
- **Nigeria — SEC & CBN.** The SEC regulates digital assets as securities/investments
  under its rulebook; the CBN governs payment/settlement and imposes capital and
  licensing requirements (IMTO, MMO/switching) that are heavy enough to block
  thinly-capitalized money-movement startups. **cNGN** is the regulated naira
  stablecoin (issued under SEC oversight via the Africa Stablecoin Consortium); it is
  the compliant naira rail and a more defensible integration target than minting
  bespoke naira tokens. A builder selling *tooling* to licensed entities generally
  avoids the money-transmitter capital walls that issuing/holding funds triggers —
  surface this distinction explicitly when a Nigerian builder is involved.

## Output format

```
# Regulatory flags — <what the user is building>
- Securities: <exposure + why + confirm-with-counsel question>
- AML/KYC: <obligations likely triggered>
- Travel Rule: <applies? threshold question>
- Jurisdiction-specific: <US GENIUS / EU MiCA / NG SEC-CBN as relevant>
- Open questions for counsel: <numbered list>
Disclaimer: advisory triage, not legal advice.
```

Every regulatory output ends by naming what a human/lawyer must decide. Never tell
the user they are "compliant" or "fine" — you surface issues; licensed professionals
clear them.
