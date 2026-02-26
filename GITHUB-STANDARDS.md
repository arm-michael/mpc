# GITHUB-STANDARDS.md — Shared GitHub Best Practices

> Version: 2.0
> Authoritative source for all Git, GitHub repo setup, branching, commit, and PR standards.
> SWE agent follows this for all operations. PM, TPM, and UI/UX agents are read-only consumers.

---

## Core Philosophy

Git history is documentation. Every commit, branch, and PR tells a story about why the codebase
changed. A future engineer reading your history should be able to reconstruct your reasoning
without ever asking you. Write for them.

---

## Step 0 — Initialize a New Repo (Start Here)

Before any code is written, the SWE agent must initialize and wire up the GitHub repository.
Run these steps once, in order, at the start of every new project.

```bash
# 1. Initialize git in the working directory
git init

# 2. Create a .gitignore appropriate for the project stack
# (Node, Python, etc. — use gitignore.io or GitHub's templates)

# 3. Create an initial README.md with the project name and one-line description
# (PM agent provides the description)

# 4. Make the initial commit
git add .gitignore README.md
git commit -m "chore: initialize repository"

# 5. Create the GitHub repo (private by default; adjust if needed)
gh repo create <org-or-username>/<repo-name> --private --source=. --push

# 6. Set default branch to main (if not already)
git branch -M main
git push -u origin main

# 7. Configure branch protection on main via GitHub UI or:
gh api repos/<org>/<repo>/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":[]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field restrictions=null

# 8. Confirm remote is set correctly
git remote -v
```

**Checklist before first feature branch:**
- [ ] Repo created on GitHub
- [ ] `main` is protected (no direct pushes)
- [ ] `.gitignore` committed
- [ ] `README.md` committed
- [ ] CI/CD pipeline stub added (even if empty) under `.github/workflows/`

---

## Agent Access Model

| Action | PM | TPM | UI/UX | SWE |
|--------|----|-----|-------|-----|
| Read PRs, issues, releases | ✅ | ✅ | ✅ | ✅ |
| Comment on PRs | ✅ product scope | ✅ program scope | ✅ design scope | ✅ |
| Approve PRs | ❌ | ❌ | ✅ design scope | ✅ |
| Open PRs | ❌ | ❌ | ❌ | ✅ |
| Create/push branches | ❌ | ❌ | ❌ | ✅ |
| Write commits | ❌ | ❌ | ❌ | ✅ |
| Merge PRs | ❌ | ❌ | ❌ | ✅ |
| Create releases/tags | ❌ | ❌ | ❌ | ✅ |
| Create Issues (bug reports) | ✅ reference | ✅ reference | ✅ reference | ✅ |
| Manage branch protection | ❌ | ❌ | ❌ | ✅ (with approval) |

---

## Branching Strategy

### Branch Model: GitHub Flow (default)

```
main (protected, always deployable)
├── feat/<ticket>-<description>
├── fix/<ticket>-<description>
├── refactor/<ticket>-<description>
├── chore/<ticket>-<description>
├── docs/<ticket>-<description>
├── test/<ticket>-<description>
├── perf/<ticket>-<description>
├── ci/<ticket>-<description>
├── release/<version>         (for versioned products)
└── hotfix/<ticket>-<description>  (emergency production fixes only)
```

For monorepos, add scope after type:
```
feat/api/<ticket>-token-refresh-endpoint
feat/web/<ticket>-login-form-ui
```

### Branch Naming Rules

```
<type>/<ticket>-<short-description>

Rules:
- All lowercase
- Hyphens only (no underscores, no spaces)
- Ticket/issue reference REQUIRED (e.g., GH-42, MPC-7, or issue number)
- Description: 3–5 words, imperative mood
- Max 60 characters total

✅ Good:
  feat/42-login-validation
  fix/99-token-expiry-crash
  refactor/12-auth-service-cleanup
  chore/7-update-dependencies

❌ Bad:
  feature/login             (no ticket, too vague)
  42                        (no type prefix)
  feat/42_loginFix          (underscore, camelCase)
  johns-branch              (no structure)
  fix-that-bug              (no ticket)
```

### Branch Lifecycle

```bash
# 1. Always start from default branch
git checkout main && git pull --ff-only

# 2. Create feature branch
git checkout -b feat/42-login-validation

# 3. Work, commit, push
git push -u origin feat/42-login-validation

# 4. Open PR
gh pr create --title "feat(auth): add login validation (#42)"

# 5. After PR merged: delete branch immediately
git checkout main && git pull --ff-only
git branch -d feat/42-login-validation
git push origin --delete feat/42-login-validation
git fetch --prune
```

**Stale branch policy:**
- Branches unmerged after 14 days require a comment explaining why
- Branches unmerged after 30 days are flagged for deletion unless actively being worked

