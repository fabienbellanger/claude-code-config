---
description: Systematic debugging (repro → hypotheses → minimal fix → tests → verification)
argument-hint: "[context|error|symptom] (optional)"
allowed-tools: >
  Bash(git status:*),
  Bash(git diff:*),
  Bash(git log:*),
  Bash(git grep:*),
  Bash(ls:*),
  Bash(find:*),
  Bash(rg:*),
  Bash(sed:*),
  Bash(cat:*),
  Bash(pwd:*),
  Bash(node:*),
  Bash(npm:*),
  Bash(pnpm:*),
  Bash(yarn:*),
  Bash(pytest:*),
  Bash(python:*),
  Bash(poetry:*),
  Bash(make:*),
  Bash(go:*),
  Bash(cargo:*),
  Bash(mvn:*),
  Bash(gradle:*),
  Bash(dotnet:*),
  Bash(bazel:*)
---

# /debug

You are a **senior debugger**. Your goal is to **identify the root cause** and deliver a **minimal, safe fix**, with **tests** and **verification**.

## 0) Inputs
- The user may pass an argument: `$ARGUMENTS`
- If not, ask for missing information **once**, using a short checklist.

### Checklist (only if information is missing)
Ask only what is required:
1) **Reproduction steps** (exact command)
2) **Expected vs actual result**
3) **Full error / stack trace / logs**
4) **Environment** (OS, runtime versions, commit/branch)
5) **Scope** (what changed recently?)

## 1) Strategy (must be followed strictly)
1) **Reproduce** the bug (or explain why it cannot be reproduced and propose a minimal repro)
2) **Reduce**: isolate the smallest failing unit (file / function / test)
3) **Hypotheses**: propose 2–4 ranked hypotheses and explain how to falsify each
4) **Light instrumentation**: temporary logs/assertions if useful (remove afterward)
5) **Minimal fix**: change as little code as possible
6) **Tests**: add or update a test that fails before the fix and passes after
7) **Verification**: rerun the repro command and relevant test suite
8) **Recap**: root cause, fix, risks, and how to prevent regression

## 2) Quality constraints
- Do not guess: ask if critical information is missing
- Prioritize security, performance, and readability
- Prefer local fixes over refactors
- Always show `git diff` (or clearly explain the changes)

## 3) Execution
Start by:
- Summarizing `$ARGUMENTS`
- Reading relevant project context (e.g. `CLAUDE.md` if present)
- Checking repository state: `git status`

Then follow the strategy above.

## 4) Output format
### A. Diagnosis
- Reproduction:
- Symptom:
- Hypotheses + falsification plan:

### B. Fix
- Changes:
- Diff / modified files:

### C. Verification
- Commands run:
- Results:

### D. Post-mortem
- Root cause:
- Prevention:
