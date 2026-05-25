# Commit

Stage and commit current changes following the standards commit format.
This command is READ-ONLY in analysis; it only writes when the user explicitly approves the commit.

---

## Step 1 — Determine source of truth

Check whether `.claude/context/implementation_state.md` exists and is current:

1. Read the file if it exists
2. Run `git status` and `git branch --show-current`
3. Compare: does the branch in the state file match the current branch? Do the files in the state file roughly match what `git status` shows as staged/modified?

**Path A — State file is current** (file exists, branch matches, files match):
Use `implementation_state.md` as the primary source for commit message and file list.

**Path B — No state file or stale** (file absent, branch mismatch, or significant discrepancy):
Fall back to git as source of truth:
- `git diff --staged` — what is staged
- `git diff` — what is unstaged but modified
- `git log -5` — recent commit context
Derive the commit message from the diff content.

---

## Step 2 — Check for staged changes

Run `git status`. If nothing is staged:
> "Nothing is staged. Stage the files you want to commit first, or run a write operation so the Implementer stages them."

Stop.

---

## Step 3 — Jira ticket

**Path A:** read from `implementation_state.md` → `## Jira Ticket`.
**Path B:** check recent `git log` for a ticket pattern `[A-Z]+-[0-9]+` on the current branch.

If ticket is "not set" or not found in either path, ask:
> "What is the Jira ticket for this work? (e.g. PROJ-123)"

Do not proceed without a ticket ID.

---

## Step 4 — Draft commit message

Format: `PROJ-123 <type>: <description>`

Types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`

**Path A:** derive type and description from `## Summary` in the state file.
**Path B:** derive from `git diff --staged` content.

Keep the description concise (under 72 characters after the ticket prefix).

---

## Step 5 — Present for approval

Show the user:

```
FILES TO COMMIT
───────────────────────────────────────
<list of staged files from git status>

COMMIT MESSAGE
───────────────────────────────────────
<proposed message>
```

Ask:
> "Shall I proceed with this commit? (yes / no / modify message)"

On **no**: stop.
On **modify message**: ask for the revised message, then re-present.
On **yes**: proceed to Step 6.

---

## Step 6 — Commit

Run `git commit -m "<approved message>"`.

Report the commit hash to the user.

---

## Step 7 — Reset implementation state (Path A only)

If using Path A, update `implementation_state.md`:
- Clear the `## Uncommitted Changes` table
- Set `## Change Count` to 0
- Append a line to `## Summary`: `Committed: <hash> — <message>`

Do not delete the file — keep Current Scope, Jira Ticket, and Branch for the next cycle.
