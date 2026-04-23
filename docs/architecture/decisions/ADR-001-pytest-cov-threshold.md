# ADR-001: Adopt pytest-cov 60% line coverage threshold for Python template

---

- **Status**: Accepted
- **Date**: 2026-04-23
- **Deciders**: @gs07103
- **Related**: DISCUSS Q2 (`.plans/llm-setup/12-python-template-hardening/DISCUSS.md`)

## Context

Python scaffolded templates must pass CI on day-0 without requiring the LLM agent or first human contributor to write production code before the first green build. Historical anchoring: `research.md §8.2` suggested 80% as a mature-stage target, but applying it at scaffold time guarantees a red CI on every fresh repo — blocking autonomous agent runs and first-session setup.

Python's coverage tooling (`pytest-cov` on top of `coverage.py`) exposes a **single line-coverage metric** by default; branch coverage is opt-in via `--cov-branch` and is not industry-standard for Python projects. This differs from Spring's JaCoCo (LINE + BRANCH simultaneously default) and TypeScript's Jest (branches/functions/lines/statements four metrics).

Cross-stack comparison at time of decision (2026-04-23):

| Stack | Template | Threshold | Metric shape |
|-------|----------|-----------|--------------|
| Spring | jacoco | 70% LINE + 70% BRANCH | 2-metric (JaCoCo default) |
| TypeScript | Jest | 60/50/60/60 (branches/functions/lines/statements) | 4-metric (Jest default) |
| **Python** | **pytest-cov** | **60% line** | **1-metric (pytest-cov default)** |

Spring's outlier 70% reflects JVM + ArchUnit ecosystem characteristics (stronger static guarantees enable higher coverage floors without flakiness). Python and TS interpreted-language templates converge on 60% as the starter baseline.

## Decision

Adopt **`--cov-fail-under=60`** (line coverage, single metric) as the default pytest-cov threshold across all three Python archetypes (main library/CLI, data-science, FastAPI). Document the rationale in two guards:

1. **In-place comment** in `examples/pyproject.toml` `[tool.pytest.ini_options]` — one-liner pointing to this ADR
2. **SETUP.md § Coverage Threshold Adjustment** — trigger list (team ≥5 / audit / production) + raise procedure + floor rule ("do not lower below 60% without an ADR supersede")

## Alternatives considered

### Option A: 60% line (chosen) — current day-0 baseline

**Trade-offs**: Guarantees green CI on fresh scaffold. Allows LLM agent autonomous runs. Consistent with TypeScript template 60% line (interpreted-language alignment). Understates risk for mature codebases — mitigated by guards (pyproject.toml comment + SETUP.md adjustment guide).

**Rejected alternatives**: see Option B and C below.

### Option B: 70% line (match Spring)

**Trade-offs**: Cross-stack consistency for teams using multiple templates. Harder anchor for first-session scaffold — requires real modules before CI passes. Does not reflect stack-specific characteristics (Python lacks Spring's JVM + ArchUnit compile-time guarantees).

**Rejected because**: Python pytest-cov ecosystem norms center on 60-80% as a continuous ramp; picking 70% as scaffold default blocks day-0 green without Spring's compile-time safety net.

### Option C: 60% line + branch coverage activated (`--cov-branch`)

**Trade-offs**: Adds branch coverage metric without raising line threshold. More thorough than Option A. Complicates multi-archetype sync (scientific archetype branch coverage on numpy/pandas-heavy code adds noise from external library call paths).

**Rejected because**: Branch activation is not standard in pytest-cov community and adds maintenance cost without clear signal quality improvement at current team scale. Revisit if data-science archetype matures.

See DISCUSS Q2 for the full 4x6 tradeoff matrix used during selection.

## Consequences

What becomes **easier**:

- Day-0 green CI on every fresh scaffold — no manual threshold tuning
- LLM agent autonomous end-to-end runs (no human intervention for CI baseline)
- Cross-archetype consistency: all three Python archetypes share the same threshold

What becomes **harder**:

- Multi-archetype drift risk — threshold must stay synchronized across `examples/pyproject.toml`, `examples/pyproject.scientific.toml`, `examples/archetype-fastapi/pyproject.toml`. Mitigated by `validate.sh V12` regression guard.
- Coverage blindness — 60% line masks uncovered branches. Partially mitigated by SETUP.md guidance to raise when real modules exist.

**New technical debt**:

- Threshold ramp-up responsibility shifts to derived-repo maintainers. Named explicitly in SETUP.md § Coverage Threshold Adjustment so future contributors see the raise triggers.

## Business impact

### Cost

- Infrastructure: $0 / month (pytest-cov is bundled with pytest; no additional tooling)
- Vendor / license: $0
- Engineer time to implement: 0.5 person-days (already implemented; this ADR records the decision)
- Ongoing maintenance: ~1 hour / quarter (derived-repo threshold raise reviews)

### Risk

- Blast radius if the decision turns out wrong: all derived Python repositories inherit 60% floor; override requires per-repo `pyproject.toml` edit.
- Rollback time: < 1 hour (change single line in pyproject.toml + push).
- Mitigations: SETUP.md adjustment guide, validate.sh V12 sync check, this ADR as supersede anchor.

### Velocity impact

- **Enables**: autonomous LLM agent scaffold green runs; day-0 repo creation without manual tuning.
- **Blocks**: nothing — threshold is additive and raisable.
- **Does not affect**: existing derived repos that have already raised their own threshold.

## Implementation notes

- Configuration source: `examples/pyproject.toml` `[tool.pytest.ini_options]` `addopts` contains `--cov-fail-under=60`
- Documentation: `SETUP.md § Coverage Threshold Adjustment` subsection in Config Reference Appendix
- Regression guard: `validate.sh V12` checks multi-archetype sync (ruff "W" + pyright exclude "examples")
- Guard comment: `examples/pyproject.toml` L78 (between DISCUSS Q4 comment and `addopts`)

## References

- DISCUSS Q2: `.plans/llm-setup/12-python-template-hardening/DISCUSS.md`
- Spring counterpart: `templates-review/spring-template/docs/architecture/decisions/ADR-001-jacoco-coverage-threshold.md` (70% LINE + 70% BRANCH)
- TypeScript counterpart (Phase 11.5 planned): 60/50/60/60 four-metric baseline
- `research.md §8.2` (historical 80% target — superseded as scaffold baseline)
- pytest-cov documentation: https://pytest-cov.readthedocs.io/
