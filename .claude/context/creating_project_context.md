# Project Context Creation Guide

Read this file only when `.claude/context/project_context.md` does not exist.
After the interview is complete, write the result to `.claude/context/project_context.md` and do not read this file again for the rest of the session.

---

## Instructions

Tell the user:

> "No project context found. I need to ask you a few questions to set up the assistant for this project. This takes about 2 minutes and only happens once."

Ask the following checklist in **two batches**.

---

### Batch 1 — Project Identity

Ask all of these together in a single message:

1. **What is this project about?**
   What does it do and who uses it? A few sentences is enough — this helps me understand the domain and work more relevantly.

2. **Is this project starting fresh or already in development?**
   - *Starting fresh* — no existing code yet.
   - *Already in development* — code exists. In this case I will treat standards compliance as an ongoing concern: I will flag violations in existing code when I encounter them and work toward bringing the codebase into compliance over time.

3. **What Jira space or project key is this tracked in?**
   All commits and PRs must reference a Jira ticket. (e.g. `USR`, `PAYM`, `CORE`)

---

### Batch 2 — Tools & Technical Context

Ask these after Batch 1 is answered:

4. **Is there a Bitbucket repository for this project, or will one be created?**
   Provide the repo URL if it exists, or say "to be created" if not yet set up. (Company standard SCM is Bitbucket.)

5. **What Confluence space should documentation be written to?**
   Provide the space key or URL. This is where architecture docs, ADRs, and feature pages will go. (Company standard documentation tool is Confluence.)

6. **What Python version does this project use?** (e.g. 3.12, 3.13)

7. **What libraries are central to this project beyond the standard stack?**
   Skip pydantic, pydantic-settings, requests, pytest — those are company standards. List any additional ones a developer would encounter immediately (e.g. FastAPI, Flask, SQLAlchemy, boto3, celery).

8. **How do you run or start this service?**
   The non-standard command (lint, format, and test commands come from the standards and are already known).

9. **Describe the directory layout.**
   A rough sketch is enough — which folders exist, what goes where. If the project is already in development and you are unsure, say so and I will inspect the directory.

---

## Post-Interview Setup Steps

After both batches are answered, run these setup steps **before** writing project_context.md.

### Step A — Atlassian MCP Check

The Documentator agent requires the Atlassian MCP to interact with Jira and Confluence.

Check whether the MCP is already connected by attempting to list available MCP tools. If the `atlassian` MCP is available, proceed silently.

If it is **not** connected, tell the user:

> "The Documentator agent needs the Atlassian MCP to manage Jira tickets and Confluence pages. You need to connect it once — it uses OAuth so no tokens to manage.
>
> **Setup (30 seconds):**
> 1. Type `/mcp` in Claude Code
> 2. Select **Add Server**
> 3. Enter URL: `https://mcp.atlassian.com/v1/sse`
> 4. Complete the browser OAuth flow with your Atlassian account
>
> Once done, let me know and I'll continue."
>
> Wait for the user to confirm before proceeding.

Record MCP status in the output as `connected` or `not connected — user notified`.

### Step B — Bitbucket Git Setup

After getting the Bitbucket repo answer (question 4):

**If repo URL was provided:**
1. Check if git is already initialized: run `git status`
2. If not initialized: run `git init`
3. Check if a remote named `origin` already exists: run `git remote -v`
4. If no `origin`: run `git remote add origin <url>`
5. Verify SSH access: run `ssh -T git@bitbucket.org`
   - If it fails, tell the user:
     > "Your SSH key is not authorized for Bitbucket. Add your public key to Bitbucket:
     > 1. Go to Bitbucket → Personal Settings → SSH Keys
     > 2. Add this key:
     > ```
     > <contents of ~/.ssh/id_ed25519.pub or ~/.ssh/id_rsa.pub>
     > ```
     > Then run `ssh -T git@bitbucket.org` to verify."
   - Wait for confirmation before continuing.
6. Record git status as `configured — origin set to <url>` or `pending SSH key setup`.

**If "to be created":**
- Run `git init` if not already initialized.
- Record as `repository to be created — git initialized locally`.

---

## Behavioral Rules Based on Answers

**If "already in development" (question 2):**
- Treat the codebase as potentially non-compliant.
- When reading existing files, flag any violations found — even if the user did not ask about them.
- Surface violations as WARNs in the compliance report, not blocking FAILs, unless the user is about to touch that code.
- Goal: bring the codebase into compliance incrementally, following the "incremental improvement" principle from the standards.

**If "starting fresh" (question 2):**
- All new code must be compliant from the first file.
- No legacy tolerance.

**Jira project key (question 3):**
- Use this key in all commit message and PR title suggestions.
- Format: `KEY-<number> <type>: <description>`

**Confluence space (question 5):**
- Reference this space when the Documentator creates or updates pages.
- Architecture decisions, feature overviews, and API docs should point here.

---

## Output Format

Once both batches are answered and setup steps are complete, write `.claude/context/project_context.md` using this structure:

```markdown
# Project Context

## What This Is

<answer to question 1>

## Development Stage

<"Starting fresh" or "Already in development — treat existing code as potentially non-compliant and surface violations incrementally.">

## Stack

- Language: Python <question 6>
- Dependency manager: uv (company standard)
- Test framework: pytest (company standard)
- Validation / config: pydantic, pydantic-settings (company standard)
- Additional libraries: <question 7, or "None beyond company standards">

## Commands

\`\`\`bash
uv run ruff check .           # lint
uv run ruff format .          # format
uv run ruff format . --check  # format check (CI)
uv run pytest                 # run all tests
<run command from question 8>
\`\`\`

## Layout

\`\`\`
<answer to question 9>
\`\`\`

## Project Tracking

- Jira project key: `<question 3>` — all commits and PRs must include the ticket ID
- Confluence space: <question 5>

## Source Control

- Bitbucket repo: <question 4 URL or "to be created">
- Git status: <result of Step B — "configured", "pending SSH key setup", or "repository to be created — git initialized locally">

## Integrations

- Atlassian MCP: <result of Step A — "connected" or "not connected — user notified">

## Project-Specific Constraints

<any constraints that emerged from the interview, or "None beyond company standards.">
```

---

## Closing

After writing the file, tell the user:

> "Project context saved to `.claude/context/project_context.md`. You can edit it any time. Ready to help."

Do not begin any development work before this file is written.
