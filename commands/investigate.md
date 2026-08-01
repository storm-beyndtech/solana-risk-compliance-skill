---
name: investigate
description: Run a forensic investigation on a Solana incident or address.
---

# /investigate <address | tx | incident | operator>

Run the six-step forensic method from `skill/investigation.md`: scope, verify
anchors, baseline, the four forensic questions, calibrated language, structured
writeup. Trace fund flow, label confidence, and hand attribution to a human before
publication.

If the target is an operator/deployer rather than one incident, scope to its full
recent population of deployments before generalizing, check third-party labels,
re-derive any cached reputation metric from a live source, check for self-trading
on its own assets, and run a comparative baseline before calling any pattern
distinctive — see `skill/investigation.md` §1–4 and `agents/investigator.md`.
