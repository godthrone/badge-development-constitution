# CLAUDE.md — BADGE Constitution

## Bilingual Sync Requirement

The BADGE constitution exists in two versions:
- `BADGE-constitution.en.md` — English
- `BADGE-constitution.zh-CN.md` — Chinese

**Any change to one version MUST be reflected in the other.** The two files are semantic mirrors — not word-for-word translations, but the same content, same structure, same clauses, same version number. When editing one, always update the other in the same commit.

This applies to:
- Clause additions, deletions, and rewordings
- Version number bumps
- Structure changes (section numbering, headings)
- New examples, litmus tests, or code snippets

## Language Convention

Per Constitution 12.3:
- README is bilingual (English + Chinese)
- All other files: Chinese or English, author's choice, one language per file
- Config template comments default to English
- Commit messages in English
- Technical terms kept in original English

## Additional Notes

This `CLAUDE.md` is committed to git — unlike the constitution's general recommendation for project repos, the constitution repo itself is a standards document, and AI assistant instructions are part of its content.

## Compliance Check Scripts

The `tools/` directory contains bash scripts that verify a project's compliance with the constitution:

- `tools/check_all.sh` — run all checks
- `tools/check_secrets.sh` — scan for IPs, keys, tokens, internal paths (§15.1)
- `tools/check_gitignore.sh` — verify .gitignore coverage (§19.2)
- `tools/check_readme_parity.sh` — verify README.md / README.zh-CN.md content mirroring (§17.1)
- `tools/check_version.sh` — verify version is only in pyproject.toml (§8.7)
- `tools/check_local_files.sh` — verify no temporary files outside .local/ (§XVI)

Scripts are zero-dependency (bash + grep + git only). They define the exact matching patterns while the constitution defines the principles (§15.1).

## Current Version

v1.6.0 — restructured Layer 3 with Security (§XV) and Temporary Files (§XVI) chapters, removed Changelog requirement (§17.4: git log is the changelog).