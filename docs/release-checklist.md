# BADGE Constitution — Release Checklist

Maintainer process for releasing this repository. This is **not** a consumer-facing document
(where a `README` exists it is the consumer entry point; this repository currently has none); it is
tracked by git so the process itself is reviewable and survives across sessions (§17.2, §17.4).

Runtime rule of thumb for this repo: the constitution is a documentation/governance project, so
it is exercised as **Class C** (`--class=C`) — do not run the full Class A Python checks here.

---

## 0. Scope

- [ ] Define what changes: new clause, edit, or bug fix.
- [ ] Version bump per §18.1: **MAJOR** = restructure / incompatible change, **MINOR** = new
      clause or feature, **PATCH** = fix. Record the new version `vX.Y.Z`.

## 1. Edit both language editions in lockstep

- [ ] `BADGE-constitution-vX.Y.Z.zh-CN.md` — a new edition is a **new file**, not a rename:
      `git add` it after editing (an untracked file is invisible to `git commit -a`; see section 6).
- [ ] `BADGE-constitution-vX.Y.Z.en.md` (the English edition is published alongside the Chinese one).
- [ ] Version string in line 1 of every language edition.
- [ ] Section structure identical between every language edition. **This is a maintainer convention
      of this repo, not a §17.1 requirement** — §17.1 mirrors `README.md` / `README.zh-CN.md` only
      and does not constrain the constitution's own language editions.
- [ ] Cross-references (§a.b) still point at existing sections after any renumbering.

## 2. Add the new files and remove the old version

- [ ] `git add BADGE-constitution-vNEW.zh-CN.md && git rm BADGE-constitution-vOLD.zh-CN.md`
      (a new edition is a new file, not a rename; reserve `git mv` for a pure lexical rename).
- [ ] English edition likewise: `git add BADGE-constitution-vNEW.en.md && git rm BADGE-constitution-vOLD.en.md`
      (skip only if that release is Chinese-only).
- [ ] Before removing an old edition, confirm it is recoverable — tracked in git and reachable via a
      tag or blob hash (`git ls-tree <old-tag>`, `git cat-file -p <blob>`) (§2.4 操作防呆 / §3 退路).
- [ ] `grep -rn 'BADGE-constitution-v' --include='*.sh' --include='*.md' --include='*.toml' .` and
      update every **hardcoded** filename reference (`tools/`, `.gitignore`, work log, `docs/`),
      including the **language-suffix** dimension: a tool that assumes `*.en.md` is the version
      source of truth breaks silently when only another language edition is present.
- [ ] Filename-based exemption / regex filters in `tools/` must be **version-independent**
      (prefix match, not exact filename). Regression source: `check_constitution_refs.sh` matched
      `BADGE-constitution\.` and silently stopped exempting the constitution after a version rename.

## 3. Regression — consumer-facing tooling

- [ ] `for f in tools/*.sh; do bash -n "$f"; done`
- [ ] `bash tools/check_all.sh --class=C --meta-pii=fail` (full run; on a WSL `/mnt/c` 9p mount
      prefer `--no-history` or copy to a native disk first — heavy git-history scans can wedge 9p
      into a fake read-only state). `--meta-pii=fail` makes a personal author/committer email a
      hard failure; it is required for public repositories (§15.1 category 5).
- [ ] Re-run the full `check_all.sh --class=C` gate **whenever a constitution filename is changed or
      deleted**, and confirm it actually ran — a silent exit / empty output means the gate did not
      run (e.g. the `.en.md`-hardcoded glob in `check_all.sh`). Re-run it after the language-suffix
      tool fix lands, before tagging.
- [ ] Privacy audit before a public push: `git log --all --format='%an <%ae> %cn <%ce>' | sort -u`
      **and** `git for-each-ref --format='%(taggeremail)' refs/tags | sort -u` must show only
      `noreply@` / project mailboxes (commit author/committer **and** annotated-tag tagger).
      Content, history, and identity metadata are covered by `tools/check_secrets.sh`
      (PII patterns + allowlist; run with `--meta-pii=fail`).
- [ ] Any tool that reads the base config must accept `config.toml` (base default) **and**
      legacy `config_example.toml` / `config_example.yaml` (`check_config_system.sh`,
      `check_directory_layout.sh`, `check_gitignore.sh`, `check_reproducibility.sh`,
      `check_version.sh`).
- [ ] Cross-check that §-numbers quoted in tool comments still match the constitution.

## 4. Stale-reference sweep

- [ ] `grep -rn 'vOLD' .` → no hits.
- [ ] `grep -rn 'config_example\.\(toml\|yaml\)\|config\.yaml' .` → only intentional legacy fallbacks.
- [ ] `grep -rn 'pyyaml' .` → none (TOML is the preferred format; Python 3.11 has `tomllib`).

## 5. Work log (§17.5) — manual check

- [ ] **Manual check, no automation by decision:** `tools/` deliberately ships no work-log script
      (§17.5 is a human handover discipline). Verify by hand that the state area is current and every
      history entry starts with `YYYY-MM-DD HH:MM`.
- [ ] Refresh `.local/work_log_current.md` (state area). Keep the "用户原始提示词" anchor frozen —
      append only when the user explicitly changes the goal.
- [ ] Append 3–5 timestamped lines to `.local/work_log_history.md`.
- [ ] `.local/` stays out of git; it is the local-only home for logs and temp files (§16).

## 6. Commit & release

- [ ] Pre-flight `git status --porcelain`: only this release's changes appear. Isolate unrelated
      uncommitted changes (e.g. a modified `tools/check_reproducibility.sh`) — never let another
      person's in-flight edit ride along in the release commit.
- [ ] Stage the new constitution edition(s) (`git add BADGE-constitution-vX.Y.Z.*.md`); a new file
      left untracked would be missing from the commit and the tag.
- [ ] Commit message follows §19.1: `type: short description` (feat/fix/docs/refactor/test/chore).
      §19.1 **recommends** English; this repo has used English consistently — keep one language
      consistent across the repository.
- [ ] `git tag -a vX.Y.Z -m "..."` (annotated tag, matching the existing tags and the tagger-email
      audit in section 3).
- [ ] Push branch and tag.
- [ ] Verify the GitHub repository description / latest release still matches the version.
