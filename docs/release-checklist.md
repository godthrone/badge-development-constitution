# BADGE Constitution — Release Checklist

This file is the sole authoritative source for this repository's release procedure. It describes steps and cites `§` numbers only — it does not restate clause text (§17.2 process-document exception, §17.8 sole-landing rule).
It is git-tracked so it survives sessions (§17.4).

Run each check below as **Class C** (`--class=C`); which clauses bind a Class C project is decided by §17.8, not by this file.
Do not start §2, tag, or push until §1 is green. If this file and the constitution disagree, follow the constitution.

## 0. Scope and version

- [ ] Define what changes: new clause, edit, or bug fix.
- [ ] Bump the version per §18.1 and record it here.
- [ ] If this release is the **layered restructure**, say so here. The tagging pass must satisfy §17.8's
      four conditions; record the evidence in the commit message.

## 1. Chinese final-text review — BLOCKING GATE

Read `BADGE-constitution-vX.Y.Z.zh-CN.md` clause by clause — a *read*: items 8–9 credit 1–7.

- [ ] **1. Logical contradiction** — clause against clause and against 总纲 / 第〇层, especially whether
      a clause's *applies-when* condition and its marker contradict. Read bodies, not just
      cross-references. *Criterion:* clauses on one action can both hold, or a stated rule resolves it.
- [ ] **2. Internal inconsistency** — terminology (`L1`/`L2`/`L3`, `M`/`R`, `A`/`B`/`C`, trigger words),
      numbering and definitions each have one home. *Criterion:* each term and each `§a.b` resolves to a
      single defining site, and every reference resolves at all.
- [ ] **3. Duplicated content** — one requirement stated in several places, repeated paragraphs, and
      spots that should be "defined once, pointed at elsewhere". *Criterion:* every requirement has one
      normative home; every other mention is a bare pointer.
- [ ] **4. Markers match their body** — each heading's marker (layer/mode/category/trigger) is earned
      by its text, the vocabulary is the §17.8 closed set, and `宪自` has a definition. *Criterion:* the
      marker alone tells whether the clause binds a reader, and none is marked weaker or narrower than
      its own wording.
- [ ] **5. Agreement with `tools/`** — every `§` in a tool comment still names an existing section,
      tool behaviour matches its clause (an opt-in check is not an unconditional mandate), and every
      clause that defers to a script still holds. *Criterion:* each cited `§` names a section that says
      what the tool does — and vice versa.
- [ ] **6. Boundary with `docs/`** — check every file there against §17.2: no restated clause, criterion
      or enumeration, steps and `§` citations only. *Criterion:* anything in `docs/` that reads as a rule
      rather than a step is folded into the constitution or deleted.
- [ ] **7. Decidability** — every mandatory requirement can be judged *met* or *not met*. *Criterion:*
      name the evidence that settles each 必须 / 禁止 line; where none exists, supply the criterion or
      downgrade the clause's marker or wording.
- [ ] **8. Full read by fresh eyes** — someone who did not write the text reads the whole edition once.
      *Criterion:* reader and findings are in the revision record; "the scripts passed" is not this.
- [ ] **9. Strip-marker invariance (marker-carrying releases only)** — Run `tools/check_constitution_text.sh`
      (see `--help`); C5 strips only line-end and standalone block markers, never inline examples.

## 2. English edition — whole-text translation

Starts only after section 1 is green and Chinese is final — that file is the *only* input (§17.8).

- [ ] Translate the whole document continuously — no patch over the previous English edition, no "only
      the clauses that moved", no independent English edit, nothing back-filled into Chinese.
- [ ] Verify the consistency criteria in §17.8 (per §17.8) plus the marker-token sequence.

## 3. Swap files and update references

- [ ] `git add BADGE-constitution-vNEW.zh-CN.md && git rm BADGE-constitution-vOLD.zh-CN.md`, likewise
      for `.en.md` (`git mv` is for lexical renames only) — English ships with Chinese, a Chinese-only
      release only by the user's decision. Before deleting, confirm the old edition is recoverable —
      tracked in git, reachable via a tag or blob (`git ls-tree`, `git cat-file -p`) (§2.4, §3).
