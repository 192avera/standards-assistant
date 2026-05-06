# standards-assistant

A portable Claude Code workflow that enforces company engineering standards in any Python project.

Drop the `.claude/` directory and `CLAUDE.md` into a project root and the assistant will:
- Interview you to create a project context on first open (once per project)
- Enforce all company standards on every proposed change
- Always ask before writing or modifying any file
- Flag violations before presenting changes for approval
- Notify you when a newer version of the standards is available

---

## Install

Run from this directory, pointing at your target project:

```bash
bash install.sh ~/path/to/your-project
```

This copies the workflow files into the target project and records the installed version. Your existing `project_context.md` is never overwritten.

## Update

Re-run `install.sh` to pull the latest standards into a project:

```bash
bash install.sh ~/path/to/your-project
```

Or from within the project, check if an update is available:

```bash
bash .claude/check-updates.sh
```

The assistant also checks for updates automatically on every session start.

## What gets installed

```
CLAUDE.md                                  ← entry point
.claude/
  agents/
    coordinator.md                         ← approval gate, session entry
    implementer.md                         ← writes code after approval
    reviewer.md                            ← standards compliance checker
  context/
    standards.md                           ← full company engineering standards
    creating_project_context.md            ← interview guide (runs if no context exists)
  check-updates.sh                         ← version check script
  settings.json                            ← pre-allowed commands (ruff, pytest)
```

## What does NOT get installed

`.claude/context/project_context.md` — this is generated per project through the setup interview and is never overwritten by updates.

## First open

Open Claude Code in the target project. On your first message, the assistant will detect that no `project_context.md` exists and run a short interview (about 2 minutes). After that it is ready for development.

---

## Standards covered

Python style · Type hints · Docstrings · Error handling · External calls · Logging · Function design · Security · Dependencies · Configuration · Testing · Project structure · Docker · Git workflow
