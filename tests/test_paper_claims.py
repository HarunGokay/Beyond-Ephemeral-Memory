"""Offline integrity & statistical verification suite for public paper artifacts.

Runs offline with zero external API keys, proprietary engine code, or network access (`pytest -q`).
Verifies:
1. Exact binomial McNemar tests, paired Odds Ratios, and 95% Wilson CIs reported in Studies B and C.
2. PostgreSQL 16 schema DDL tables, CHECK constraints, cascading deletes, and Row-Level Security policies.
3. Structural, token-budget, and zero-canary-leak invariants across all 3 x 2,000-turn world models
   and EpiBench v2.2 (`stress_108` & `live_depth`) JSON scorecards.
"""

from __future__ import annotations

import json
from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from benchmark_runs.statistics import exact_mcnemar_test, wilson_ci_95


def test_paper_statistical_tests():
    # Study C (N=20 full-haystack subset): b=10 (Framework only), c=2 (RAG only) -> p = 0.0386, OR = 5.00
    study_c = exact_mcnemar_test(10, 2)
    assert study_c["p_value"] == 0.0386
    assert study_c["odds_ratio"] == 5.0

    # Study B Primary Endpoint (n=78 held-out KU+TR vs Vector RAG): b=15, c=9 -> p = 0.3075, OR = 1.67
    study_b_primary = exact_mcnemar_test(15, 9)
    assert study_b_primary["p_value"] == 0.3075
    assert study_b_primary["odds_ratio"] == 1.67

    # Study B Overall Held-Out (n=134 vs Vector RAG): b=19, c=13 -> p = 0.3771, OR = 1.46
    study_b_overall_rag = exact_mcnemar_test(19, 13)
    assert study_b_overall_rag["p_value"] == 0.3771
    assert study_b_overall_rag["odds_ratio"] == 1.46

    # Study B Overall Held-Out (n=134 vs Isolated-Evidence Oracle): b=55, c=13 -> p < 0.0001, OR = 4.23
    study_b_overall_oracle = exact_mcnemar_test(55, 13)
    assert study_b_overall_oracle["p_value"] < 0.0001
    assert study_b_overall_oracle["odds_ratio"] == 4.23

    # 95% Wilson CIs checked in paper
    lo, hi = wilson_ci_95(60, 78)
    assert (round(lo, 1), round(hi, 1)) == (66.4, 84.9)

    lo_c, hi_c = wilson_ci_95(14, 20)
    assert (round(lo_c, 1), round(hi_c, 1)) == (48.1, 85.5)


def test_postgres_schema_ddl_invariants():
    ddl_path = REPO_ROOT / "schema" / "postgres_epistemic_schema.sql"
    assert ddl_path.exists(), f"Missing schema file {ddl_path}"
    ddl = ddl_path.read_text(encoding="utf-8")

    expected_tables = (
        "users",
        "sources",
        "context_trees",
        "context_branches",
        "semantic_records",
        "event_ledger",
        "entity_relationships",
        "decision_records",
        "decision_assumptions",
        "predictions",
        "temporal_patterns",
        "interventions",
        "intervention_patterns",
    )
    for table in expected_tables:
        assert f"CREATE TABLE {table} (" in ddl, f"Missing CREATE TABLE {table}"

    assert "ON DELETE CASCADE" in ddl
    assert "ck_temporal_patterns_causal_status CHECK" in ddl
    assert ddl.count("ENABLE ROW LEVEL SECURITY;") >= 4
    assert ddl.count("FORCE ROW LEVEL SECURITY;") >= 4


def test_three_2000_turn_world_models_and_epibench_artifacts():
    wm_root = REPO_ROOT / "world_models"
    expected_worlds = ("01_helixnova_biotech", "02_vektorflow_saas", "03_executive_ops")

    summary = json.loads((wm_root / "world_models_summary.json").read_text(encoding="utf-8"))
    for wk in expected_worlds:
        assert wk in summary["worlds"], f"Missing {wk} in world_models_summary.json"
        assert summary["worlds"][wk]["total_dialogue_turns"] == 2000
        assert summary["worlds"][wk]["post_erasure_canary_hits"] == 0

        wdir = wm_root / wk
        assert wdir.exists(), f"Missing world directory {wdir}"
        turns_lines = (wdir / "turns.jsonl").read_text(encoding="utf-8").strip().splitlines()
        assert len(turns_lines) == 2000, f"{wk} expected 2000 turns, got {len(turns_lines)}"
        for line in turns_lines:
            json.loads(line)

        mg = json.loads((wdir / "derived_multigraph.json").read_text(encoding="utf-8"))
        assert mg["stats"]["total_dialogue_turns"] == 2000
        assert mg["stats"]["post_erasure_canary_hits"] == 0
        assert mg["stats"]["active_trees"] >= 1

        patterns_doc = json.loads((wdir / "temporal_patterns_and_inquiries.json").read_text(encoding="utf-8"))
        assert isinstance(patterns_doc.get("temporal_patterns"), list)
        assert isinstance(patterns_doc.get("generated_inquiries"), list)

        receipt = json.loads((wdir / "deletion_receipt.json").read_text(encoding="utf-8"))
        assert receipt["post_erasure_postgres_canary_hits"] == 0
        assert receipt["surviving_active_branches_count"] >= 2
        canary = receipt["canary_token"].lower()

        slices = json.loads((wdir / "context_slices.json").read_text(encoding="utf-8"))
        assert len(slices) == 4
        for sl in slices:
            assert sl["token_count"] <= sl["budget"]
            assert canary not in sl["compiled_context"].lower()

    # Check EpiBench v2.2 benchmark scorecards exist and validate
    stress_108 = json.loads((REPO_ROOT / "benchmark_runs" / "epibench_v2_2_stress_108.json").read_text(encoding="utf-8"))
    assert stress_108["generator_version"] == "2.2.0"
    assert stress_108["total_scenarios"] == 108
    assert stress_108["total_questions"] == 216
    assert stress_108["total_llm_spend_usd"] == 0.0
    assert stress_108["systems"]["kora_v2"]["as_of_violations"] == 0
    assert stress_108["systems"]["kora_v2"]["budget_overshoots"] == 0
    assert stress_108["systems"]["kora_v2"]["track_e_leak_rate_pct"] == 0.0

    live_depth = json.loads((REPO_ROOT / "benchmark_runs" / "epibench_v2_2_live_depth.json").read_text(encoding="utf-8"))
    assert live_depth["generator_version"] == "2.2.0"
    assert live_depth["depths"] == [6, 24, 60]
    for d in ("6", "24", "60"):
        kora_stats = live_depth["results_by_depth"][d]["performance_summary"]["by_system"]["kora"]
        assert kora_stats["parse_failures"] == 0
        assert kora_stats["judge_errors"] == 0
        assert kora_stats["as_of_violation_count"] == 0
