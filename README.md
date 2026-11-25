# Beyond Ephemeral Memory: Epistemic Context Layer Artifacts

Official reproducibility artifact repository accompanying the research paper:

> **Beyond Ephemeral Memory: Non-Monotonic Epistemic Context Layers for Long-Horizon Language Agents**  
> Harun Yahya Gokay (2026)

---

## Overview

Most autonomous agent memory layers treat history as a flat embedding store or an append-only episodic log. Across thousands of real-world interactions—where employees change roles, projects are cancelled and restarted, budgets are cut (invalidating prior decision premises), statements are contradicted, legacy facts become obsolete, and sensitive items are explicitly deleted—monotonic memory suffers from stale-value leakage, distractor crowding, and causal confabulation.

This public repository releases the paper PDF, PostgreSQL 16 epistemic multigraph schema and Row-Level Security (RLS) DDL, longitudinal `2,000`-turn world-model corpora with derived graphs and erasure receipts, EpiBench v2.2 benchmark scorecards, and an offline artifact and statistical verification suite—structured in the lightweight, reproducible style of [`noahshinn/reflexion`](https://github.com/noahshinn/reflexion). To protect intellectual property, proprietary engine and algorithm source code (transition validator, causal promotion gate, knapsack compiler, write-admission pipeline, production prompts, auxiliary gate weights, and commercial Web UI / OAuth / billing layers) are withheld from this public artifact release.

---

## Repository Layout

```text
kora-epistemic-artifacts/
├── paper/
│   └── beyond_memory_kora.pdf             # Full research paper (PDF)
├── schema/
│   └── postgres_epistemic_schema.sql      # PostgreSQL 16 DDL, CHECK constraints & Row-Level Security
├── world_models/
│   ├── README.md                          # Schema & guide to the 3 longitudinal world-model corpora
│   ├── world_models_summary.json          # Aggregate corpus statistics & write-path spend summary
│   ├── 01_helixnova_biotech/              # 2,000 turns (9 months): role shifts, Proteus cancel/restart, budget alert, NDA erasure
│   ├── 02_vektorflow_saas/                # 2,000 turns (6 months): 3-hop Stripe SLA cascade, pricing reversals, incident erasure
│   └── 03_executive_ops/                  # 2,000 turns (12 months): 0-overlap constraints (allergy, meniscus, freeze), medical erasure
├── benchmark_runs/
│   ├── epibench_v2_2_stress_108.json      # Zero-LLM-spend 108-scenario (240-distractor) substrate evaluation scorecard
│   ├── epibench_v2_2_live_depth.json      # Live End-to-End EpiBench v2.2 Depth Stress (Depths 6, 24, 60) scorecard
│   └── statistics.py                      # Exact paired McNemar test, Odds Ratio & 95% Wilson CI helpers
├── tests/
│   └── test_paper_claims.py               # Offline schema, corpus, scorecard & statistical verification suite
├── requirements.txt
└── LICENSE                                # MIT License
```

---

## Quickstart: Verify Public Artifacts & Statistics Offline (`$0.00` API Spend)

No API keys, database instances, external services, or proprietary runtime modules are required to run the artifact verification suite:

```bash
pip install -r requirements.txt
pytest -q
```

Running `pytest -q` executes three offline verification checks:
1. **Statistical Significance Audits:** Recomputes exact binomial McNemar $p$-values, paired Odds Ratios, and 95% Wilson confidence intervals reported in Study B (`n=78` primary endpoint vs. Vector RAG: `p = 0.3075`, n.s.; `n=134` overall vs. Vector RAG: `p = 0.3771`, n.s.; vs. Oracle: `p < 0.0001`, `OR = 4.23`) and Study C (`N=20` full-haystack subset: `p = 0.0386`, `OR = 5.00`).
2. **PostgreSQL 16 Schema & RLS DDL Checks:** Verifies all 13 epistemic tables, cascading foreign-key deletes, 8-state causal `CHECK` constraint definitions, and `FORCE ROW LEVEL SECURITY` multi-tenant isolation statements in `schema/postgres_epistemic_schema.sql`.
3. **Longitudinal `2,000`-Turn World Models (`6,000` Turns) & EpiBench v2.2 Scorecards:** Verifies JSON/JSONL integrity, turn counts, strict `<= 1,500` context slice token budgets, `0` post-erasure PostgreSQL canary leaks across all three worlds, and EpiBench v2.2 scorecard invariants (`0` `as_of` violations, `0` budget overshoots for Kora v2).

---

## Key Empirical Highlights

### 1. EpiBench v2.2 Reader-Free Substrate Evaluation (`N = 108` Scenarios, `240` Mixed Distractors/Scenario)

Directly isolating memory-substrate compilation from reader LLM guesswork under a strict `1,500`-token ceiling (`600`-token tight probe on Track X; `$0.00` LLM generation spend). Note: `epibench_v2_2_stress_108.json` also records a composite `epistemic_hygiene_index_pct` field that is omitted from headline claims because its weighting formula is not documented in the paper.

| System | Gold-Session Recall | 3-Hop Cascade (All Hops) | 0-Overlap Constraint (`@600`) | Complete Overflow Chain | Track E Leak Rate | `as_of` Violations | Budget Overshoots |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Framework v2 (Ours)** | **86.83%** | **100.0%** | **100.0%** | **58.33%** | **0.00%** | **0** | **0** |
| Hybrid RAG (BM25 + Dense + RRF) | 76.13% | 62.50% | 41.67% | 2.08% | 0.00% | 0 | 0 |
| Naive Vector RAG (Dense Top-$k$) | 78.19% | 58.33% | 33.33% | 8.33% | 0.00% | 0 | 0 |
| Recent Context Window | 12.85% | 0.00% | 0.00% | 0.00% | 0.00% | 0 | 7 |
| *Unbounded Oracle Reference* | *100.0%* | *100.0%* | *100.0%* | *100.0%* | *0.00%* | *0* | *n/a* |

### 2. EpiBench v2.2 Live End-to-End Depth Stress (`Depths 6, 24, 60`, Mixed Distractors)

Author-built suite (`n=16` questions across 6 scenarios per depth) evaluated under pinned `gemini-3.5-flash-lite` reader and `gemini-3.5-flash` rubric judge (`T = 0.0`, `B = 1,500` tokens) across Tracks R (28-step revision chains), D (3-hop zero-overlap cascades), and X (0-overlap cross-domain constraints). No significance testing applies at `n=16`/depth.

| System | Depth 6 Acc. | Depth 24 Acc. | Depth 60 Acc. | Depth 60 Scenario Pass | Track D @ 60 | Track R @ 60 | Track X @ 60 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Framework v2 (Ours)** | 75.00% (12/16) | **81.25%** (13/16) | **81.25%** (13/16) | **66.67% (4/6)** | **100.0% (6/6)** | **62.50% (5/8)** | **100.0% (2/2)** |
| Mem0 (Local Qdrant) | **81.25%** (13/16) | 68.75% (11/16) | 62.50% (10/16) | 16.67% (1/6) | 83.33% (5/6) | **62.50% (5/8)** | 0.00% (0/2) |
| Hybrid RAG (BM25+Dense) | 75.00% (12/16) | 75.00% (12/16) | 56.25% (9/16) | 33.33% (2/6) | 66.67% (4/6) | 50.00% (4/8) | 50.00% (1/2) |
| Naive Vector RAG | 75.00% (12/16) | 62.50% (10/16) | 43.75% (7/16) | 16.67% (1/6) | 33.33% (2/6) | 50.00% (4/8) | 50.00% (1/2) |
| *Unbounded Oracle Reference* | *93.75% (15/16)* | *100.00% (16/16)* | *93.75% (15/16)* | *83.33% (5/6)* | — | — | — |

### 3. Controlled LongMemEval-S & Write-Path Efficiency Summary

- **Study B (Reduced Haystacks, $n=134$ Held-Out / $n=78$ Primary KU+TR, Pipeline v1 Commit `cd064b0`):** On the primary pooled knowledge-update and temporal-reasoning endpoint, the framework scored **76.92% (60/78)** versus **69.23% (54/78)** for Naive Vector RAG (**not statistically significant**, exact McNemar `p = 0.3075`, `OR = 1.67`), **65.38% (51/78)** for Mem0, and **28.21% (22/78)** for the Isolated-Evidence Oracle (which behaved abnormally on stripped ground-truth turns). Overall held-out accuracy was **73.13% (98/134)** vs. **68.66% (92/134)** for Vector RAG (`p = 0.3771`, n.s.) and **21.43% (3/14)** on Single-Session Assistant (filtered by design). Median PostgreSQL read latency was `38.77 ms` (`2.8x` faster than Vector RAG at `109.21 ms`, though slower than local Mem0 at `15.40 ms`); Study B also had unequal v1 mean token injection (`1,598.9` vs. `1,366.3` due to an unbudgeted profile primer fixed in v2).
- **Study C (Full 48-Session Haystacks, $N=20$ Subset of Study B, Pipeline v1):** **70.0% (14/20)** vs. **30.0% (6/20)** for Naive Vector RAG (**+40.0%**, exact McNemar `p = 0.0386`, `OR = 5.00`, 95% CI `[1.05, 23.8]` — suggestive small-sample evidence over 40–53 session / ~121k-token transcripts).
- **Write-Path Salience Efficiency (EpiBench v2.2 $N=108$):** Two-tier write admission invoked **1,068** structured LLM extraction calls across **~27,540** sessions (**96.1%** skipped at zero write-path LLM cost) while preserving local verbatim indexing.

---

## Citation

```bibtex
@article{gokay2026beyond,
  title   = {Beyond Ephemeral Memory: Non-Monotonic Epistemic Context Layers for Long-Horizon Language Agents},
  author  = {Gokay, Harun Yahya},
  year    = {2026}
}
```
