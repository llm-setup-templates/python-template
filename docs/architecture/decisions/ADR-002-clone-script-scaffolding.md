# ADR-002: Clone + Script Scaffolding over gh --template

Status: Accepted (2026-04-23)
Supersedes: Implicit Phase 0 flow in SETUP.md (pre-Phase-13, removed)
Related: ADR-001 (pytest-cov 60% threshold — unchanged)

## Context

Through Phase 12, `SETUP.md` began every session with a `gh repo create --source=.`
call, making GitHub CLI a **hard dependency for Phase 0**. Phase 5.5 then
cloned `/tmp/ref-python` with `gh repo clone`, and Phase 8 pushed with `gh
run watch`. Four distinct gh calls, the earliest at the very first step.

On **2026-04-23**, the Codex e2e23 dry run empirically demonstrated the
failure mode this causes:

- Codex's sandbox runs inside a Linux container (paths like `/mnt/c/...`
  are WSL-style interop mappings to the host Windows filesystem)
- `gh` is not pre-installed in that sandbox
- The SETUP.md directive "Use Bash (Git Bash on Windows)" is ambiguous —
  Codex interpreted it as "any bash", which in its sandbox means Linux bash
- Codex spent 2m 26s attempting to locate Windows `gh.exe` via `/mnt/c/`
  interop, hitting quoting + IO encoding failures, and **never reached
  Phase 1**
- The preceding Phase 12 Fix 1–6 (merge commit `926b1b1`) didn't address
  this because they tightened individual steps but kept the coupling
  between "obtain template files" and "connect to GitHub" intact

## Decision

Separate "obtain template files" from "connect to GitHub":

1. **Template acquisition**: `git clone https://github.com/.../python-template`.
   Requires only `git` (already present in every environment that can edit
   files, including Codex's sandbox).
2. **Customization**: `./scaffold.sh --pkg <name> --archetype <type>`.
   Requires only `bash` ≥ 4.0. No network calls, no `gh`, no `curl`.
3. **GitHub connection (optional)**: `gh repo create` + `git push`. Moved to
   a separate `Publish to GitHub` section in SETUP.md § 4. Users who publish
   to private GitLab, self-hosted Gitea, or keep the repo local can skip
   this entire section.

scaffold.sh is single-use (detects `validate.sh` presence as freshness marker)
and self-deletes on success (Linux/macOS; Windows Git Bash prints a warning
and asks for manual deletion due to file locks on the running script).

## Alternatives considered

### A. `gh repo create --template llm-setup-templates/python-template` (rejected)

Server-side templating via GitHub API. Clone-less, but:

- Still requires `gh` at step 1 → **does not solve the Codex blocker**
- Auto-creates an "Initial commit" message that violates the Conventional
  Commits gate in our own Phase 8 (empirically confirmed in Phase 06 notes)
- No access to substitute placeholders before first commit (user must
  rewrite history, which breaks the "one clean initial commit" contract)

### B. degit (tarball download) (rejected)

`npx degit user/repo target-dir` downloads the tarball without `.git`.
Clean, no git reinit step needed. But:

- Adds `npm` (Node.js) as a prerequisite — heavier than git for Python
  users who may not have Node installed
- Loses the ability to `git pull` future template updates into the derived
  repo (users who want that have to re-clone anyway, so this is a shallow
  benefit — but the added dependency is not)

### C. Keep current Phase 0 flow + add Codex-specific Troubleshooting (rejected)

The "add a 7th Fix" path. Rejected because:

- Phase 12 Fix 1–6 were already accumulating environment-specific
  workarounds (PowerShell encoding, CODEOWNERS whitespace, Dependabot
  race, CI no-run recovery). Adding a 7th doesn't stop the 8th
- The underlying coupling (file acquisition ⊗ GitHub connection) is the
  root cause; Troubleshooting entries only paper over symptoms

## Consequences

### Positive

- **Single-dependency scaffolding**: `git` is enough. Any environment that
  can `git clone` over HTTPS can scaffold, including Codex sandboxes,
  air-gapped CI runners with git proxies, or GitLab / Gitea mirrors
- **Executable documentation**: scaffold.sh IS the scaffolding logic.
  SETUP.md shrinks from 970 lines to ~200 lines and documents "why /
  when / how to call" rather than "paste these 40 bash commands in order"
- **CI regression coverage**: scaffold.sh's behavior is now testable in
  `.github/workflows/validate.yml` via `test/scaffold-e2e.sh` (3-archetype
  matrix). Bugs in scaffolding are caught before they reach users
- **Decoupled gh**: publishing to GitHub is optional. The template is no
  longer a GitHub-first artifact

### Negative

- **scaffold.sh is a new, load-bearing file**: bugs here break all users.
  Mitigated by scaffold-e2e CI matrix + `--dry-run` flag + single-use
  freshness check
- **Single-use constraint surprises users**: re-running scaffold.sh errors
  out with "validate.sh not found". This is intentional (idempotent sed
  substitutions are fragile) but the error message must be clear. We
  instruct users to re-clone rather than retry
- **Windows self-delete caveat**: scaffold.sh can't delete itself on
  Windows Git Bash (file lock). We warn and ask for manual cleanup. This
  is the cleanest outcome available without invoking an out-of-process
  helper
- **Phase 0.5 `/tmp/ref-python` concept deleted**: pre-Phase-13 SETUP.md
  used a reference clone to copy template files. In the clone+script
  architecture, the cloned directory IS the reference — no separate copy
  needed. Users relying on that pattern (e.g., external docs) get a
  redirect hint in SETUP.md § 4

## Implementation trail

- Plan: `.plans/llm-setup/13-clone-script-architecture/PLAN.md` (rev.2)
- Discussion: `.plans/llm-setup/13-clone-script-architecture/DISCUSS.md`
- Review (Reality Lens, 5 Critical/High → resolved in rev.2):
  `.plans/llm-setup/13-clone-script-architecture/REVIEW.md`
- Direct driver: Codex e2e23 transcript (2026-04-23, `/mnt/c/...` paths,
  2m 26s exhaustion before Phase 1 completion)
