"""Exact Paired McNemar Test, Odds Ratio, and 95% Wilson Confidence Intervals.

Verifies the statistical hypothesis tests reported across Studies B, C, D, and EpiBench.
"""

from __future__ import annotations

import math
from typing import Dict, Tuple


def wilson_ci_95(k: int, n: int, z: float = 1.95996) -> Tuple[float, float]:
    """Return 95% Wilson score confidence interval in percentage points [0..100]."""
    if n <= 0:
        return (0.0, 0.0)
    p = k / n
    denom = 1.0 + (z * z) / n
    centre = (p + (z * z) / (2.0 * n)) / denom
    half = (z * math.sqrt((p * (1.0 - p) + (z * z) / (4.0 * n)) / n)) / denom
    return (round(max(0.0, centre - half) * 100.0, 2), round(min(1.0, centre + half) * 100.0, 2))


def exact_mcnemar_test(b: int, c: int) -> Dict[str, float]:
    """Compute exact two-sided binomial McNemar p-value and paired Odds Ratio b/c.

    `b`: questions passed ONLY by System A (Framework)
    `c`: questions passed ONLY by System B (Baseline)
    """
    n_disc = b + c
    if n_disc == 0:
        return {"p_value": 1.0, "odds_ratio": 1.0}

    k_min = min(b, c)
    tail = sum(math.comb(n_disc, i) for i in range(k_min + 1)) / (2 ** n_disc)
    p_two_sided = min(1.0, 2.0 * tail)
    odds_ratio = (b / c) if c > 0 else float("inf")
    return {
        "discordant_pairs": n_disc,
        "b_only_a": b,
        "c_only_b": c,
        "p_value": round(p_two_sided, 4),
        "odds_ratio": round(odds_ratio, 2) if math.isfinite(odds_ratio) else odds_ratio,
    }
