# The BADGE Constitution v1.6.2

> **B**oundary **A**nd **D**efensive **G**uard for **E**ngineering
>
> Great projects aren't built by checking harder — they're built by designing so that mistakes are impossible.
> This constitution is the distillation of engineering taste — it tells you *why* a design is right, not just *what* to do.

---

# Layer 1: Design Philosophy

## I. Boundary Thinking

Boundaries are the first step of system design. From network boundaries between services down to parameter boundaries between functions — where you draw the line determines the complexity distribution, testability, and extensibility of your entire system. Draw boundaries first, then fill in the implementation.

### 1.1 Module Boundaries: One Thing Well

Each module does one thing and does it well. If a module's responsibility can't be described in a single sentence, split it. The internals of a module can be complex, but the boundaries between modules must be clean and simple.

**The practical effect of good boundaries:** when modifying upper-layer code, you never need to open lower-layer files. If an agent module calls a dozen tools, you only need to know each tool's interface and purpose — you don't need to read their implementations. Even if those tools total thousands of lines, they have nothing to do with your agent scheduling logic changes. This is the power of boundaries — they confine the blast radius of change, letting you modify safely without worrying about downstream chain reactions.

**Litmus test:** Can you, without reading the code, accurately describe a module's responsibility from its name and interface signature alone? If not, the boundary isn't clear. When modifying a module, does the number of downstream files you need to open approach zero? If not, the boundary needs reinforcing.

### 1.2 Interface Boundaries: Stable Abstractions, Swappable Implementations

Modules communicate through stable abstract interfaces, never depending on each other's concrete implementations. Add a new model backend, a new sampling strategy, a new storage engine — implement the interface and register it, without modifying a single line of existing code. Open for extension, closed for modification.

**Litmus test:** How many lines of existing code need to change to add a new implementation? If the answer is more than zero, the interface boundary needs redesign.

### 1.3 Layer Boundaries: Computation vs. Infrastructure

There are only two kinds of code: code that does **computation** (algorithms, business rules, data transformations), and code that does **infrastructure** (GPU communication, network I/O, filesystems, databases). Computation code depends on zero infrastructure — it can run single-threaded locally, be tested independently, and reproduce in any environment. Infrastructure code connects computation results to the real world.

This idea comes from distributed systems like Flink and Hadoop — don't make engineers juggle business logic, low-level implementation, and infrastructure simultaneously. No one can do all three well at once.

**Litmus test:** Can you run the core computation logic tests without starting a GPU, without a network connection, without reading files? If not, the layers aren't separated.

### 1.4 Data Boundaries: Single Source of Truth

Every piece of information in the system has exactly **one** authoritative source. Configuration comes from one file — no environment variable fallback chains. State is maintained in one place — no multi-copy synchronization. Data flows in one direction — no callbacks, no circular dependencies.

"The value can come from three places" sounds flexible, but in practice the user changes a parameter, finds it didn't take effect, and spends an afternoon debugging. Flexibility here isn't a feature — it's a bug factory.

**Litmus test:** If someone asks "where does this value come from?", can you give the unique answer in one second? If not, there are too many sources.

---

## II. Foolproof Design

Automotive design has a principle: a floored accelerator has a rev limiter, a gearshift has a synchronizer, brakes override throttle, and the defog button is placed within easy reach. The manual is hundreds of pages — few owners ever read it — yet accidents are rare, because **the system doesn't allow people to make mistakes.**

Software should be the same. Don't pray for careful developers or hope users read the docs carefully. Design so that mistakes are literally impossible.

### 2.1 Contracts as Foolproofing

Every interaction across a boundary is governed by a **verifiable contract**, never by convention or guesswork. Pydantic models validate config fields. ABC abstract classes force subclasses to implement hooks. Type annotations let mypy check data flow. These aren't "best practices" — they're foolproofing devices. Developers don't avoid mistakes because they're careful; they avoid them because the system won't let them happen.

### 2.2 Explicitness as Foolproofing

No magic in the code. State is explicit. Data flow is visible. Dependencies are declared. No string-concatenated paths. No `**kwargs` passing unknown parameters. No `hasattr` probing for interfaces. Implicit behavior is the biggest obstacle to understanding — for humans and AI alike. When everything is explicit, errors have nowhere to hide.

**Reasonable use of `**kwargs`:** In the adapter pattern for ABC abstract methods, `**kwargs` is allowed as an extension point — different subclasses may need different domain parameters, and the base class should not modify its interface for each subclass's special needs. The key: `**kwargs` must document in the docstring what additional parameters subclasses may accept, so callers know what to pass. HuggingFace's `model.generate(**kwargs)` is the canonical example of this pattern.

