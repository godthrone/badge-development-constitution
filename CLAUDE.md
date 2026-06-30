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

The `tools/` directory contains bash scripts that verify a project's compliance with the constitution.
Run all checks with: `./tools/check_all.sh [project_root]`

Scripts are zero-dependency (bash + grep + git only). They define the exact matching patterns while the constitution defines the principles (§15.1).

### Design Philosophy (Layer 1)

| Script | Clause | Description |
|--------|--------|-------------|
| `check_hasattr_kwargs.sh` | §2.2 | Detect `hasattr()` on business interfaces and undocumented `**kwargs` |

### Engineering Standards (Layer 2)

| Script | Clause | Description |
|--------|--------|-------------|
| `check_reproducibility.sh` | §6 | Verify uv.lock tracked, Docker base image pinned, seed config |
| `check_config_system.sh` | §7.1-7.3 | Verify config_example.yaml, pydantic validation, no env overrides |
| `check_directory_layout.sh` | §8.1 | Verify src-layout, required directories and files exist |
| `check_file_size.sh` | §8.2 | Flag files exceeding 500/1000 lines |
| `check_imports.sh` | §8.6 | Detect forbidden relative imports |
| `check_future_annotations.sh` | §8.6 | Warn on unnecessary `from __future__ import annotations` |
| `check_version.sh` | §8.7 | Verify version only in pyproject.toml |
| `check_constitution_refs.sh` | §8.7 | Scan for constitution version references in source code |
| `check_pydantic.sh` | §9.1 | Detect BaseModel without `extra="forbid"`, bare dict usage |
| `check_test_structure.sh` | §11.2 | Verify tests/ mirrors src/, toolchain config |
| `check_type_annotations.sh` | §12.1 | Detect `Optional[str]` → should be `str \| None`, verify py.typed |
| `check_exception_handling.sh` | §13.1 | Detect `except: pass`, `except Exception: pass`, bare except |
| `check_log_consistency.sh` | §13.3 | Cross-reference README log file names with source code |
| `check_dependencies.sh` | §14.1-2, §19.3 | Verify uv-only deps, LICENSE file, no copyleft packages |
| `check_dockerfile.sh` | §14.3 | Verify Dockerfile: no :latest, multi-stage build, uv usage |
| `check_docker_version.sh` | §14.3 | Verify Docker image tag matches pyproject.toml version |

### Security and Governance (Layer 3)

| Script | Clause | Description |
|--------|--------|-------------|
| `check_secrets.sh` | §15.1 | Scan for IPs, keys, tokens, passwords, JWT, base64 secrets |
| `check_local_files.sh` | §XVI | Verify no temp files outside .local/, no .log/.tmp/.bak tracked |
| `check_readme_parity.sh` | §17.1 | Verify README.md / README.zh-CN.md content mirroring |
| `check_legacy_cleanup.sh` | §18.1 | Detect legacy/ dirs, naming anti-patterns, stale TODOs |
| `check_gitignore.sh` | §19.2 | Verify .gitignore coverage of all required entries |

### Orchestrator

| Script | Description |
|--------|-------------|
| `check_all.sh` | Run all 22 checks, print summary |

## Current Version

v1.7.0 — raise file-size advisory threshold from 500 to 1000 lines (§8.2), bump check_file_size.sh thresholds (1000→warn, 2000→fail).
