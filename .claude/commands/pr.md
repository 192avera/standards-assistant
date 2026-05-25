# PR

Draft and open a pull request for the current branch.
This command is READ-ONLY in analysis; it only writes when the user explicitly approves the PR.

---

## Step 1 — Determine source of truth

Check whether `.claude/context/implementation_state.md` exists and is current:

1. Read the file if it exists
2. Run `git branch --show-current` and `git status`
3. Compare: does the branch in the state file match the current branch?

**Path A — State file is current** (file exists, branch matches):
Use `implementation_state.md` as the primary source for PR content.

**Path B — No state file or stale** (file absent or branch mismatch):
Fall back to git as source of truth:
- Determine base branch: try `origin/main`, then `origin/master`, then `main`, then `master`
- Run `git merge-base HEAD <base>` to get MERGE_BASE
- Run `git log <MERGE_BASE>..HEAD --format="%H %s"` for commits in range
- Run `git diff <MERGE_BASE>...HEAD --name-only` for changed files
- Run `git diff <MERGE_BASE>...HEAD` for full diff content
Derive PR content from commits and diff.

---

## Step 2 — Check for unpushed or uncommitted changes

Run `git status` and `git log origin/<branch>..HEAD 2>/dev/null`.

If there are **uncommitted staged changes**:
> "There are staged but uncommitted changes. Run `/commit` first before opening a PR."
Stop.

If there are **commits not yet pushed**, note this — the push will happen in Step 6 before opening the PR.

---

## Step 3 — Jira ticket

**Path A:** ask the user for the Jira ticket — the state file no longer tracks it.
**Path B:** scan commit messages in range for `[A-Z]+-[0-9]+` pattern.

If not found in either path, ask:
> "What is the Jira ticket for this work? (e.g. PROJ-123)"

Do not proceed without a ticket ID.

---

## Step 4 — Run pre-PR standards check

Run the same analysis as `/pre-pr-check` against the changed files.

If FAILs are found, present the report and ask:
> "There are standards violations in this branch. Open the PR anyway, or fix them first?"

Wait for user choice before proceeding.

---

## Step 5 — Draft PR description

**Title:** `PROJ-123: <concise description>` (under 70 characters)

**Path A:** derive What and Why from `## Scope` and `## Log` in the state file.
**Path B:** derive from commit messages and diff content.

```
## What
<summary of what changed>

## Why
<motivation and link to Jira ticket: PROJ-123>

## Testing
<what was tested — ruff status, pytest results, manual steps if any>

## Risk / Rollback
<risk assessment and how to revert if needed>
```

---

## Step 6 — Present for approval

Show the user:

```
BRANCH  : <current branch>
BASE    : <base branch>
COMMITS : <N> commit(s)
FILES   : <N> file(s) changed

PR TITLE
────────────────────────────────────────
<proposed title>

PR DESCRIPTION
────────────────────────────────────────
<full description>
```

Ask:
> "Shall I open this PR? (yes / no / modify)"

On **no**: stop.
On **modify**: ask what to change, update the draft, re-present.
On **yes**: proceed to Step 7.

---

## Step 7 — Push and open PR

1. If branch has unpushed commits: run `git push -u origin <branch>`
2. Open PR: `gh pr create --title "<title>" --body "<description>"`
3. Report the PR URL to the user

---

## Step 8 — Update implementation state (Path A only)

If using Path A, append to `## Log` in `implementation_state.md`:
`PR opened: <PR URL>`
