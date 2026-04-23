# RATIONALE — Why python-template made these choices

> **Snapshot as of 2026-04.** External template references (mpuig,
> smartwhale8, cookiecutter-uv) are frozen at the date this document was
> written. They may diverge or become stale. If you are evaluating whether
> to adopt this template in 2027+, treat the comparison sections as
> historical context, not current ground truth.

**Who should read this**: advanced users who have seen several Python
templates and want to know **why this one picked the specific stack it
did**. If you're just deciding whether this template is for you, read
[README.md](./README.md) instead — that has the 30-second fit check.

---

## Feature Matrix

The table below compares this template against three alternatives that
were evaluated before the design was finalized.

| Feature | mpuig/claude-code-py-template | smartwhale8/claude-playbook | fpgmaas/cookiecutter-uv | **This template** |
|---------|:-----:|:-----------:|:---------------:|:-----------------:|
| LLM fail-fast meta-instructions | N | Partial | N | Y |
| Non-interactive scaffolding | N | N | **N (interactive)** | Y |
| 2-job CI + needs gate + concurrency cancel | N | Unknown | Partial | Y |
| CodeRabbit path_instructions | N | N | N | Y |
| basedpyright strict CI | N | N | N | Y |
| 3 archetype branching | N | N | N | Y |
| Git safety gate bash block | N | Unknown | N | Y |
| 3-language unified skeleton | N | N | N | Y |
| Scientific basedpyright preset | N | N | N | Y |

---

## Alternatives considered

### mpuig/claude-code-py-template

mpuig's template is a **PoC orchestrator**, not a scaffolding template.
It provides slash-command agents that build a proof-of-concept from
requirements. It has:

- No `.github/workflows/` CI
- No CodeRabbit integration
- No basedpyright (uses mypy)
- No Git safety gate
- No non-interactive `uv init` automation

This template's purpose — "empty directory → CI green, non-interactively"
— is simply out of scope for mpuig. The two templates answer different
questions: mpuig answers "build me a working PoC from a description",
this template answers "give me a production-grade project scaffold that a
CI system can verify on the first push".

### smartwhale8/claude-playbook

smartwhale8/claude-playbook is a **language-neutral `.claude/` template**.
It provides a production-ready `.claude/rules/` + skills + agents
structure, but:

- No Python-specific tooling (Ruff, basedpyright, uv, pytest)
- No SETUP.md phase document to drive scaffolding
- No CI template, no archetype branching
- Requires manual adaptation for every language

This template provides the Python-specific layer that claude-playbook
intentionally omits. The two are complementary rather than competing:
claude-playbook is a good foundation for the `.claude/` configuration
layer, while this template adds the Python toolchain and agent-executable
setup flow on top.

### fpgmaas/cookiecutter-uv

cookiecutter-uv is **interactive-only** — `cookiecutter.json` requires
interactive user prompts, which directly conflicts with LLM agent
non-interactive execution. Additionally:

- Uses tox + Makefile (not uv-native CI)
- No CodeRabbit `.coderabbit.yaml`
- No basedpyright (offers mypy/ty as interactive choice)
- No LLM meta-instructions
- No Git safety gate

The interactive prompt model is a fundamental design choice, not a
missing feature. Adding non-interactive support would require replacing
the entire cookiecutter interpolation layer. For human-driven project
creation where interactivity is acceptable, cookiecutter-uv is a
reasonable choice; for agent-driven pipelines it is not.

---

## Why these pinned versions

### Python 3.13

Python 3.13 introduced free-threaded mode (PEP 703) and improved error
messages. More importantly: choosing 3.13 means the template gets to use
3.12+ syntax (PEP 695 type aliases) and deprecates patterns that were
removed or warned against in 3.12. Pinning to an older version would
require "compatibility shims" that obscure idiomatic modern Python from
the LLM agent.

### basedpyright (strict) over mypy

- mypy is **slower** — a project with 50 files takes noticeably longer in CI
- plain pyright (not `strict`) lets too much through: implicit `Any`,
  missing return types, and untyped function parameters all pass silently