**Reasonable use of `hasattr`:** The following three scenarios allow `hasattr`:
1. **Runtime capability detection**: checking whether a PyTorch version supports a feature (e.g. `hasattr(torch, "float8_e8m0fnu")`) — more reliable than parsing version strings
2. **Cross-version compatibility**: handling upstream libraries (e.g. HuggingFace) returning different output types across versions (`output.logits` vs `output["logits"]`)
3. **Duck-typing**: determining object type without introducing a hard dependency (e.g. distinguishing tensor from plain numeric values)

What is forbidden: using `hasattr` to probe business interfaces in your own project — that means the interface contract is unclear. Use ABC or Protocol to define explicit interfaces instead.

### 2.3 Boundary Validation as Foolproofing

Data must be validated when crossing boundaries. Validate all config fields at load time, reject unknown fields, check required fields. Validate request format before sending, validate response structure on receipt. Check before writing output — don't overwrite existing data, don't leak sensitive information. Errors are intercepted at the boundary — illegal data never enters the system, sensitive data never leaves it.

**A critical distinction:** boundary validation that rejects an illegal request (e.g. missing config) is not a "fallback" — it's a **defense line**. Defense lines block. Fallbacks route around. Don't confuse them.

---

## III. Fallback Design

The core principle of fallbacks: **degradation may change the cost, but never the result.**

### 3.1 Same-Result Fallbacks

The system may execute these automatically, without notifying the user. The result is unchanged — only the cost changes (time, resources, speed).

- Retry: takes more time, but the final result is identical. A failed rollout retries 5 times; only errors out if all 5 fail.
- Slowdown: reduce concurrency under network congestion — slower, but data arrives intact.
- Spare tire: speed limit 80 km/h, but gets you to your destination.

### 3.2 Transparent Fallbacks

The result may be affected, and the system must clearly inform the user. Log at WARNING level, expose in metrics, let the user decide whether to intervene.

- Skipping a corrupted sample: log the sample ID and reason, training continues, but the user knows what happened.
- Using stale cache: data is expired but the network is unreachable — use the stale cache and notify the user.

### 3.3 Pre-Authorized Fallbacks

The result changes significantly, and the user must **explicitly opt in** via configuration. Default: off. This is not a runtime decision — it's a pre-deployment decision.

Examples of pre-authorized fallbacks that follow this principle:
- Skipping corrupted training samples during data loading — acceptable only when the user has explicitly set a config toggle (default off), because the model will train on a different dataset than intended.
- Overwriting existing output directories — acceptable only when the user has explicitly opted in (default off), because it destroys previous results.

The constitution does not prescribe specific config key names — each project defines its own toggles. The principle is: if the result changes significantly, the user must say "yes" before deployment, not discover it afterward.

### 3.4 Fallbacks vs. Defense Lines

Password expired, can't log in? That's not a fallback — that's a **defense line** at work. The authentication boundary validation found non-compliance and blocked access. Config field missing, exit with error? Defense line. Silently downgrading to a worse model? That's a **bad fallback** — it changed the result, and the user doesn't know.

---

## IV. Zero-Step Onboarding

A new user clones the project and gets results in two commands. No extra system dependencies to install (all in Docker). No manual configuration (defaults are production-grade reasonable values). No need to understand the internal architecture (copy the example config and go).

**Zero-step does not mean zero configuration. It means the default configuration is a working configuration.** If the user must understand the meaning of 10 parameters before they can begin, zero-step onboarding has failed.

**Litmus test:** How many steps does it take for a new user to go from clone to first output? If it's more than 3, rethink.

---

## V. Correct First, Optimize Later

Performance optimization is necessary, but not at the cost of correctness and maintainability. The principle: **guarantee correctness first, then pursue performance. But never design an architecture that cannot be optimized.**

The computation-infrastructure separation already provides a natural foundation for optimization — core algorithms can be independently tuned, decoupled from distributed communication or I/O. Stable abstract interfaces guarantee that replacing an inefficient implementation doesn't affect upper layers. If "code elegance" couples together operations that should be independent, and later you discover you can't parallelize them because they're inseparable — that's over-design. It sacrificed optimization potential for nothing in return.

**Litmus test:** If you discover a component is a performance bottleneck, can you replace it without touching the code above it? If not, the architecture needs rethinking.

---

## VI. Reproducible Environments

A project run on any two machines with identical hardware should produce **bit-for-bit identical** output. This is not an ideal — it's a verifiable engineering standard. If two runs produce different results, either the random seed isn't fixed, or dependency versions are inconsistent, or the code contains non-deterministic operations — all of these should be eliminated.

**Implementation points:**
- Random seed is explicitly set in the config file, never dependent on system time or hardware state
- `uv.lock` locks exact versions of all dependencies, committed to git
- Docker base image is pinned to a specific SHA256 digest (not a tag — tags can be overwritten)
- Configuration for each run is automatically backed up to the output directory, ensuring post-hoc reproducibility

**Litmus test:** Two machines, same config, same seed — identical output? Two runs, identical output?

---

# Layer 2: Engineering Standards

## VII. Configuration System

### 7.1 Single YAML Entry Point

All configuration lives in a single YAML file, organized by functional domain. No environment variables (NVIDIA's `CUDA_VISIBLE_DEVICES`, `NCCL_*` are already messy enough — don't add to them). No implicit CLI-overrides-config priority chains. Configuration is configuration, environment is environment — keep them separate.

### 7.2 Validate at Load Time

All validation happens at config load time, not scattered across usage points. Pydantic's `extra="forbid"` rejects misspelled field names. `model_validate()` checks all field types and constraints in one pass. Validation failure exits immediately with a clear error message — which field, what was expected, what was received.

### 7.3 Template as Documentation

Every project provides a `config_example.yaml` containing all fields, comments, and defaults. Users copy it, change a few values, and go. The template file itself is a working configuration — well-commented, sensible defaults, covering 80% of use cases.

---

## VIII. Code Organization

### 8.1 Directory Layout

```
project/
├── src/project_name/        # Source code, src-layout
│   ├── __init__.py          # Version + public API re-exports
│   ├── __main__.py          # python -m entry point
│   ├── py.typed             # PEP 561 marker
│   ├── cli.py               # CLI entry point (upgrade to cli/ when complex)
│   ├── config.py            # Config model definition + loading
│   ├── core/                # Computation layer: pure logic, zero infrastructure
│   ├── backends/            # Infrastructure layer: distributed, GPU, network
│   └── domain/              # Domain logic layer (omit if not needed)
├── configs/                 # Example configs
├── docs/                    # Architecture documentation
├── tests/                   # Tests (mirrors source tree)
│   ├── core/
│   ├── backends/
│   └── e2e/                 # End-to-end tests
├── scripts/                 # One-off utility scripts
├── .local/                  # Temporary local files (never committed, see §XVI)
├── docker/                  # Docker build
├── pyproject.toml
├── uv.lock
├── .python-version
├── README.md
├── README.zh-CN.md
├── LICENSE
└── .gitignore
```

**`cli.py` may be upgraded to a `cli/` directory:** When the CLI logic is complex enough to warrant multiple sub-modules (e.g. subcommand dispatch, training worker process entry point), follow the same logic as §8.3 (Class-to-Directory) — `cli/__init__.py` maintains external transparency, so consumers only see `graspo.cli:main` and are unaware whether the implementation is a single file or a directory.

**`domain/` may be omitted:** Not every project has an independent domain logic layer. If the domain logic naturally coheres within `core/` computation modules, or if the domain concepts are not yet stable enough to justify a separate layer, an empty directory is worse than no directory. The core principle of module boundaries (§1.1) is that a module's responsibility must be describable in a single sentence — if you cannot describe what `domain/` is responsible for, it should not exist.

### 8.2 File Granularity: Neither Too Large Nor Too Fragmented

A file of thousands of lines is hard to read, modify, and even slow for the IDE to open. But split too finely, and a single feature is scattered across a dozen files — the reader jumps between them, their mental model fractured. The ideal granularity: **one file corresponds to one clear conceptual unit.** The reader should be able to fully understand that concept by opening that file.

**Litmus test:** Can you fully understand a concept in one file? If you need to jump between multiple files to piece together the full picture, it's too fragmented. **Aim to keep files under 500 lines** — if a file exceeds that, ask yourself: is it cramming in two concepts? However, if the logic genuinely belongs to a single conceptual unit (e.g., a pure-function toolkit, a complex model adapter), exceeding 500 lines is acceptable; in that case, ensure the file is internally organized by functional domain with clear separators and comments so readers can quickly navigate.

### 8.3 Class-to-Directory: When a Class Outgrows a File

When a class has so many methods that a single file bloats to hundreds or thousands of lines, don't force the methods into one file. Upgrade the class to a directory:

```
backends/models/qwen35_36/
├── __init__.py          # Re-exports Qwen35Adapter from adapter.py
├── adapter.py           # Main class definition + template method skeleton
├── forward.py           # Forward-pass methods
├── generation.py        # Generation/sampling methods
├── checkpoint.py        # Checkpoint save/load methods
└── helpers.py           # Pure utility functions (no self state)
```

