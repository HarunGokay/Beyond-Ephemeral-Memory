# Longitudinal 2,000-Turn World Models

This directory contains three longitudinal `2,000`-turn (`1,000` user turns + `1,000` assistant turns) multi-session interaction datasets and the PostgreSQL-derived epistemic multigraphs compiled by our framework (Kora v2).

Unlike static single-fact recall benchmarks, these corpora model realistic organizational and executive environments over 6 to 12 months where people change roles, projects are cancelled and restarted, budgets are cut (invalidating prior decision assumptions), architecture and pricing commitments are reversed, earlier factual statements are contradicted by later audits, technical configurations become obsolete, and users issue explicit right-to-erasure deletion commands.

## World Model Catalog

| Directory | Horizon | Turns | Key Epistemic Transitions |
| :--- | :--- | :---: | :--- |
| `01_helixnova_biotech/` | 9 months (Jan–Sep 2026) | 2,000 | Role promotions (`Dr. Elena Vance`, `Marcus Chen`); `Project Proteus` cancelled then restarted as `Proteus-Lite`; GPU budget cut (`$420k -> $240k/qtr`) triggering an **Assumption Contradiction Alert** on in-house 14B training; warehouse reversal (`Snowflake -> ClickHouse -> PostgreSQL 16 + Parquet`); contradicted `Batch HX-409` QC report (`0.0% -> 3.8%` contamination); 6-milestone deadline calibration (`prediction_errors`); controlled `Snakemake` schema-gate intervention promoted to `tested_causal_evidence`; cascading NDA erasure (`CANARY-NDA-9941-KESTREL`). |
| `02_vektorflow_saas/` | 6 months (Mar–Aug 2026) | 2,000 | Role transitions (`Priya Nair`, `Tomas Lindqvist`); `Project Mercury` cancelled for SOC-2 then restarted; **3-hop transitive dependency cascade** (`Stripe 30-min Payout SLA -> Automated Split-Settlement Engine -> Guaranteed Same-Day Creator Payout Tier`); pricing reversals (`$49/seat -> $0.004/event -> $299 hybrid`); contradicted SAML SSO churn hypothesis (`webhook latency > 12s`); retired `Redis 6 -> Valkey 8`; customer incident erasure (`CANARY-ACMEFIN-INC-772`). |
| `03_executive_ops/` | 12 months (Oct 2025–Sep 2026) | 2,000 | Three **0-lexical-overlap cross-domain standing constraints** (anaphylactic cashew/tree-nut allergy, right-knee meniscus rehab rule, `$6.0M` ARR debt-covenant G&A hiring freeze) surfaced proactively on Month-12 retreat and hiring planning queries; multi-city relocation (`Austin -> Denver -> Boston`); cancelled/restarted book manuscript; selective medical note erasure (`CANARY-MED-308-HOLTER`) preserving standing safety rules. |

## Artifact Files per World Model

Each world directory contains five inspectable files:

1. `turns.jsonl` — Chronological stream of all `2,000` dated dialogue turns (`turn_index`, `session_id`, `session_date`, `session_kind`, `role`, `content`).
2. `derived_multigraph.json` — Derived Topic Forest (`trees`, `branches`, and full `supersession_lineage` chains), typed `relationships`, `decisions` + `assumptions`, `assumption_alerts`, `predictions`, `interventions`, and `event_ledger_sample`.
3. `temporal_patterns_and_inquiries.json` — Discovered `TemporalPattern` records (with 5-tier `causal_status`) and `UnderstandingInquiry` gap-resolution questions.
4. `context_slices.json` — Deterministic relational knapsack context slices (`<= 1,500` tokens, zero read-path LLM generation calls) compiled across current-state, point-in-time `as_of`, multi-hop/constraint, and post-erasure probes.
5. `deletion_receipt.json` — Structured cascading erasure receipt confirming `post_erasure_postgres_canary_hits == 0` while non-deleted operational branches remain intact.
