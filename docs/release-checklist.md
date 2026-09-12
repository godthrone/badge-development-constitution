# BADGE Constitution — Release Checklist

Maintainer process for releasing this repository. This is **not** a consumer-facing document
(consumer entry point is `README`); it is tracked by git so the process itself is reviewable and
survives across sessions (§17.2, §17.4).

Runtime rule of thumb for this repo: the constitution is a documentation/governance project, so
it is exercised as **Class C** (`--class=C`) — do not run the full Class A Python checks here.

---

## 0. Scope

- [ ] Define what changes: new clause, edit, or bug fix.
- [ ] Version bump per §18.1: **MAJOR** = restructure / incompatible change, **MINOR** = new
      clause or feature, **PATCH** = fix. Record the new version `vX.Y.Z`.

## 1. Edit both language editions in lockstep

- [ ] `BADGE-constitution-vX.Y.Z.zh-CN.md`
- [ ] `BADGE-constitution-vX.Y.Z.en.md`
- [ ] Version string in line 1 of both files.
- [ ] Section structure identical between the two (§17.1 mirror).
- [ ] Cross-references (§a.b) still point at existing sections after any renumbering.

## 2. Rename files when the version changed

- [ ] `git mv BADGE-constitution-vOLD.zh-CN.md BADGE-constitution-vNEW.zh-CN.md`
- [ ] `git mv BADGE-constitution-vOLD.en.md   BADGE-constitution-vNEW.en.md`
- [ ] `grep -rn 'BADGE-constitution-v' .` and update every **hardcoded** filename reference
      (`tools/`, `.gitignore`, work log, `docs/`).
- [ ] Filename-based exemption / regex filters in `tools/` must be **version-independent**
      (prefix match, not exact filename). Regression source: `check_constitution_refs.sh` matched
      `BADGE-constitution\.` and silently stopped exempting the constitution after a version rename.

## 3. Regression — consumer-facing tooling

- [ ] `for f in tools/*.sh; do bash -n "$f"; done`
- [ ] `bash tools/check_all.sh --class=C --meta-pii=fail` (full run; on a WSL `/mnt/c` 9p mount
      prefer `--no-history` or copy to a native disk first — heavy git-history scans can wedge 9p
      into a fake read-only state). `--meta-pii=fail` makes a personal author/committer email a
      hard failure; it is required for public repositories (§15.1 category 5).
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

## 5. Work log (§17.5)

- [ ] Refresh `.local/work_log_current.md` (state area). Keep the "用户原始提示词" anchor frozen —
      append only when the user explicitly changes the goal.
- [ ] Append 3–5 timestamped lines to `.local/work_log_history.md`.
- [ ] `.local/` stays out of git; it is the local-only home for logs and temp files (§16).

## 6. Commit & release

- [ ] Commit message in English, conventional-commit style (§19.1).
- [ ] `git tag vX.Y.Z`.
- [ ] Push branch and tag.
- [ ] Verify the GitHub repository description / latest release still matches the version.