**Principle:** `adapter.py` keeps the class skeleton — `__init__`, template methods, abstract methods. Each file split out by functional domain contains a group of related methods. External consumers only import the class name, completely unaware whether it's a single file or a directory. `__init__.py` is responsible for this "external transparency."

Internal methods that need shared state access it through `self` — they remain methods of the same class, just physically distributed across files. Pure functions that don't need `self` state go into `helpers.py` — they are independent and individually testable.

### 8.4 OOP and FP: Each Has Its Place

Object-oriented and functional programming have debated for decades which is better. The answer is: **they are not rivals — they are tools.** The key is letting each do what it's best at.

**OOP excels at:** stateful, long-lived objects, scenarios with multiple implementations needing a unified interface. Class inheritance expresses "same kind of thing, different implementations" — model backends, sampling strategies, scheduling strategies. Template methods let the base class control the flow while subclasses fill in the differences.

**FP excels at:** stateless, pure computation, data transformation scenarios. Functions receive input, return output, no side effects. Reward computation, data cleaning, format conversion, text parsing — these are most natural as pure functions, with clear input-output and tests that need no context.

**Don't OOP for OOP's sake:** if a piece of logic doesn't need `self` state, don't force it into a class. A standalone pure function is clearer, easier to test, and easier to reuse than a class with a single method.

**Mixing styles within a module requires nuanced grading:**

The following mixing is **benign** (Type A) and does not need splitting:
- A file defines dataclasses (`frozen=True`, no mutable state, serving only as function return types) alongside pure functions that operate on those dataclasses. For example, `compare.py` contains `CompareResult` (frozen dataclass) and the `dict_compare_score()` family of comparison functions — they are naturally cohesive; splitting them would force readers to jump between two files.
- A file is primarily a pure-function toolkit, and the "classes" within it are essentially typed tuples (`@dataclass(frozen=True, slots=True)` small data structures), not stateful service objects. For example, `tensor_utils.py` contains `OpMemoryProfile` and similar profiling data containers alongside numerous tensor utility functions.
- Multiple sibling classes (e.g. several scheduler subclasses) share the same file — they share the same responsibility, and keeping them together is reasonable.

The following mixing **needs splitting** (Type B):
- A stateful, long-lived service class sits alongside unrelated standalone functions. For example, a `RewardCalculator` class (managing config, cache, state) next to `normalize_targets()`, `validate_tool_calls()`, and other functions that don't depend on `self` — these should be extracted into `helpers.py`.
- Complex state-management classes mixed with pure computation functions, making it impossible for the reader to tell at a glance which functions have side effects.

**Litmus test:** Can the reader tell at a glance whether the functions in this file have side effects? If seeing a class in the file leaves them unsure whether a function depends on the class's state — that's Type B, and it needs splitting.

### 8.5 Output Directory Isolation

Source code and data are assets. Run artifacts are consumables. The two must be physically separated — the output directory is not inside the source tree, specified by the `output` field in the config file. The default points to `outputs/` under the project root, and this directory is excluded in `.gitignore`.

```
outputs/<run_name>/
├── config.yaml           # Config backup for this run (full reproducibility)
├── checkpoints/          # Model checkpoints
├── logs/                 # Logs, split by functional domain
└── results/              # Final outputs (datasets, models, evaluation results)
```

Each run automatically generates a unique `run_name` (default: timestamp-based), preventing accidental overwrites. After the run completes, the user can fully reproduce it from the `config.yaml` in `outputs/` — no need to hunt down the original config file.

### 8.6 Imports and File Headers

Always use absolute imports — relative imports are forbidden. `from __future__ import annotations` (PEP 563) is used only when circular imports prevent type annotations from being evaluated, not required in every file. In Python 3.11+ projects, `str | None` syntax is natively supported, and `TYPE_CHECKING` guards already handle most circular import scenarios — there is no need to add boilerplate to every file. `__init__.py` is responsible for re-exporting the public API so external consumers don't need to know the internal file structure.

### 8.7 Version Number: Single Source of Truth

The project's version number is maintained **only in the `[project] version` field of `pyproject.toml`**. This directly embodies Constitution 1.4 (Single Source of Truth) and 2.1 (Foolproof Design):

- **Forbidden:** defining `__version__` in `__init__.py` — it inevitably drifts out of sync with `pyproject.toml`, creating two sources of truth
- **Forbidden:** writing version numbers in comments in `config_example.yaml` — the template file is for users, not version records
- **Forbidden:** hardcoding version strings in source code

If the version number is needed at runtime, read it from `pyproject.toml` or use `importlib.metadata.version("package-name")`. If users need to know the version, tell them to check `pyproject.toml` or run `pip show`.

**Litmus test:** How many files need to change to update the version? If more than 1, this clause is violated.

- **Forbidden:** embedding constitution version references (`BADGE Constitution vX.Y`,
  `constitution vX.Y §Z.W`, or similar patterns) in source code files.  The
  constitution version is maintained only in the constitution repository itself.
  Scattering version references across project source files creates drift and
  violates the same single-source-of-truth principle that §8.7 applies to project
  versions.  The constitution repo's own `CLAUDE.md` and `tools/` scripts are
  exempt — they are part of the constitution's own content, not project code.

---

## IX. Data and Interfaces

### 9.1 Data Models: Pydantic

All core data structures use pydantic `BaseModel`. Passing bare `dict` or `list` for business data is forbidden. `extra = "forbid"` rejects unknown fields. Nested structures use nested pydantic models — no dict of dicts.

`frozen = True` is recommended for pure data objects loaded from external sources that are never modified afterward (e.g. training samples, scoring results) — it prevents accidental mutation. For configuration objects that may need to be overridden by CLI arguments during initialization, `frozen` is not required; in that case, ensure the config object is not modified after initialization completes.

### 9.2 Class Inheritance: ABC Template Method

When there are multiple implementations, an ABC base class defines the process skeleton (public methods), with each step calling a `_`-prefixed private hook. Concrete subclasses only override hooks, never public methods. The base class provides default hook implementations, minimizing subclass boilerplate. To extend with a new implementation, define a new class and register it — no existing code changes.

### 9.3 Registry: Dynamic Extension

Multiple implementations of the same type are managed through a registry (string-to-class mapping). Look up by name at runtime and instantiate. On lookup failure, give a clear error message listing all available options. Adding a new implementation requires only one line of registration code.

---

## X. CLI Design

### 10.1 Config-Driven Commands

A project may have a small set of CLI commands (e.g. `train`, `export`), each accepting only a `--config` parameter plus infrastructure parameters. All behavior is driven by the config file — the CLI makes no logic decisions. Each command's sole responsibility is: parse arguments → load config → execute. Nothing more. CLI flags that override config values are forbidden.

Infrastructure parameters (`--gpus`, `--master_port`) are legitimate exceptions — they describe the runtime environment (which GPUs are available, which port is free), not business logic. Adding a new command is acceptable when it represents a fundamentally different lifecycle operation (training vs. exporting) that cannot be naturally expressed as a config toggle.

### 10.2 CLI vs. Scripts Boundary

**CLI is the stable user-facing interface. Scripts are temporary developer tools.** CLI parameters and output formats are contracts — don't change them casually. Scripts are one-off, experimental, deletable at any time, with no backward compatibility obligations. If a script is used repeatedly, by people beyond the original developer, it should be promoted to a CLI subcommand.

---

## XI. Testing

### 11.1 Toolchain

pytest runs tests, ruff formats and lints (`ruff format` + `ruff check --fix`), mypy checks types. All three are configured in `pyproject.toml` with versions pinned in dev dependencies.

### 11.2 Directory Structure

The `tests/` directory tree mirrors the `src/` directory tree. Finding a test file requires zero thought: the test for `src/project/core/schema.py` is at `tests/core/test_schema.py`. End-to-end tests go in a separate `tests/e2e/` directory.

### 11.3 Testing Standards

Unit tests cover public interfaces, with external dependencies mocked. End-to-end tests cover the full pipeline. Parametrized tests cover boundary conditions. Test function names describe three elements: what was done, under what conditions, with what expected result. Every test is independent — no dependency on execution order.

---

## XII. Code Style

### 12.1 Type Annotations

Union types: `str | None`, not `Optional[str]`. `py.typed` marker file present. Line width: 100. Target Python: 3.11+. `from __future__ import annotations` is used only when circular imports prevent type annotations from being evaluated (see 8.6).

### 12.2 Naming

Classes PascalCase, functions and variables snake_case, private members `_`-prefixed, constants UPPER_SNAKE_CASE, type aliases PascalCase, module files snake_case.

### 12.3 Language Convention

`README.md` and `README.zh-CN.md` are bilingual — the project's front door is accessible to both the English and Chinese developer communities, the two most active language groups in open source.

All other files — comments, docstrings, architecture documentation, config annotations — use **either Chinese or English, at the author's discretion**. No other languages are permitted. Choose one language per file and stay consistent within that file.

**Config template comments** (`config_example.yaml`) default to **English** — the config template is a user-facing interface, and English is the common language of the global developer community.