- basedpyright strict applies strict type checking that catches real bugs
  before runtime: `Unknown` propagation, missing `__all__` exports, and
  inferred-`Any` function calls

The cost is real: basedpyright strict requires annotating functions that
mypy would accept without annotations. That cost is intentional — this
template treats strict types as a non-negotiable invariant, not a
nice-to-have.

### ty (IDE only, not in CI)

ty is Astral's new type checker, currently in alpha. It is significantly
faster than basedpyright for interactive use (sub-second feedback in
editors). However, its output is not yet stable enough for a CI gate:
false positives and missing checks make it unsuitable as the single
source of truth for a PR workflow. The split — `ty` in the editor,
`basedpyright` in CI — gives developers fast feedback without
compromising the CI gate.

### Ruff over black + isort + flake8

Three tools means three configuration surfaces that can diverge. Ruff
handles formatting (equivalent to black), import sorting (equivalent to
isort), and linting (equivalent to flake8 + many plugins) from a single
`[tool.ruff]` section in `pyproject.toml`. The 11-rule select in this
template (`E,F,I,UP,B,S,PERF,PD,NPY,RUF`) covers style, imports,
upgrades, bugbear, security, performance, pandas-specific, numpy-specific,
and Ruff-specific rules — coverage that would require six separate plugins
under the old stack.

### uv over pip + poetry

- pip lacks a lockfile format — `requirements.txt` pinning is fragile
- poetry is slow (dependency resolver) and uses a different lockfile
  format than the stdlib/uv ecosystem
- uv resolves in milliseconds, generates a standards-compatible lockfile
  (`uv.lock`), and integrates with `pyproject.toml` directly
- `uv init --package` with `src/` layout is a single command vs. manual
  directory creation + `setup.cfg` with pip

The `src/` layout choice (produced by `uv init --package`) is not
aesthetic: it prevents accidental imports of in-tree code during testing,
which is a real class of bug where `pytest` discovers the local module
instead of the installed package.

### Import Linter over runtime checks

Architecture boundaries (`routers/ → services/ → repositories/`) are
only useful if they are enforced. Runtime enforcement (raising at import
time) fails too late — CI must catch boundary violations before a PR
merges. Import Linter runs as a static check and fails the CI pipeline if
any configured boundary is violated. The contracts in `examples/.importlinter`
(with `include_external_packages = True`) also prevent service layers from
importing framework dependencies directly, keeping business logic
framework-agnostic.

---

## Rejected alternatives (summary)

| Decision | Chosen | Rejected | Reason |
|---|---|---|---|
| Type check | basedpyright strict (CI) + ty (IDE) | mypy | Speed + strict default catches more bugs |
| Lint + format | Ruff (unified) | black + isort + flake8 | Single config, faster, broader rule coverage |
| Package manager | uv | pip, poetry | Lockfile + speed + `src/` layout integration |
| Architecture enforcement | Import Linter (static) | Runtime checks, convention | CI catches boundary violations before merge |
| Non-interactive scaffolding | SETUP.md phase doc | cookiecutter interactive | Agent-executable without user prompts |
| CI template | 2-job (lint-type-test / build-push) | Single-job | Fail-fast on type errors without running build |
| PR review | CodeRabbit `.coderabbit.yaml` | Manual, Reviewdog | Path-specific instructions for LLM context |

---

## Core differentiator

This template is part of `llm-setup-prompts` — a **3-language unified
scaffolding workspace** (TypeScript + Spring + Python). All three
language templates share the same 14-section SETUP.md skeleton,
`.claude/rules/` structure, and Git workflow conventions. That
cross-language consistency is the feature that none of the three
competitor templates above can replicate — they are each single-language
solutions with no shared skeleton or cross-language convention.

---

## See also

- [README.md](./README.md) — 30-second fit check and quick start
- [SETUP.md](./SETUP.md) — scaffold.sh usage guide (post-Phase-13 architecture)
- [ADR-002](./docs/architecture/decisions/ADR-002-clone-script-scaffolding.md)
  — why the pre-Phase-13 14-phase SETUP.md flow was replaced with clone + script
