# Pre-PR Standards Check

You are running a pre-PR compliance check against company engineering standards.
This is a READ-ONLY analysis. Do not modify any files. Do not trigger the write approval flow.
Report findings only.

---

## Step 1 — Determine the diff base

Run:
```bash
git rev-parse --abbrev-ref HEAD
```

Then find the upstream base in this order (stop at first success):
1. `git rev-parse --verify origin/main`
2. `git rev-parse --verify origin/master`
3. `git rev-parse --verify main`
4. `git rev-parse --verify master`

If `$ARGUMENTS` is provided, use it as the base branch and skip auto-detection.

Compute the merge base:
```bash
git merge-base HEAD <base-ref>
```

Store as MERGE_BASE. If no ref resolves, stop and tell the user:
> "Cannot determine base branch. Ensure 'main' or 'master' exists locally or as origin/main."

---

## Step 2 — Identify changed Python files

```bash
git diff --name-only --diff-filter=ACMR <MERGE_BASE>...HEAD
```

Filter to `.py` files only → CHANGED_FILES.

Collect commits:
```bash
git log <MERGE_BASE>..HEAD --format="%H %s"
```
Store as COMMITS (hash + subject per line).

If CHANGED_FILES is empty:
> "No Python files changed since branching from <base-ref>. Nothing to check."
Stop.

---

## Step 3 — Run Ruff

```bash
uv run ruff check --output-format=json <file1> <file2> ...
```

Parse JSON output. Each object has: `filename`, `code`, `message`, `row`, `col`.
Group violations by filename → RUFF_RESULTS[filename].

If ruff is unavailable (command not found), record RUFF_RESULTS = ERROR and continue all other checks.

---

## Step 4 — Read each changed file

Use the Read tool on each file in CHANGED_FILES. Use the content for Steps 5–6.

---

## Step 5 — Check each file against standards

For each file, evaluate every category below. Record PASS, WARN, FAIL, or N/A with specific findings.

### 5A. Style / Ruff
- FAIL: any ruff finding for this file (codes E, F, W, B, N, UP, I).
- PASS: no ruff findings.
- FAIL: RUFF_RESULTS = ERROR → note "ruff could not run".

### 5B. Type Hints
Check all `def` / `async def` statements.
- FAIL: any non-trivial function (has parameters, or body > 2 lines) lacks type annotations on parameters OR lacks `->` return type.
  - Skip: `__init__` return annotation, `*args`/`**kwargs` where annotation is impractical.
- WARN: function uses deeply nested generics (`dict[str, list[dict[str, Any]]]`) instead of a Pydantic model.
- N/A: no function definitions.

### 5C. Docstrings
Check all `def` / `async def` (including `_` prefixed).
- FAIL: any non-trivial function (not a zero-parameter one-liner) lacks a docstring.
- WARN: docstring present but missing `Args:` when parameters exist, or missing `Returns:` when return type is annotated.
- N/A: no function definitions.

### 5D. Error Handling
Scan `try`/`except` blocks.
- FAIL: bare `except:` with no type; or `except Exception: pass`; or exception caught and silenced.
- WARN: `except Exception` used without logging before re-raise; or catch block has no `logger.` call before re-raise.
- N/A: no try/except blocks.

### 5E. External Calls
Patterns to detect: `requests.get(`, `requests.post(`, `requests.put(`, `requests.patch(`, `requests.delete(`, `requests.request(`, `httpx.get(`, `httpx.post(`, `httpx.put(`, `httpx.patch(`, `httpx.delete(`, `urllib.request.urlopen(`, direct `aiohttp.ClientSession()` not inside a class body.
- FAIL: any direct external call found outside a class method body.
- FAIL: any external call (inside or outside a class) with no `timeout=` argument on the call.
- WARN: no retry logic visible (`for attempt`, `tenacity`, `backoff`) in a file that makes external calls.
- N/A: no external HTTP calls detected.

### 5F. Logging
- FAIL: `print(` anywhere outside `if __name__ == "__main__"` blocks.
- FAIL: `logger.` call where `extra=` dict contains a key named `password`, `token`, `secret`, `api_key`, or `credential`.
- WARN: logging calls present but no logger setup in the file (may be imported — flag as WARN, not FAIL).
- N/A: no logging or print statements.

### 5G. Commented-Out Code
Detect consecutive `#` lines containing code patterns (any line with `=`, `(`, `)`, `import`, `return`, `if`, `for`, `class`, `def`, `raise`, `try`, `except`).
- FAIL: commented-out code block with no justification block immediately above it (4+ comment lines explaining why, what it did, what replaced it, and when it can be removed).
- WARN: single isolated commented-out code line with no justification.
- N/A: no commented-out code detected.

### 5H. Function Design
For each function definition:
- FAIL: function name is not a verb. Detect by checking for noun-style prefixes: `data_`, `result_`, `item_`, `user_`, `response_`, `config_`, `error_`, `payload_`, `output_`, `input_`. Also flag single-word nouns: `data`, `result`, `items`, `users`, `payload`.
- WARN: function body exceeds 50 lines.
- WARN: function has more than 4 parameters not consolidated into a model.
- N/A: no function definitions.

### 5I. Security
- FAIL: assignment to a variable whose name (lowercased) contains `api_key`, `secret_key`, `password`, `token`, `credential`, `private_key` where the right-hand side is a string literal.
- FAIL: string matching AWS access key pattern (starts with `AKIA`, 20 uppercase alphanumeric chars).
- WARN: `os.getenv("KEY", "non-empty-default")` where the fallback is a non-empty string value.
- WARN: URL literal containing `10.`, `192.168.`, `localhost`, or `127.0.0.1` assigned to a constant.

### 5J. Configuration
- FAIL: module-level constant assignment where the name suggests config (`*_URL`, `*_HOST`, `*_PORT`, `*_KEY`, `*_SECRET`, `*_PASSWORD`, `*_TOKEN`, `*_DSN`, `*_URI`) and the value is a string or integer literal.
- WARN: file contains configuration-like constants but does not import `BaseSettings` (suggest migration to pydantic-settings).
- N/A: no configuration constants.

### 5K. Testing (source files only — skip test files)
Apply only to files under `src/` or `app/` that are not themselves test files.
Derive expected test path:
- Strip `src/app/` (or `src/` if `app/` is absent) from the path
- Prepend `tests/`
- Prepend `test_` to the filename
- Example: `src/app/services/payment.py` → `tests/services/test_payment.py`

Attempt to Read the expected test file path.
- FAIL: test file does not exist.
- WARN: test file exists but contains test functions not following `test_should_` naming.
- N/A: file is itself a test file, or is not under a `src/`-style directory.

### 5L. Project Structure
- FAIL: `.py` file at project root (exceptions: `conftest.py`, `setup.py`, `manage.py`).
- WARN: source file directly under `src/` without a named layer (`api/`, `services/`, `models/`, `utils/`, `repositories/`, `tasks/`, `workers/`, `schemas/`).
- N/A: file is under `tests/` or is a non-source config file.

---

## Step 6 — Check commit messages

For each entry in COMMITS:
- FAIL: subject does not match pattern `[A-Z]+-[0-9]+` anywhere.
- WARN: subject is fewer than 20 characters total.
- PASS: Jira ticket ID present and message is descriptive.

If project_context.md is loaded and contains the project key, validate against that specific key and flag a different key as WARN.

If COMMITS is empty, note "No commits in range — are you on a feature branch?" and skip this section.

---

## Step 7 — Compile and output the report

Header:
```
PRE-PR STANDARDS CHECK
======================
Branch : <current branch>
Base   : <base-ref> (merge base: <MERGE_BASE short hash>)
Files  : <N> Python file(s) changed
Commits: <N> commit(s) in range
```

Per file — show N/A rows, never omit them (they confirm the category was evaluated):
```
FILE: src/app/services/payment.py
──────────────────────────────────────────────────────────
| Category           | Status | Finding                                       |
|--------------------|--------|-----------------------------------------------|
| Style / Ruff       | PASS   |                                               |
| Type hints         | FAIL   | process_data() missing return type annotation |
| Docstrings         | WARN   | _validate() missing Args: section             |
| Error handling     | N/A    |                                               |
| External calls     | FAIL   | requests.get() called without timeout=        |
| Logging            | PASS   |                                               |
| Commented-out code | N/A    |                                               |
| Function design    | WARN   | handle_request() is 63 lines (guideline ~50)  |
| Security           | PASS   |                                               |
| Configuration      | N/A    |                                               |
| Testing            | FAIL   | tests/services/test_payment.py not found      |
| Project structure  | PASS   |                                               |
```

If a file has zero findings (all PASS or N/A), compress to one line:
```
FILE: src/app/utils/helpers.py — ALL CHECKS PASSED
```

Commit section:
```
COMMIT MESSAGES
───────────────────────────────────────────────────────────
| Commit  | Status | Subject                                  |
|---------|--------|------------------------------------------|
| abc1234 | PASS   | PROJ-42 feat: add payment timeout        |
| def5678 | FAIL   | fix bug in user service                  |
| ghi9012 | WARN   | PROJ-43 fix                              |
```

Summary table (aggregate counts across all files):
```
SUMMARY
───────────────────────────────────────────────────────────
| Category           | PASS | WARN | FAIL |
|--------------------|------|------|------|
| Style / Ruff       |  3   |  0   |  1   |
| Type hints         |  2   |  0   |  1   |
| Docstrings         |  3   |  1   |  0   |
| Error handling     |  1   |  1   |  0   |
| External calls     |  1   |  1   |  1   |
| Logging            |  4   |  0   |  0   |
| Commented-out code |  2   |  1   |  0   |
| Function design    |  3   |  1   |  0   |
| Security           |  4   |  0   |  0   |
| Configuration      |  2   |  0   |  1   |
| Testing            |  2   |  0   |  2   |
| Project structure  |  4   |  0   |  0   |
| Commit messages    |  1   |  1   |  1   |
```

Verdict:
- Zero FAILs across all files and commits:
  `READY — All checks passed. Safe to open the PR.`
- Zero FAILs, at least one WARN:
  `READY (WITH WARNINGS) — No FAILs found. <N> WARN(s) noted above — review before opening the PR.`
- Any FAIL:
  `NEEDS FIXES — <N> FAIL(s) found across <M> file(s) and <K> commit(s). Fix all FAILs before opening the PR. WARNs are your call.`

---

## Behavior Rules

- READ-ONLY throughout. Do not offer to fix any issues. Do not enter the write approval flow.
- Do not re-read standards.md or project_context.md if already loaded in session.
- N/A rows must appear in every per-file table — never omit them.
- If a file cannot be read, skip it and note "could not read file" in the report.
- If ruff is not installed, mark Style/Ruff as FAIL with note "ruff not available — run `uv sync` to install" and continue all other checks.