**Commit messages** use **English** (see 19.1).

**Technical terms, algorithm names, framework names, and academic concepts** are kept in their original English form — e.g. Flink, 1F1B, KV cache, attention mask, backpressure. These are the shared vocabulary of engineers across all languages. Forcing translation loses information density. The principle is: **accuracy first — do not sacrifice technical expression for language purity.**

Comments explain **why**, not **what**. No useless comments.

---

## XIII. Error Handling and Logging

### 13.1 Exceptions: Never Swallow

**Absolutely forbidden:** `except Exception: pass` or bare `except: pass`. Every `except` block must contain explicit handling logic (retry, degrade, or convert to user-readable message and exit). In principle, exceptions are handled uniformly at boundary layers and exposed as early as possible in internal layers.

### 13.2 Log Levels

DEBUG for developers debugging, INFO for users tracking progress, WARNING for users evaluating run quality, ERROR for telling users why something failed.

**Every project must provide at least one standard Python `logging` channel** using these four levels. This ensures compatibility with log aggregation tools, CI pipelines, and debugging workflows. Beyond this required channel, projects may add domain-specific log files (structured JSONL for metrics, timing event logs, raw rollout records, etc.) — these are system-specific extensions and are not constrained to the four-level scheme.

### 13.3 Log Files by Module Boundary

Log file granularity mirrors module boundaries (§1.1): **independent modules each get their own log files; tightly-coupled pipeline steps share a single log file.** Each independent log domain is split into **readable logs** (human-readable, INFO level) and **raw logs** (machine-parseable, DEBUG full detail). ERROR-level logs are aggregated into a common error log file. All log files live under a `logs/` subdirectory of the output directory (see 8.5 Output Directory Isolation).

The specific filenames and module splits are defined by each project according to its own architecture. For example:
- In a training framework, rollout generation, reward computation, and policy optimization are tightly-coupled steps of the same training loop — they share a single `training.log` rather than each writing to its own file
- In a data pipeline, if extraction, transformation, and loading are performed by three independent services (each independently deployable and testable), they may each have their own log file
- A project that contains both a training module and an API service module — the two are independent of each other, each with its own log file

**Core principle: splitting is meant to prevent investigators from having to open irrelevant modules' logs, but it must not force investigators to stitch together a timeline across files when tracing a single causal chain.** Structured domain-specific logs (e.g., JSONL rollout records, timing event logs) are system-specific extensions (see 13.2) and are not constrained by this rule — they serve machine analysis, not human investigation.

**Litmus test:** When investigating an event, how many log files do you need to open and correlate timelines across? If you keep jumping back and forth, the split is too fine — merge.

---

## XIV. Dependencies and Deployment

### 14.1 License Constraints

All dependencies must be MIT, Apache 2.0, or equivalent permissive licenses suitable for commercial use. GPL, AGPL, and other copyleft licenses are forbidden. Check license compatibility before introducing any new dependency.

### 14.2 Dependency Management: uv

All projects use `uv` as the sole package manager. `.python-version` pins the Python version. `pyproject.toml` declares dependency constraints (package name + version bounds). `uv.lock` is **generated from** `pyproject.toml` via `uv lock` and records the fully resolved dependency graph with exact versions and content hashes. Together they form the single source of truth for all dependencies — there is no other dependency specification. Both files are committed to git. `uv sync` sets up the development environment in one command.

**Never edit `uv.lock` by hand.** It is a generated artifact. The dependency change workflow is: `pyproject.toml` → `uv lock` → `uv.lock`. No `requirements.txt`, no `Pipfile`, no environment-variable overrides for dependency versions.

### 14.3 Docker Required

Every project must support Docker deployment. Base image is pinned to a specific version tag (never `latest`); a SHA256 digest is strongly recommended. Dockerfile uses two-stage caching (dependencies layer + source layer). Dependencies are installed via `uv sync` or `uv pip install` with `uv.lock` to guarantee the same versions as the development environment. `build.sh` encapsulates the build command.

- **build.sh version:** The Docker image tag in `build.sh` MUST derive the version
  from `pyproject.toml` rather than hardcoding it.  Per §8.7 (single source of
  truth), the tag is read dynamically.  Recommended pattern:

  ```bash
  VERSION=$(python -c "import tomllib; print(tomllib.load(open('pyproject.toml','rb'))['project']['version'])")
  IMAGE_NAME="${IMAGE_NAME:-project:${VERSION}}"
  ```

  The `IMAGE_NAME` environment variable override remains available for manual
  testing, but the default MUST come from `pyproject.toml`.

---