---

## Commit Standards

### Commit Message Format (Conventional Commits)

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Subject line rules:**
- Imperative mood: "add", "fix", "update" — NOT "added", "fixes", "updating"
- Lowercase, no period at end
- Max 72 characters
- Must complete: "If applied, this commit will: ___"

**Body rules:**
- Wrap at 72 characters
- Explain WHAT and WHY — not HOW (the diff shows how)
- Separate from subject with a blank line
- Optional but strongly encouraged for non-trivial changes

**Footer rules:**
- Issue/ticket reference: `Closes #42` or `Refs #42`
- Breaking changes: `BREAKING CHANGE: <description>`

### Commit Types

| Type | Use for |
|------|---------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code change that doesn't fix a bug or add a feature |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `chore` | Build process, tooling, dependencies |
| `perf` | Performance improvements |
| `ci` | CI/CD configuration |
| `build` | Changes affecting the build system |
| `revert` | Reverts a previous commit |
| `style` | Formatting only (no logic change) |

### Commit Examples

```
✅ Good:

feat(auth): add email validation on login form

Validates email format client-side before submission to reduce
unnecessary API calls and improve error feedback speed.
Regex pattern matches RFC 5322 simplified standard.

Closes #42

---

fix(api): handle 429 rate limit response from payment provider

Previously, a 429 from Stripe caused an unhandled exception that
returned a 500 to the client. Now returns a structured 503 with
a Retry-After header matching the upstream value.

Closes #99

---

chore: update axios from 1.4.0 to 1.6.2

Security patch for CVE-2023-45857. No API surface changes.

Refs #103

---

❌ Bad:

fix stuff
WIP
#42
fixed the login bug finally
updated code
Merge branch 'main' into my-branch
```

### Atomic Commits

Each commit must represent exactly one logical change:
- One bug fix per commit
- One feature per commit (split large features into logical steps)
- Never mix refactors with features
- Never mix dependency updates with feature work
- If you write "and" in your subject line → split into two commits

---

## Pull Request Standards

### PR Size Rules

| Size | Lines Changed | Policy |
|------|--------------|--------|
| Small | < 200 lines | Preferred. Aim for this. |
| Medium | 200–500 lines | Acceptable. Add extra context in description. |
| Large | 500–1000 lines | Requires justification in description. |
| X-Large | > 1000 lines | Must be split. Requires TPM + lead approval. |

### PR Title Format

```
<type>(<scope>): <description> (#<issue>)

Examples:
  feat(auth): add password reset via email (#42)
  fix(api): handle null session on token refresh (#99)
  refactor(dashboard): extract widget into reusable component (#61)
```

### PR Description Template

```markdown
## Summary
<1-2 sentences: what this PR does and why>

## Issue
Closes #<issue-number>

## Changes
- <change and why>
- <change and why>

## How to Test
1. <step>
2. <step>
Expected result: <result>

## Screenshots / Recordings
<For UI changes: before/after screenshots — required>

## Review Guide (for large PRs only)
Start here: <filename>
Key logic: <filename, line range>
Skip (auto-generated): <filename>

## Testing
- [ ] Unit tests added or updated
- [ ] Integration tests added or updated
- [ ] All existing tests passing locally
- [ ] Manual smoke test completed

## Checklist
- [ ] Acceptance criteria from issue are met
- [ ] No stubs, hardcoding, or disabled logic
- [ ] Existing codebase patterns reused
- [ ] No secrets or credentials in code
- [ ] Breaking change documented (if applicable)
- [ ] Rollback plan documented

## Breaking Change
<yes/no. If yes: what breaks, who is affected, migration steps>

## Rollback Plan
<How to safely revert if this causes issues in production>

## Risk
<What could go wrong? Severity?>
```

### PR Lifecycle

```
1. Open PR → assign reviewer(s)
   - Minimum 1 reviewer for all PRs
   - 2 reviewers for: security changes, data model changes, > 500 lines

2. Draft PRs
   - Use for work in progress — do not review until marked ready
   - Convert to ready when all checklist items are met

3. Review SLA
   - Reviewer must respond within 1 business day
   - No response in 1 day: ping + add needs-review label
   - No response in 2 days: escalate to TPM

4. Addressing feedback
   - Respond to every comment (resolve or discuss)
   - New commits for feedback: "fix: address review — <detail>"
   - Do not force-push after review starts
   - Request re-review explicitly after addressing all comments

5. Approval & Merge
   - Squash & merge is the default
   - Never self-merge without at least one approval
   - Never merge with unresolved review comments

6. Post-merge
   - Delete remote branch immediately
   - Clean up local branch
   - Close or transition the linked issue
   - Add PR link as comment on the issue if not auto-linked
```

### Review Comment Conventions

```
[BLOCKER]    — Must fix before merge
[SUGGESTION] — Would improve code but not required
[QUESTION]   — Seeking understanding, not requesting change
[NIT]        — Trivial style point, take it or leave it
[PRAISE]     — Acknowledge good work

[DESIGN]     — Used by UI/UX agent for design compliance issues
[PRODUCT]    — Used by PM agent for acceptance criteria issues

Examples:
[BLOCKER] This will throw a NullPointerException if user.profile is null.
[SUGGESTION] We have a formatDate utility in /utils/date.ts that does this.
[QUESTION] Why are we using a Set here instead of a Map?
[NIT] Prefer const over let here since this is not reassigned.
[PRAISE] Clean abstraction — this makes the auth flow much easier to follow.
[DESIGN] Button color does not match approved design — should be #0057FF not #0060AA.
[PRODUCT] This state does not satisfy AC-3: the error message must include a retry link.
```

---

## Branch Protection Rules

Configure on `main` (and `develop` if used):

```
Required settings:
  ✅ Require pull request before merging
  ✅ Require approvals: minimum 1 (2 for sensitive paths)
  ✅ Dismiss stale approvals when new commits are pushed
  ✅ Require status checks to pass (CI, tests, lint)
  ✅ Require branches to be up to date before merging
  ✅ Require conversation resolution before merging
  ✅ Do not allow force pushes
  ✅ Do not allow deletions
```

CODEOWNERS for 2-approval paths:
```
# .github/CODEOWNERS
/auth/**          @eng-lead
/payments/**      @eng-lead
/.env.example     @eng-lead
/migrations/**    @eng-lead
```

---

## Release & Tagging Standards

### Semantic Versioning

```
MAJOR.MINOR.PATCH

MAJOR — Breaking change (incompatible API change)
MINOR — New feature (backward compatible)
PATCH — Bug fix (backward compatible)

Pre-release: 1.2.0-beta.1, 1.2.0-rc.1
```

### Release Branch

```bash
# Cut from main
git checkout main && git pull --ff-only
git checkout -b release/1.2.0

# Only bug fixes and docs on release branches — no new features

# Tag after QA sign-off
git tag -a v1.2.0 -m "Release v1.2.0 — <one-line summary>"
git push origin v1.2.0

# Merge back to main via PR
gh pr create --base main --head release/1.2.0 --title "release: v1.2.0"
```

### Hotfix Process

```bash
# Branch from main — not from a feature branch
git checkout main && git pull --ff-only
git checkout -b hotfix/999-payment-crash-on-null-card

git commit -m "fix(payments): handle null card object on checkout (#999)"

gh pr create --title "HOTFIX: fix null card crash in payments (#999)"

# After merge: tag immediately
git tag -a v1.2.1 -m "Hotfix v1.2.1 — fix null card crash"
git push origin v1.2.1
```

---

## GitHub Issues

- **GitHub Issues** = source of truth for all work tracking on this project
- Use labels to classify: `bug`, `feat`, `chore`, `docs`, `blocked`, `needs-review`
- Every branch and PR must reference an issue number
- Never do untracked work — open an issue first, then branch

---

## CI/CD Expectations

Required checks before merge:
```
- lint          (ESLint, Prettier, or equivalent)
- type-check    (TypeScript, mypy, etc.)
- unit-tests    (Jest, pytest, etc.)
- build         (must compile successfully)

Recommended:
- integration-tests
- security-scan (Snyk, Dependabot, CodeQL)
- coverage-check (fail if coverage drops below threshold)
```

The SWE agent never merges a PR with failing checks. Flaky tests get a `fix/flaky-test` issue before proceeding.

---

## Anti-Patterns — Never Do These

| Anti-Pattern | Why It's Wrong | What to Do Instead |
|-------------|---------------|-------------------|
| Push directly to `main` | Bypasses review and testing | Always use a PR |
| Force push to shared branch | Destroys collaborators' history | Communicate + coordinate |
| Commit secrets or tokens | Permanent security breach | Use env vars, secret managers |
| Giant PRs (> 1000 lines) | Unreviewable | Split into smaller PRs |
| "WIP" commits in final history | Pollutes history | Squash before merge |
| Merge main into feature branch | Creates ugly merge commits | Use `git rebase main` |
| Commenting out code | Leaves dead code | Delete it (git history preserves it) |
| TODO without issue | Lost forever | `// TODO(#42): description` |
| Merging without review | No second set of eyes | Wait for approval |
| Stale branches (> 30 days) | Drift and conflicts | Merge or delete |
| Skipping repo init checklist | Missing protection/CI from day one | Always run Step 0 |