- [CLAUDE.md](./CLAUDE.md) — AI agent rules for derived projects
- External references (snapshot as of 2026-04):
  - [mpuig/claude-code-py-template](https://github.com/mpuig/claude-code-py-template)
  - [smartwhale8/claude-playbook](https://github.com/smartwhale8/claude-playbook)
  - [fpgmaas/cookiecutter-uv](https://github.com/fpgmaas/cookiecutter-uv)

---

## Clone + Script Architecture (Phase 13, 2026-04-23)

See [ADR-002](./docs/architecture/decisions/ADR-002-clone-script-scaffolding.md)
for the full decision record. One-sentence summary: Phase 12 Fix 1–6 accumulated
environment-specific workarounds because **template file acquisition was coupled
to GitHub CLI availability**. Phase 13 decouples them — `git clone` gets the
files, `./scaffold.sh` customizes, and `gh repo create` is an optional separate
step. Direct driver: Codex e2e23 dry run (2026-04-23) spent 2m 26s unable to
locate Windows `gh.exe` from its Linux sandbox and never reached Phase 1.

---

## PowerShell Silent-No-Op — Accepted Limitation (Fix 8 post-mortem)

> Timeline: Fix 8 merged 2026-04-23 (commit `5a16bf3`). Empirical PowerShell
> testing + this post-mortem section written 2026-04-24.

After Phase 13 shipped, the Codex e2e24 and e2e25 dry runs uncovered a
Windows-specific failure mode. Fix 8 addressed part of it but could not
fully eliminate it. This section documents what remains, why, and what
users must do.

### Symptoms

Invoking `.\scaffold.sh` directly from Windows PowerShell (no `bash` prefix)
produces one of two outcomes, depending on environment:

| Environment | Result |
|---|---|
| Interactive user PowerShell (Windows 10/11) | Windows "choose an app" dialog appears — visible feedback. If the user dismisses or picks a non-bash app, the script does **not** execute. |
| Headless PowerShell (Codex sandbox, CI runners, `powershell.exe -Command "..."` from scripts) | **Silent no-op** — `exit 0`, no output, no side effects. Script body never executes. |

### Empirical test matrix (2026-04-24, Windows 11 + Git for Windows 2.49.0 + PowerShell 5.1)

| Invocation | Script body ran? | `$LASTEXITCODE` | Side effects |
|---|---|---|---|
| `.\test.sh` (direct) | ❌ no-op | 0 / empty | none |
| `.\test` (no extension, direct) | ❌ no-op | 0 / empty | none |
| `bash test.sh` | ✅ runs | 0 | expected |
| `bash test` (no extension) | ✅ runs | 0 | expected |

The root cause is in PowerShell's invocation mechanism, not the `.sh` extension
or the Windows registry. PowerShell's `.\<name>` form invokes the file directly
as a process argument and does **not** fall back to ShellExecute when that
fails. The `.sh=sh_auto_file "C:\Program Files\Git\git-bash.exe" --no-cd "%L" %*`
registry entry IS registered by standard Git for Windows installs, and WOULD
dispatch correctly if the file were launched via ShellExecute (double-click in
Explorer, `Start-Process` with the default verb, or `cmd /c file.sh`). But
PowerShell's `.\<name>` code path skips ShellExecute for non-`.ps1` files.
This is why the `.\test` (no extension) case reproduces identically — the
invocation form is the variable, not the extension. The script body is never
parsed, which in turn means the `BASH_VERSION` / `$BASH` interpreter guard
inside scaffold.sh cannot fire — the shell never reaches the line where the
guard is defined.

### Why file-extension rename doesn't help

A natural Fix 9 hypothesis was "rename `scaffold.sh` to `scaffold` (no extension)
so Windows has no file association to dispatch to." Empirical testing rejected
this hypothesis: `.\scaffold` (no extension) also silent-no-ops from headless
PowerShell, identical to `.\scaffold.sh`. The silent-no-op behavior is a
property of PowerShell's handling of non-PS1 files in the `.\<name>` invocation
form, not of the `.sh` extension specifically. See rationale above.

### What users must do

Always invoke scaffold.sh with an explicit `bash` prefix:

```bash
bash ./scaffold.sh --pkg <name> --archetype <type>
```

This works identically in:
- Git Bash (Windows)
- WSL bash (Windows)
- Native bash (Linux, macOS)
- Headless PowerShell (when `bash` is on PATH via Git for Windows)

The Quick Start in SETUP.md and README.md uses this form. Users who follow the
documented Quick Start are safe. Users who substitute `./scaffold.sh` or
`.\scaffold.sh` in PowerShell may observe the silent-no-op documented above.

### Guard coverage (what Fix 8 does and doesn't protect against)

The guard at the top of scaffold.sh is a **three-condition OR check**:
1. `[ -z "${BASH_VERSION:-}" ]` — no `BASH_VERSION` variable
2. `[ -z "${BASH:-}" ]` — no `BASH` variable
3. `${BASH##*/}` (basename of `$BASH`) not in `{bash, bash.exe}`

Any one true → guard fires and exits non-zero with a remediation message.

Both `BASH_VERSION` and `$BASH` are bash-only shell variables, so either one
being unset reliably signals non-bash. Checking both independently (rather
than a single `BASH_VERSION` check) closes the M-03 edge case: a parent
PowerShell process can inject `BASH_VERSION` into the exported environment
(`$env:BASH_VERSION = "5.0"`), which a spawned non-bash POSIX shell (dash,
ash, busybox) would inherit as a shell variable — making condition 1 alone
insufficient. The `$BASH` variable (bash-only, holds the interpreter's
absolute path) plus the basename check confirms the running interpreter IS
bash and not just a shell with an inherited environment.

The guard fires when:
- Script body is parsed by a non-bash interpreter that proceeds past the
  shebang line: dash, ash, busybox sh, zsh. CI matrix verifies this on Linux
  via explicit `dash scaffold.sh ...` invocation.

The guard cannot fire when:
- Script body is never parsed — e.g., Windows ShellExecute dispatches the file
  to a non-shell handler (Notepad, default app dialog), or the headless
  PowerShell case documented above where PowerShell's `.\<name>` form bypasses
  execution entirely.

This asymmetry is why we treat PowerShell silent-no-op as an **accepted
limitation** rather than a bug to fix in-script: no code inside the script can
defend against scenarios where the script is never executed. Once any
interpreter actually begins parsing the script body, the guard works; when
PowerShell never gets to the guard, there's no defense point inside the file.

### Why this is not Phase-13-blocking

Happy Path verification has passed empirically in both Codex e2e24 and e2e25
runs (50 pytest tests, 77.78% coverage, 6/6 uv lifecycle PASS). The documented
Quick Start (`bash ./scaffold.sh ...`) works reliably. The silent-no-op only
manifests when users deviate from the Quick Start in a specific way that is now
documented here, in SETUP.md § Troubleshooting, and in the Windows warning
block of Quick Start itself.

### Deferred: Python wrapper (Phase 15 candidate)

A `scaffold.py` wrapper that shells out to bash would let users type
`python scaffold.py --pkg ...` from any shell (PowerShell, cmd, bash).
Trade-offs:

- **Prerequisite expansion**: adds Python as a scaffolding prerequisite
  (currently only needed post-scaffold for uv), contradicting ADR-002's "git
  is the only prerequisite" principle.
- **Shim depth illusion**: a thin `subprocess.run(["bash", "scaffold.sh", ...])`
  wrapper eliminates the PowerShell silent-no-op symptom but still requires
  `bash` on PATH — if a user has no bash installed at all, the wrapper fails
  too, just at a different depth ("FileNotFoundError: bash") rather than
  silently succeeding. A **full** silent-no-op fix that works in a bash-less
  environment would require reimplementing scaffold.sh's 8-stage pipeline in
  Python — scope-equivalent to rewriting the script, and needing to track
  every future scaffold.sh change.
- **Maintenance surface**: two sources of truth for the scaffolding logic.

Marked as deferred Phase 15 candidate, not a blocker. The accepted-limitation
framing is preferred until there is concrete user demand for Windows-native
execution without bash.