# Layer 3: Security and Project Governance

## XV. Security and Secrets

Security is not an afterthought bolted on before release. It is a design constraint that shapes every commit. The principle is simple: **if you don't want it on GitHub, it doesn't belong in any tracked file.**

### 15.1 Pre-Commit Verification

Every commit must pass the following checks. These checks should be integrated into CI or pre-commit hooks, executed by the companion `tools/` scripts, not left to human memory. The constitution defines the categories — the scripts define the exact patterns.

**1. Secrets scan:** No tracked file may contain any secret information. Secrets include:
- Keys, passwords, tokens, private keys of any form
- Internal IP addresses, internal domain names, internal file paths
- Any information you would not want public after open-sourcing

**2. File-type check:** The following must not appear in tracked files:
- `.env` file (only `.env-example` may be committed)
- Build artifacts, caches, virtual environments
- IDE configuration files
- AI assistant files (`CLAUDE.md`, `AGENTS.md`, `CLAUDE.zh-CN.md`)
- Temporary local files — all such files must live in `.local/` (see §XVI)

**3. Content review (human + AI assisted):**
- No training data, user data, or private datasets
- No internal resource references in README

### 15.2 Secrets Management

The only authoritative location for secrets is the `.env` file — local, never committed. (If the project has no non-infrastructure environment variables — see §19.2 for the definition of infrastructure-only projects — `.env` and `.env-example` are not required.) No code, documentation, config template, or example file may contain literal secret values. If a piece of information should not appear on GitHub after open-sourcing, it must not appear in any tracked file, period.

### 15.3 Post-Leak Response

If secret information was ever committed to git history:
- Confirm via `git log --all --full-history` that no sensitive file history remains
- Use `BFG Repo-Cleaner` to thoroughly purge all traces, then rotate every leaked key
- Confirm `LICENSE` file exists and is correct
- Confirm README contains no references to internal resources

---

## XVI. Temporary and Local Files

Every project generates files that are useful during development but have no place in the permanent codebase — run logs, migration plans, deployment notes, personal experiments. Without a designated home, these files scatter across the repository, and sooner or later one of them gets committed with internal IPs or passwords still in it.

### 16.1 `.local/` — The Sole Home for Temporary Files

The `.local/` directory at the project root is the **only** permitted location for temporary files. It is excluded entirely in `.gitignore` — nothing inside it will ever be committed.

`.local/` is not a suggestion. It is a rule: any temporary file found in a tracked path outside `.local/` is a violation.

### 16.2 What Belongs in `.local/`

A file belongs in `.local/` if it meets any of these criteria:
- Contains runtime environment information (IPs, hostnames, container names, SSH users, internal paths)
- Describes a one-time operation (migration plans, deployment records, experiment tracking)
- Is a personal note, debug log, or run monitor
- Is temporary data or an experimental config
- Is any engineering artifact that does not belong in the permanent codebase

If a file has long-term value to the project, turn it into formal documentation under `docs/`. If it only has short-term value to you or the current phase, put it in `.local/`.

### 16.3 Relationship with `scripts/`

§10.2 defines `scripts/` as the directory for shared temporary code tools. The two directories serve different purposes:
- `scripts/` — shared temporary code tools (committed to git, no backward-compatibility obligation)
- `.local/` — private temporary files (never committed, never shared, no obligations whatsoever)

---

## XVII. Documentation System

### 17.1 Bilingual Documentation

`README.md` (English) and `README.zh-CN.md` (Chinese) must be **content mirrors**, not just structural mirrors. The same operation instructions, configuration descriptions, and FAQ entries must exist in both versions — one version must never contain information absent from the other. Both READMEs must be updated simultaneously on every release.

Chapter structure: Introduction → Quick Start → Data Format → Configuration Reference → Output Description → Development Guide → FAQ.

### 17.2 Architecture Documentation

Split by topic under the `docs/` directory, each file focused on one concern. Write **why** the design is the way it is, not just what the code looks like.

### 17.3 AI Assistant Documentation

If a project uses AI coding assistants (e.g. Claude Code, GitHub Copilot), it may generate `CLAUDE.md` and `AGENTS.md` on demand for the assistant's use — high information density, structured format, helping AI understand the project's architecture and conventions. These files are **not committed to git** (excluded in `.gitignore`) — they are part of the local development environment. If the project does not use AI assistants, there is no need to create these files.

### 17.4 Version History

Projects do not maintain a standalone Changelog file. The git commit log is the single, authoritative change history. On release, tag the version with `git tag`. To review changes, use `git log`. Commit messages must follow the format specified in §19.1 so that `git log --oneline` is a readable project history.

