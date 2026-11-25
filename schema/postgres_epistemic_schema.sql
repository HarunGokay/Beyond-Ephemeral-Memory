-- =============================================================================
-- Beyond Ephemeral Memory: Epistemic Context Multigraph Schema (PostgreSQL 16+)
-- Enforces non-monotonic supersession, 5-tier epistemic ladder invariants,
-- dependency-directed cascade erasure, and multi-tenant Row-Level Security.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Tenants
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Raw & Verbatim Sources (User-Authored Learning Filter Boundary)
CREATE TABLE sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_type TEXT NOT NULL,
    content_sha256 TEXT NOT NULL,
    source_timestamp TIMESTAMPTZ,
    source_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Disjoint Topic Forest (Context Trees & Active/Archived Context Branches)
CREATE TABLE context_trees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    title TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_context_trees_status CHECK (status IN ('active', 'archived'))
);

CREATE TABLE context_branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tree_id UUID NOT NULL REFERENCES context_trees(id) ON DELETE CASCADE,
    branch_key TEXT NOT NULL,
    label TEXT NOT NULL,
    current_claim TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_context_branches_status CHECK (status IN ('active', 'archived'))
);

-- 4. Bitemporal Semantic Record Lineage (Non-Monotonic Supersession Chains)
CREATE TABLE semantic_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_id UUID NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES context_branches(id) ON DELETE SET NULL,
    supersedes_record_id UUID REFERENCES semantic_records(id) ON DELETE SET NULL,
    record_key TEXT NOT NULL,
    category TEXT NOT NULL,
    claim_text TEXT NOT NULL,
    confidence DOUBLE PRECISION,
    valid_from TIMESTAMPTZ,
    valid_until TIMESTAMPTZ,
    current_status TEXT NOT NULL DEFAULT 'active',
    state_version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_semantic_records_status CHECK (
        current_status IN ('active', 'superseded', 'contradicted', 'archived')
    )
);

-- 5. Append-Only Operational Event Ledger
CREATE TABLE event_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_id UUID NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    tree_id UUID REFERENCES context_trees(id) ON DELETE SET NULL,
    branch_id UUID REFERENCES context_branches(id) ON DELETE SET NULL,
    supersedes_event_id UUID REFERENCES event_ledger(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    description TEXT NOT NULL,
    occurred_at TIMESTAMPTZ,
    occurred_at_precision TEXT NOT NULL DEFAULT 'unknown',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Typed Directed Multigraph Edges
CREATE TABLE entity_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_record_id UUID REFERENCES sources(id) ON DELETE CASCADE,
    source_type TEXT NOT NULL,
    source_id TEXT NOT NULL,
    source_label TEXT,
    relationship_type TEXT NOT NULL,
    target_type TEXT NOT NULL,
    target_id TEXT NOT NULL,
    target_label TEXT,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until TIMESTAMPTZ,
    CONSTRAINT ck_entity_relationships_status CHECK (
        status IN ('active', 'superseded', 'retired')
    )
);

-- 7. ATMS Decisions & Explicit Operating Assumptions
CREATE TABLE decision_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES context_branches(id) ON DELETE SET NULL,
    decision_summary TEXT NOT NULL,
    stated_rationale TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until TIMESTAMPTZ
);

CREATE TABLE decision_assumptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decision_id UUID NOT NULL REFERENCES decision_records(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assumption_text TEXT NOT NULL,
    linked_branch_id UUID REFERENCES context_branches(id) ON DELETE SET NULL,
    is_invalidated BOOLEAN NOT NULL DEFAULT FALSE,
    invalidated_at TIMESTAMPTZ
);

-- 8. Quantitative Forecasts & Calibration Tracking
CREATE TABLE predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    statement TEXT NOT NULL,
    metric_type TEXT NOT NULL,
    expected_date TIMESTAMPTZ,
    actual_date TIMESTAMPTZ,
    expected_value DOUBLE PRECISION,
    actual_value DOUBLE PRECISION,
    outcome_status TEXT NOT NULL DEFAULT 'pending',
    error_magnitude DOUBLE PRECISION,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until TIMESTAMPTZ
);

-- 9. Temporal Patterns & Interventions (Enforcing Invariant 1 at DB Schema Level)
CREATE TABLE temporal_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pattern_type TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'candidate',
    causal_status TEXT NOT NULL DEFAULT 'unknown',
    confidence DOUBLE PRECISION NOT NULL DEFAULT 0.5,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_temporal_patterns_status CHECK (
        status IN ('candidate', 'emerging', 'supported', 'contradicted', 'retired')
    ),
    CONSTRAINT ck_temporal_patterns_causal_status CHECK (
        causal_status IN (
            'unknown', 'temporal_association', 'correlational_evidence',
            'causal_hypothesis', 'observed_impact', 'tested_causal_evidence',
            'contradicted', 'retired'
        )
    )
);

CREATE TABLE interventions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    prediction_id UUID REFERENCES predictions(id) ON DELETE SET NULL,
    intervention_type TEXT NOT NULL,
    recommendation TEXT NOT NULL,
    acceptance_status TEXT NOT NULL DEFAULT 'recommended',
    implementation_status TEXT NOT NULL DEFAULT 'not_implemented',
    efficacy_evaluation TEXT NOT NULL DEFAULT 'unresolved',
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until TIMESTAMPTZ
);

CREATE TABLE intervention_patterns (
    intervention_id UUID NOT NULL REFERENCES interventions(id) ON DELETE CASCADE,
    pattern_id UUID NOT NULL REFERENCES temporal_patterns(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (intervention_id, pattern_id)
);

-- Multi-Tenant Row-Level Security Isolation
ALTER TABLE sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE sources FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_sources ON sources
    USING (user_id = current_setting('app.current_user_id', true)::uuid);

ALTER TABLE context_trees ENABLE ROW LEVEL SECURITY;
ALTER TABLE context_trees FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_trees ON context_trees
    USING (user_id = current_setting('app.current_user_id', true)::uuid);

ALTER TABLE context_branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE context_branches FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_branches ON context_branches
    USING (user_id = current_setting('app.current_user_id', true)::uuid);

ALTER TABLE semantic_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE semantic_records FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_records ON semantic_records
    USING (user_id = current_setting('app.current_user_id', true)::uuid);