- [ ] `grep -rn 'BADGE-constitution-v' --include='*.sh' --include='*.md' --include='*.toml' .` and update
      every **hardcoded** filename reference (`tools/`, `.gitignore`, work log, `docs/`), including the
      language dimension: a tool treating `*.en.md` as the version source of truth breaks silently when
      only another language edition is present.
- [ ] Confirm the filename filters in `tools/` are version-independent: prefix match, not exact filename
      (criterion: §17.8).
- [ ] Regenerate the **DSH skill handover artifact**; the **user** replaces
      `~/.dsh/skills/badge-constitution.md` (outside this repo) and re-checks its version string
      (`description:`, `# BADGE 开发宪法 vX.Y.Z`) — a stale skill teaches the old edition to every session.

## 4. Tooling regression and privacy audit

- [ ] `for f in tools/*.sh; do bash -n "$f"; done`
- [ ] `bash tools/check_all.sh --class=C --meta-pii=fail` — on a WSL `/mnt/c` 9p mount use
      `--no-history` or a native disk first (history scans wedge 9p into fake read-only). `--meta-pii=fail`
      fails a personal author/committer email, required for public repositories (§15.1).
- [ ] Re-run that full gate whenever a constitution filename is changed or deleted, and confirm it ran —
      a silent exit or empty output means it did not (e.g. the `.en.md`-hardcoded glob in `check_all.sh`);
      re-run after the language-suffix fix lands, before tagging. Tool-comment `§` numbers: gate item 5.
- [ ] Privacy audit before a public push: `git log --all --format='%an <%ae> %cn <%ce>' | sort -u`
      **and** `git for-each-ref --format='%(taggeremail)' refs/tags | sort -u` must show only `noreply@`
      / project mailboxes — author, committer **and** tag tagger. Content, history and identity metadata
      are covered by `tools/check_secrets.sh`.
- [ ] Any tool reading the base config accepts `config.toml` (base default) **and** legacy
      `config_example.toml` / `config_example.yaml` (`check_config_system.sh`, `check_directory_layout.sh`,
      `check_gitignore.sh`, `check_reproducibility.sh`, `check_version.sh`).

## 5. Stale-reference sweep

- [ ] `grep -rn 'vOLD' .` → no hits.
- [ ] `grep -rn 'config_example\.\(toml\|yaml\)\|config\.yaml' .` → only intentional legacy fallbacks.
- [ ] `grep -rn 'pyyaml' .` → none (TOML is the preferred format; Python 3.11 has `tomllib`).

## 6. Work log (§17.5) — manual check, no automation by decision

`tools/` deliberately ships no work-log script: §17.5 is a human handover discipline.

- [ ] State area current; every history entry carries a timestamp (format per §17.5).
- [ ] Per §17.5: refresh the state area, keep the intent anchor append-only.
- [ ] Append timestamped entries to `.local/work_log_history.md` (count and layout per §17.5);
      `.local/` stays out of git (§16).

## 7. Commit and release

- [ ] Pre-flight `git status --porcelain`: only this release's changes appear. Isolate unrelated
      uncommitted changes (e.g. a modified `tools/check_reproducibility.sh`) — never let another person's
      in-flight edit ride along in the release commit.
- [ ] Stage the new edition(s) (`git add BADGE-constitution-vX.Y.Z.*.md`); a new file left untracked
      would be missing from the commit and from the tag.
- [ ] Follow §19.1 for commit-message format and language (per §19.1); this repo has used one
      language consistently — keep it that way.
- [ ] A ride-along fix bundled with the release (e.g. `d93d5e1 fix: make check_local_files extension
      checks case-insensitive`) is named as its own item in the commit message; §19.1 prefers it as a
      separate commit entirely.
- [ ] `git tag -a vX.Y.Z -m "..."` (annotated tag, matching the existing tags and the tagger-email audit
      in section 4).
- [ ] **Push approval gate:** before any `git push`, hand the user `git log -1`, `git show --stat`, the tag
      object (`git for-each-ref --format='%(refname) %(taggername) %(subject)' refs/tags/vX.Y.Z`) and the
      gate readings from sections 1 and 4. No `git push` without explicit approval.
- [ ] Push branch and tag; verify the GitHub repository description / latest release still matches.