---

## XVIII. Version Evolution and Debt Management

Technical debt is the cancer of engineering quality. Today's shortcut becomes tomorrow's double workload, and the day after tomorrow's untouchable forbidden zone. The core principle is one sentence: **once the new architecture is validated, the old architecture must be eradicated.**

### 18.1 No Debt Left Behind

- After the new architecture is online, tested, and stable, old code is **deleted immediately**. No "compatibility mode" kept around. No `legacy/` directory. No `# TODO: remove after v2` comments. The codebase contains exactly one current architecture.
- When deleting old code, simultaneously update: naming (no more `v2`, `new`, `legacy` prefixes/suffixes), config templates (`config_example.yaml` reflects the current architecture), documentation (architecture descriptions in README and docs/), tests (delete tests for the old architecture — don't keep them "just in case").
- Version numbers are updated on every release, following `MAJOR.MINOR.PATCH`: architecture refactors and incompatible config changes bump MAJOR, new features bump MINOR, bug fixes bump PATCH.

### 18.2 Legacy System Migration

When users of an old version need to upgrade to the new architecture, provide a one-click migration path:

- Migration scripts go in the `scripts/` directory, named as: `migrate_v1_to_v2.py`, `migrate_config_v2_to_v3.sh`
- The script header comment states: source version → target version, what is being migrated (config file format, checkpoint format, data format), parts that cannot be auto-migrated (requiring manual user action)
- Migration scripts are temporary tools — they serve only the current major version upgrade. The next major version may be served by a new migration script. Old migration scripts remain in `scripts/` for historical reference, as users may upgrade across multiple versions

**Litmus test:** When a new person clones the project, can they see traces of the old architecture? If so — leftover code, outdated comments, un-updated config templates — version management has failed.

---

## XIX. Open Source Management

### 19.1 Git Workflow

- Direct commits to `main` / `master` are forbidden
- All development happens on feature branches: `feature/<description>`, `fix/<description>`, `docs/<description>`
- Merging to main requires a PR — at minimum, self-review the diff
- Commit messages are **recommended** to be in English, format: `type: short description` (feat, fix, docs, refactor, test, chore). English is the de facto standard of the open source community — the `git log --oneline` toolchain is English-first, and it enables international contributors to understand the project's history. Projects whose primary contributor community uses another language (e.g. Chinese) may use that language, but should stay consistent within one repository.
- **History continuity over retroactive fixes.** Commits already pushed to a public repository MUST NOT be rewritten to fix message language — changing pushed history breaks every collaborator's local clone. The specification takes effect from the current commit forward. The exception is security: if a historical commit contains leaked secrets, history MUST be rewritten (see §15.3).
- One commit does one thing

### 19.2 .gitignore Must Cover

- Python runtime: `__pycache__/`, `*.pyc`
- Virtual environments: `.venv/`, `venv/`
- Test and type check caches: `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`
- Build artifacts: `dist/`, `build/`, `*.egg-info/`
- Environment config: `.env` (keep `.env-example` if the project has
  non-infrastructure environment variables; infrastructure-only projects —
  e.g. those using only standard CUDA/NCCL/PyTorch distributed env vars
  like `CUDA_VISIBLE_DEVICES`, `NCCL_*`, `PYTORCH_*`, `RANK`, `LOCAL_RANK`,
  `WORLD_SIZE`, `MASTER_ADDR`, `MASTER_PORT` — are exempt)
- Outputs and data: `outputs/`, `data/` (except sample data)
- IDE: `.idea/`, `.vscode/`
- AI assistants: `CLAUDE.md`, `AGENTS.md`, `CLAUDE.zh-CN.md`
- Temporary local files: `.local/`
- System files: `.DS_Store`, `Thumbs.db`

### 19.3 Open Source License

Default: MIT license. `LICENSE` file at the project root. If the project depends on Apache 2.0-licensed libraries, consider using Apache 2.0 for compatibility.

---

## XX. pyproject.toml Skeleton

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "One-sentence description"
readme = "README.md"
license = {text = "MIT"}
requires-python = ">=3.11"
dependencies = [
    "pyyaml>=6.0",
    "pydantic>=2.0",
]

[project.scripts]
my-project = "my_project.cli:main"

[project.optional-dependencies]
dev = ["pytest>=8.0", "ruff>=0.6", "mypy>=1.0"]

[build-system]
requires = ["setuptools>=75.0"]
build-backend = "setuptools.build_meta"

[tool.setuptools.package-dir]
"" = "src"

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "BLE"]

[tool.mypy]
python_version = "3.11"
ignore_missing_imports = true

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]
```