---
description: Commit the current changes (structured message) and push to the remote
argument-hint: "[language]"
---

# /gitcp — Structured commit + push

Same as `/gitc`, then push the resulting commit to the remote.

## Language argument

`$ARGUMENTS` selects the commit message language. Normalize as follows:

- empty / missing → **English** (default)
- `en`, `english`, `anglais` → English
- `fr`, `french`, `français`, `francais` → French
- `es`, `spanish`, `espagnol`, `español` → Spanish
- `de`, `german`, `allemand`, `deutsch` → German
- anything else → fall back to English and mention it in your reply

## Steps

1. Run these in parallel:
   - `git status` (no `-uall` flag)
   - `git diff` (staged + unstaged combined)
   - `git log -5 --oneline` to match the repo's style
   - `git rev-parse --abbrev-ref HEAD` to know the current branch
   - `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null` to know whether an upstream is set

2. If there is nothing to commit, **skip the commit step** and go straight to step 6 (the user may just want to push existing local commits). If there is also nothing to push, stop and report it.

3. Draft a commit message in the chosen language with this **exact structure**:

   ```
   <one-line summary of the main change, < 70 chars, no trailing period>

   🔥 Feature: <what was added>
   ♻️ Refactor: <what was restructured>
   🩹 Fix: <what was fixed>
   🚨 Test: <what tests changed>
   📚 Doc: <what docs changed>
   🎨 Style: <formatting / UI styling>
   ```

   Rules for the message:
   - The first line is a **plain summary**, no emoji, no prefix.
   - Then **only include the bullet lines that actually apply** — drop categories with no matching change.
   - Keep the language **simple and readable, even for non-native speakers**. Short sentences, common words, no jargon.
   - Group related files under the same bullet rather than one bullet per file.
   - Never invent changes that aren't in the diff.

4. Stage the relevant files **explicitly by name** (do not use `git add -A` or `git add .`). Skip any file that looks like a secret (`.env`, `*.pem`, `credentials*`, etc.) and warn the user if such a file is among the changes.

5. Create the commit using a HEREDOC so newlines are preserved:

   ```bash
   git commit -m "$(cat <<'EOF'
   <message here>
   EOF
   )"
   ```

   **Do NOT add a `Co-Authored-By: Claude ...` trailer** — this project forbids it (see CLAUDE.md).

   If a pre-commit hook fails, fix the underlying issue, re-stage, and create a **new** commit (never `--amend`).

6. **Push** to the remote:
   - If an upstream is already set → `git push`
   - If no upstream is set → `git push -u origin <current-branch>`
   - **Never** use `--force` or `--force-with-lease` here. If the push is rejected (non-fast-forward), stop, show the error, and ask the user how to proceed.
   - **Never** push to `main` or `master` if the current branch is `main`/`master` and the push would be a force-push — refuse and warn.

7. After pushing, report:
   - The commit short SHA + subject (if a commit was made)
   - The branch that was pushed and the upstream it tracks
   - The PR URL if `gh` returns one for this branch (best-effort, ignore errors)
