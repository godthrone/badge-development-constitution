# The BADGE Constitution v2.3.0

> **B**oundary **A**nd **D**efensive **G**uard for **E**ngineering
>
> Great projects aren't built by checking harder — they're built by designing so that mistakes are impossible.
> This constitution is the distillation of engineering taste — it tells you *why* a design is right, not just *what* to do.
>
> **The three-layer structure of this constitution:** Principles tell you why a design is right. Rules tell you what you must do. Techniques tell you how to do it. Principles without rules are empty words. Rules without techniques are unenforceable. Techniques without principles leave you not knowing why you're doing them. All three are essential — none is optional.

---

# Layer 0: Project Classification and Compliance Scope

The BADGE Constitution classifies projects into three categories, each with a different scope of applicable clauses. This constitution targets Python projects, and its design philosophy (Layer 1) is language-agnostic and can be applied to other languages by analogy.

## Three Project Categories

- **Category A (Open-source Python projects)**: Public repositories, community audience. The full constitution applies (§1–§20).
- **Category B (Closed-source Python projects)**: Private repositories, internal teams. Core clauses are mandatory (security, foolproofing, reproducibility); some clauses may be relaxed (bilingual README exemption, config-format suggestions are non-mandatory, `__main__.py` may be exempt for Docker-deployed projects).
- **Category C (Other infrastructure projects)**: Non-standard Python packages, data repositories, DevOps tools, documentation projects, etc. Design principles (§1–§6) must be followed; §7–§20 do not apply by default, but the clauses within them that are engineering embodiments of the design principles (§15 Secrets Management, §16 `.local/`, §17.3–§17.5 Documentation System, §19.1–§19.3 Open Source Management) remain mandatory.

## Classification Determination

A project has a `pyproject.toml` and builds a Python package → Category A (public repository) or Category B (private repository). Otherwise → Category C. If it's not A or B, it's C.

## Conflict Resolution

When a project's current state conflicts with a constitutional clause, use the three-question framework:

1. What is the project's core objective?
2. How can this project align with BADGE design principles and philosophy?
3. Does the specific constitutional clause help achieve BADGE design principles and philosophy, or does it impose unnecessary burden that violates the project's core objective? Is this restriction reasonable?

## Litmus Tests by Category

**Category A litmus test**: Is this clause necessary for the open-source community?

**Category B litmus test**: Is this clause about making the team safer and more efficient, or about satisfying the open-source community? The former must be kept; the latter may be relaxed.

**Category C litmus test**: Is this clause a concrete engineering embodiment of BADGE design principles (§1–§6), or is it a detailed requirement specific to Python software projects? The former must be followed; the latter is exempt for Category C.

## Compliance Detection

Project classification is not hardcoded within the project itself. When running compliance detection scripts, the classification is passed via a command-line argument (e.g., `--class A`), allowing flexible adjustment of the detection level.

## Configuration Format: TOML First

New projects should use TOML as the configuration format. Existing projects using YAML should not be changed unless actively migrated. The constitution does not mandate migration for existing YAML projects, but recommends migrating during refactoring.

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

Every piece of information in the system has exactly **one** authoritative source. Configuration has exactly one authoritative entry point (single source of truth) — no environment variable fallback chains (the narrow env-var exceptions are in §7.1). State is maintained in one place — no multi-copy synchronization. Data flows in one direction — no callbacks, no circular dependencies.

"The value can come from three places" sounds flexible, but in practice the user changes a parameter, finds it didn't take effect, and spends an afternoon debugging. Flexibility here isn't a feature — it's a bug factory.

**Litmus test:** If someone asks "where does this value come from?", can you give the unique answer in one second? If not, there are too many sources.

> This principle extends to deployment workflows: on deployment machines, the development machine is the sole source of code — see §14.4.

### 1.5 Task Boundaries: Decomposition is Execution

Module boundaries constrain code structure. Task boundaries constrain the development process. The same principle: **one task does one thing. Finish one thing before starting the next.**

When facing a complex problem, the human instinct is to "solve everything at once." The result: context bloat, declining decision quality, and unverifiable intermediate states. The principle: complex problems must be decomposed into independent sub-tasks with clear boundaries — each sub-task has explicit inputs, verifiable outputs, and no dependency on other sub-tasks' internal state.

**Rule:** A sub-task must be independently completable and produce a verifiable result. Sub-tasks communicate through explicit input/output interfaces — never through shared implicit state. The caller must be able to determine whether a sub-task succeeded solely from its output.

**Technique (AI-assisted development):** Break a large task into multiple specific, single-responsibility sub-tasks. Dispatch them to agents in parallel, each producing independently verifiable results. Aggregate at the end. Benefits: saves context window, yields more detailed output, reduces total elapsed time, and each sub-task's correctness is independently verifiable.

**Granularity fit:** Decomposition granularity is determined by task complexity — simple tasks are not split by force. For how to assess complexity and pick the least-effort execution path, see §6.1.

**Litmus test:** Can a sub-task be completed independently and produce a verifiable result without relying on the context of other sub-tasks? If not, the decomposition isn't fine enough. After a sub-task completes, can the caller determine success solely from its output? If not, the output boundary is unclear.

### 1.6 Documentation Boundaries: Details in Comments, Structure in Docs

In the AI era, code is the first document — AI reads and writes code directly, and maintaining a detailed architecture document that stays in sync with the code is both expensive and inevitably stale. The boundary between architecture documentation and code comments is itself a boundary decision:

- **Architecture documentation** — for humans and AI. It describes module boundaries, responsibilities, and interfaces, with architecture, flow, data-flow, and swimlane diagrams — after reading it, you know how the system works. No implementation details.
- **Code comments** — for AI. First, they explain the logic of key code and the design rationale (why it is designed this way). Second, each file opens with a responsibility declaration — what this file does and its scope of responsibility — drawing a boundary around the file so that AI doesn't pile unrelated methods or classes into it during modification (a foolproof device, see §2).

**Litmus test:** Can the architecture documentation explain how the system works without containing implementation details? If not, details haven't been pushed down into comments. Can the file header's responsibility declaration answer in one sentence "should this piece of code go into this file"? If not, the file boundary isn't clear.

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

**Null-value semantics: `None` is the only legal null value.** Using `0`, `-1`, `""`, `[]`, `{}`, or any other non-None value to express "absent/not-provided/invalid" semantics is prohibited. `None` is the only value in Python's type system with "null" semantics. Using other sentinel values bypasses the type checker's null detection and introduces ambiguity — is `-1` an "invalid port" or "port number -1"? Is `0` "not set" or "length zero"? `None` has no such ambiguity.

**Exception:** Natural zero points of numeric types (e.g., counter `0`, probability `0.0`) are not "null" semantics and are not subject to this rule. Using `-1` as a sentinel is only permitted when the value carries clear, irreplaceable domain semantics (e.g., POSIX error code `-1`) that cannot be expressed with `None`. Such exceptions must be justified in a comment.

**Serialization-boundary exception (TOML):** TOML has no null literal. The base configuration may use `""`, `0`, and `[]` to mean "not provided", but only at the serialization/deserialization boundary, and the loader must immediately normalize them to `None` before any business code sees them (see §7.1). This exception does not apply to semantic expression inside Python code.

**`= None` must be paired with an optional type annotation.** When a parameter or attribute defaults to `None`, the annotation must be written `X | None` (i.e., `x: str | None = None`, not `x: str = None`). The type annotation is part of the contract — `str = None` tells the type checker "this value is always a str", but at runtime it may be `None`, which is a self-contradictory contract.

**Null-value checking:** When checking values of an optional type (`X | None`), use `is None` / `is not None`, not `if not x`. `if not x` treats `0`, `False`, `""`, and `[]` all as "empty", causing logic errors. `is None` matches only `None`, with no semantic ambiguity.

**Litmus test:** Does the codebase use `0`, `-1`, `""`, or other non-None values with "null/invalid" semantics? If so, does each have a comment justifying the choice? Are all `= None` defaults paired with `X | None` annotations?

### 2.3 Boundary Validation as Foolproofing

Data must be validated when crossing boundaries. Validate all config fields at load time, reject unknown fields, check required fields. Validate request format before sending, validate response structure on receipt. Check before writing output — don't overwrite existing data, don't leak sensitive information. Errors are intercepted at the boundary — illegal data never enters the system, sensitive data never leaves it.

**A critical distinction:** boundary validation that rejects an illegal request (e.g. missing config) is not a "fallback" — it's a **defense line**. Defense lines block. Fallbacks route around. Don't confuse them.

### 2.4 Operational Foolproofing

**Principle:** A destructive operation must make "what is about to happen" visible to the operator before execution. Deletion commands (files, directories, images, containers, database records, etc.) must not rely on implicit wildcard expansion — the result of wildcard expansion is invisible to the operator before execution, and this is the root cause of accidental deletion. The way to foolproof is not to trust the operator to be careful; it is to make it impossible for the operator not to see.

**Rule:** Before executing any deletion command, first list the targets with a listing command (`ls`, `docker images`, `git branch`, etc.), confirm they are correct, then delete using specific names one by one. **Wildcards (`*`, `?`, `[...]` and other shell glob patterns) are strictly forbidden in deletion commands.**

**Technique (wildcard exception handling):** When the number of files to delete is genuinely large and a wildcard is warranted, output the full deletion command to the user for manual review and execution. AI assistants must not automatically execute deletion commands containing wildcards. This is not a matter of judgment — it is a design constraint. Just like the car rev limiter in the opening of §2: it's not about distrusting the driver; it's about giving no one the opportunity to make a mistake.

**Litmus test:** Before executing a deletion, can you name every single target that will be deleted? If not, the operation does not comply with this clause.

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

### 4.1 Startup Script

**Principle:** If a project requires a shell script as the user entry point (wrapping Docker startup, environment variable setup, CLI parameter passing, etc.), that script must be placed at the project root so the user can spot it immediately without searching the directory tree.

**Rule:**
- At most **one** startup script at the project root, recommended name `run.sh`. This is the project's first interface to the user — after cloning, `ls` reveals it immediately.
- This script is part of the user contract and is subject to §10.2 institutionalization criteria: it is referenced by the README, used repeatedly by workflows, and is a stable interface — do not casually change its parameter signature.
- CLI parameters passed by this script must obey the three principles of §10.1 — only input-locating parameters (e.g. `--config`), runtime-environment parameters (e.g. `--gpus`), and run-boundary parameters (e.g. `--smoke`). All output-affecting parameters must go into the config file and must not be hardcoded in `run.sh`.
- This script does not belong to the `scripts/` directory (§10.2) — `scripts/` holds temporary developer tools, while `run.sh` is a stable user-facing entry point. The two must not be confused.

**Technique:**
- The minimal `run.sh`: set necessary environment variables, then call `python -m project --config "$@"`, letting the user override the config path via the command line.
- If the project also has Docker deployment (§14.3), `run.sh` may wrap the `docker run` command so the user can start the project without knowing Docker details.
- If the project does not need a shell wrapper (i.e. `pip install` followed by `python -m project` works directly), `run.sh` is not required. Not every project needs one.

**Litmus test:** After cloning, can a new user find the startup entry point within 5 seconds? Seeing `run.sh` with a single `ls` is a pass. If they need to `cd scripts/`, scan the README, or search, it's a failure.

### 4.2 Startup Script Localization

**Principle:** `run.sh` should work in any deployment environment without modification.

**Rule:**
- Localization should prefer `run.sh`'s own parameters (CLI flags, see §4.1 and §10.1) or a local override file under `.local/`; do not treat environment variables as the project's normal configuration channel (the narrow exceptions are in §7.1).
- When localization is needed, the user creates `.local/run.local.sh`, which calls the base `run.sh` with explicit parameters. The base `run.sh` remains the authoritative, portable entry point.
- `run.local.sh` is the localized variant — it is gitignored and only forwards parameters or overrides values; it must not duplicate the base logic.
- Only when a third-party component (e.g. a Docker/container interface) accepts nothing but environment variables may `${VAR:-default}` be used inside that adapter boundary. Such usage must be centralized, explicit, and commented — never scattered.

**Technique:**
- The recommended pattern: `run.sh` defines paths and settings as script variables with defaults and exposes matching `--xxx` flags. Users who need customization create `.local/run.local.sh`, e.g. `exec "$(dirname "$0")/../run.sh" --model-dir /data --port 8080`, passing localized values as parameters.
- If a third-party tool can only be configured through environment variables, export them in `run.local.sh`, mark them as a "third-party adapter" in a comment, and keep the base `run.sh` independent of them.

**Litmus test:** Can a new deployment environment start the project without editing `run.sh`? If environment variables must be set first, is it confirmed to be an allowed §7.1 third-party adapter case, clearly documented, and with reasonable defaults?

---

## V. Correct First, Optimize Later

Performance optimization is necessary, but not at the cost of correctness and maintainability. The principle: **guarantee correctness first, then pursue performance. But never design an architecture that cannot be optimized.**

The computation-infrastructure separation already provides a natural foundation for optimization — core algorithms can be independently tuned, decoupled from distributed communication or I/O. Stable abstract interfaces guarantee that replacing an inefficient implementation doesn't affect upper layers. If "code elegance" couples together operations that should be independent, and later you discover you can't parallelize them because they're inseparable — that's over-design. It sacrificed optimization potential for nothing in return.

**Litmus test:** If you discover a component is a performance bottleneck, can you replace it without touching the code above it? If not, the architecture needs rethinking.

---

## VI. Reproducible Environments

A project run on any two machines with identical hardware should produce **bit-for-bit identical** output (excluding uncontrollable randomness — the full definition is in §10.1). This is not an ideal — it's a verifiable engineering standard. If two runs produce different results, either the random seed isn't fixed, or dependency versions are inconsistent, or the code contains non-deterministic operations — all of these should be eliminated. Uncontrollable randomness (wall-clock timing differences from machine load, GPU kernel selection, and other differences outside your control) is not a reproducibility violation.

**Implementation points:**
- Random seed is explicitly set in the config file, never dependent on system time or hardware state
- `uv.lock` locks exact versions of all dependencies, committed to git
- Docker base image is pinned to a specific version tag (not `latest` — tags can be overwritten)
- Configuration for each run is automatically backed up to the output directory, ensuring post-hoc reproducibility

**Litmus test:** Two machines, same config, same seed — identical output? Two runs, identical output? "Identical" means identical on-disk output after excluding uncontrollable randomness — when judging parameter placement, use the reproducibility definition in §10.1.

---

### 6.1 Simple First: Assess, Then Act

**Principle:** Assess task complexity and risk before starting. In the absence of irreversible risk, start from the simplest path — if a simple method solves it, do not use a complex one. Simple operations are hard to get wrong; this is Occam's razor applied to engineering execution, and one of the means of foolproofing (§2) and raising task success rate.

This clause constrains the **method of execution** (depth of investigation, implementation path, tool choice), not the **standard of delivery** — the completeness of the deliverable's design is not lowered by this clause.

**Three assessment questions:**
1. How complex is the task — does it require extensive analysis and verification before acting?
2. If it goes wrong, is the consequence recoverable/reversible?
3. Is there a simpler, ready-made entry point or approach?

**Entry point first:** Look for existing scripts, README, docs, and other entry points in the directory the user gave you; build the full picture first, then decide whether to read the source in depth.

**Technique:** For simple tasks, just do it; stop when verification passes, and don't run multiple rounds of repetitive analysis on the same thing. Execution cost (time, tokens) is a resource worth managing — a light recommendation, not a hard constraint.

**Boundary:** If the chosen path is irreversible — data changes, destructive operations, external delivery — simple-first does not apply; validate fully before acting (destructive operations see §2.4).

**Escalation signal:** Only escalate to root-cause investigation when a simple approach fails once, or the same problem recurs.

**Litmus test:** If your chosen execution path is wrong, can later verification correct it? If yes, trying the simple path first is fine; if not (irreversible), validate fully first.

---

# Layer 2: Engineering Standards

## VII. Configuration System

### 7.1 Single Configuration Entry Point

**Principle:** Configuration has exactly one authoritative entry point: a git-tracked base `config.toml` holds the defaults, organized by functional domain, optionally overlaid by a gitignored override configuration; after deep merge there is only one configuration in the program. TOML is the standard configuration format of the Python ecosystem (same format as `pyproject.toml`), with a type system that natively supports nested tables and arrays. Except for the exceptions this section explicitly allows, do not use environment variables to carry configuration values (NVIDIA's `CUDA_VISIBLE_DEVICES` and `NCCL_*` are already messy enough), and do not use CLI arguments to implicitly override the configuration file. Configuration is configuration, environment is environment — keep them separate.

> This constitution targets Python projects. This section and all subsequent concrete rules (file format, package manager, type annotation syntax, etc.) are anchored in the Python ecosystem. The design philosophy (Layer 1) is language-agnostic and can be applied to other languages by analogy.

**Environment-variable policy:** Environment variables are an invisible, hard-to-control configuration channel and must not be the single source of truth for configuration. They are allowed only for: ① standard infrastructure variables (`CUDA_VISIBLE_DEVICES`, `NCCL_*`, `PYTORCH_*`, `RANK`, etc.); ② third-party components that accept nothing but environment variables and cannot be adapted through configuration (an adapter layer for that component); ③ genuinely tiny projects that have exactly one configuration. Outside these three cases, environment variables must not carry configuration or path parameters (§10.1). Any configuration that arrives via environment variables must be read centrally at startup and normalized into the same configuration-loading path — never read ad hoc at usage sites. A user's own choice to keep local secrets in `.env` is not restricted by this policy, but the project must never treat it as the configuration source of truth (see §15.2).

**Layered Configuration Pattern:** When a project needs to separate deployment configuration from public configuration, use a two-layer TOML approach with deep dict merge. Deployment configuration includes two categories of fields:

- **Secret fields**: keys, passwords, tokens, internal IPs — must not appear in git-tracked files.
- **Environment fields**: API endpoint URLs, model names, external service addresses — these vary by deployment environment but are not secrets per se.

- **Base configuration** (`config.toml`, git-tracked, loaded by default at startup): Contains **all fields** and is the **single authoritative source** of the configuration schema. Non-deployment fields have production-grade defaults. Secret fields are left empty (`""`, `0`, `[]`, normalized to `None` at load time — see §2.2). Environment fields have **development defaults** (e.g., `"http://localhost:8000"`, `"local-model"`) rather than being left empty — this ensures the project runs out of the box in a development environment.
- **Override configuration** (recommended location: `.local/config.override.toml`, gitignored, deployment machine only): Overrides only the fields that need deployment-specific values. Copy from the git-tracked `config.override.sample.toml` template and fill in real values. **Must not add fields that do not exist in the base configuration** — the override "fills holes", it does not "dig new ones". By default the template lists only the common fields that need overriding; when the total number of config fields is small (roughly under 30), it may mirror all fields for easier comparison.
- **Merge rule:** On startup, load the base configuration into a dict, then load the override configuration, and **deep merge** them into a single dict — leaf values from the override dict replace leaf values at the same path in the base dict. After merging, there is only **one configuration** in the program, eliminating any ambiguity of "two configuration sources".

**Override file location:** The recommended location for the override file is `.local/config.override.toml`. Other locations are supported via an explicit `--override` parameter passed by the user. The CLI auto-detection priority is: explicit `--override` parameter → `.local/` → adjacent path (backward compatible).

```toml
# config.toml — base configuration (git-tracked), contains all fields
[device]
type = "simulation"
robot_type = "general_robot"

[streaming]
encoder = "h264"
h264_fps = 30

[task.llm]
endpoint = ""                # secret field, empty, overridden at deployment
model = "local-model"        # environment field, development default

# .local/config.override.toml — override configuration (gitignored), only deployment fields
[task.llm]
endpoint = "http://10.1.xxx.xxx:8000/v1"
model = "production-model"
```

**TOML null-value handling:** TOML does not support `None`/null literals. To express "not provided" in the base configuration, use `""` (empty string). The program must uniformly convert `""` to `None` at load time. `""` is the serialized representation of `None`, not a business-meaningful empty string. For numeric and array fields, use `0` and `[]` as the "not provided" sentinels, and the program must convert them to `None` as well.

**Litmus test:** Does the base configuration contain every field (no omissions)? Can you understand the complete configuration schema by reading only the base configuration? Does the override configuration only override fields that already exist in the base configuration (no new fields)? After merging, does the program have only one configuration (single downstream consumer)?

### 7.2 Validate at Load Time

All validation happens at config load time, not scattered across usage points. Pydantic's `extra="forbid"` rejects misspelled field names. `model_validate()` checks all field types and constraints in one pass. Validation failure exits immediately with a clear error message — which field, what was expected, what was received.

**Two-way config contract:** The config file is the user-side contract and the pydantic model is the code-side contract; the two must correspond one-to-one. Every field that appears in config must be defined in the model and actually used; every field defined in the model must have a corresponding config source. **A field that is declared but never consumed is a "phantom config"** — the user changes it believing it takes effect, while nothing happens; this is more insidious than a missing field.

### 7.3 Template as Documentation

The base `config.toml` is itself the template and the documentation: it contains all fields, comments, and defaults, and is a working configuration — well-commented, sensible defaults, covering 80% of use cases. The deployment override template `config.override.sample.toml` shows only the fields that need overriding (or all fields when there are fewer than about 30), using placeholders to guide deployers.

### 7.4 Config Parameter Design

Config parameters are the boundary between the user and the system. Poorly designed parameters can't be fixed by better documentation — users will be misled by ambiguous names, overwhelmed by redundant knobs, and trapped by coupled parameters. Three principles of parameter design:

**1. No useless parameters.** If a value can be derived automatically, don't make the user specify it. A parameter that is uniquely determined by other parameters should not exist — every extra parameter is one more opportunity for user error. `decay_steps` is the decay span the user genuinely cares about; don't make them derive it from training length. `num_layers` is known from the model config file, so don't ask the user to fill it in. The principle: **the user should only specify what they genuinely care about and what the system cannot decide for them.**

**2. Orthogonal parameters.** Parameters should be independent of each other — adjusting one should not change the semantics of another. If changing `warmup_steps` requires also changing `total_steps` for the scheduler to work correctly, the two parameters are coupled and the design is flawed. Orthogonal configuration lets users independently optimize each dimension without maintaining a mental "parameter linkage table."

**Litmus test:** Can the user independently adjust each parameter and get a predictable result? If changing parameter A requires also changing parameter B, they are not orthogonal — they should be merged into one parameter, or one of them should be auto-derived.

**3. Self-explanatory names.** Parameter names can be long, but must communicate their meaning at a glance — no documentation lookup required. `learning_rate` is better than `lr`. `warmup_steps` is better than `ws`. `min_lr_ratio` is better than `min_lr` (the latter reads as an absolute LR value, not a ratio). Abbreviations are only acceptable when the term is a universally recognized domain standard — such as `lr`, `tp`, `pp`, `lora`. Even then, prefer full names as top-level config keys — `learning_rate` is less ambiguous than `lr`.

**Litmus test:** Show only the parameter name and comment to someone unfamiliar with the project. Can they accurately state what the parameter does? If they get the function right but the unit or range wrong, the name is good but the comment is insufficient. If they get the function wrong, the name itself is ambiguous. Beyond that: when you change this parameter, does the system behavior actually change as intended? If nothing changes, it was never wired into the code — a phantom config, not a naming problem.

---

## VIII. Code Organization

### 8.1 Directory Layout

```
project/
├── run.sh                   # Startup script (present if needed, see §4.1)
├── config.toml              # Base default config (git-tracked, contains all fields)
├── config.override.sample.toml  # Override template (git-tracked, placeholders)
├── src/project_name/        # Source code, src-layout
│   ├── __init__.py          # Version + public API re-exports
│   ├── __main__.py          # python -m entry point
│   ├── py.typed             # PEP 561 marker
│   ├── cli.py               # CLI entry point (upgrade to cli/ when complex)
│   ├── config.py            # Config model definition + loading
│   ├── core/                # Computation layer: pure logic, zero infrastructure
│   ├── backends/            # Infrastructure layer: distributed, GPU, network
│   └── domain/              # Domain logic layer (omit if not needed)
├── configs/                 # Example configs (required for long-running services; batch/training tasks may omit — place example configs in samples/configs/ instead)
├── docs/                    # Architecture documentation
├── tests/                   # Tests (mirrors source tree)
│   ├── core/
│   ├── backends/
│   └── e2e/                 # End-to-end tests
├── scripts/                 # One-off utility scripts (optional: may be absent once all tools are institutionalized, §10.2)
├── .local/                  # Local and temporary files (never committed, see §16)
├── docker/                  # Docker build
├── pyproject.toml
├── uv.lock
├── .python-version
├── README.md
├── README.zh-CN.md
├── LICENSE
└── .gitignore
```

**`configs/` directory:** Long-running services (e.g., API services, web applications) require `configs/` for runtime configuration. Batch/training tasks (e.g., model training, data processing scripts) receive configuration via CLI arguments — place example configs in `samples/configs/` instead; a root-level `configs/` is not required.

**Directory organization principle:** The directory structure is a navigation system for the codebase, not a filing cabinet. From directory hierarchy and file names alone, a reader should roughly understand what the code does, which module it belongs to, and its inheritance relationships — without opening any files. A directory should not contain more than 10 code files of distinct responsibilities. When it does, the directory contains multiple independently-nameable sub-domains — create categorized sub-directories and group files by functional domain. This is not a hard limit, but a signal: when you see the 11th file, ask yourself "can this directory's responsibility still be described in a single sentence?"

> The directory layout template shows both `README.md` and `README.zh-CN.md`. For projects exempt under §17.6, a single `README.md` is sufficient.

**`cli.py` may be upgraded to a `cli/` directory:** When the CLI logic is complex enough to warrant multiple sub-modules (e.g. subcommand dispatch, training worker process entry point), follow the same logic as §8.3 (Class-to-Directory) — `cli/__init__.py` maintains external transparency, so consumers only see `project_name.cli:main` and are unaware whether the implementation is a single file or a directory.

**`domain/` may be omitted:** Not every project has an independent domain logic layer. If the domain logic naturally coheres within `core/` computation modules, or if the domain concepts are not yet stable enough to justify a separate layer, an empty directory is worse than no directory. The core principle of module boundaries (§1.1) is that a module's responsibility must be describable in a single sentence — if you cannot describe what `domain/` is responsible for, it should not exist.

### 8.2 File Granularity: Neither Too Large Nor Too Fragmented

A file of thousands of lines is hard to read, modify, and even slow for the IDE to open. But split too finely, and a single feature is scattered across a dozen files — the reader jumps between them, their mental model fractured. The ideal granularity: **one file corresponds to one clear conceptual unit.** The reader should be able to fully understand that concept by opening that file.

**Litmus test:** Can you fully understand a concept in one file? If you need to jump between multiple files to piece together the full picture, it's too fragmented. **Aim to keep files under 1000 lines** — if a file exceeds that, ask yourself: is it cramming in two concepts? However, if the logic genuinely belongs to a single conceptual unit (e.g., a pure-function toolkit, a complex model adapter), exceeding 1000 lines is acceptable; in that case, ensure the file is internally organized by functional domain with clear separators and comments so readers can quickly navigate.

### 8.3 Class-to-Directory: When a Class Outgrows a File

When a class has so many methods that a single file bloats to hundreds or thousands of lines, don't force the methods into one file. Upgrade the class to a directory:

```
backends/models/model_adapter/
├── __init__.py          # Re-exports ModelAdapter from adapter.py
├── adapter.py           # Main class definition + template method skeleton
├── forward.py           # Forward-pass methods
├── generation.py        # Generation/sampling methods
├── checkpoint.py        # Checkpoint save/load methods
└── helpers.py           # Pure utility functions (no self state)
```

**Principle:** `adapter.py` keeps the class skeleton — `__init__`, template methods, abstract methods. Each file split out by functional domain contains a group of related methods. External consumers only import the class name, completely unaware whether it's a single file or a directory. `__init__.py` is responsible for this "external transparency."

Internal methods that need shared state access it through `self` — they remain methods of the same class, just physically distributed across files. Pure functions that don't need `self` state go into `helpers.py` — they are independent and individually testable.

File names inside a class directory need not match class names — the directory name carries the locality of the domain (the class name stem), and inner files are named by functional domain (§12.2 class-path mirroring).

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
├── config.toml           # Config backup for this run (full reproducibility)
├── checkpoints/          # Model checkpoints
├── logs/                 # Logs, split by functional domain
└── results/              # Final outputs (datasets, models, evaluation results)
```

Each run automatically generates a unique `run_name` (default: timestamp-based), preventing accidental overwrites. After the run completes, the user can fully reproduce it from the config backup in `outputs/` — no need to hunt down the original config file. The backup uses the same format as the project config (for a TOML project, `config.toml`).

### 8.6 Imports and File Headers

Always use absolute imports — relative imports are forbidden. `from __future__ import annotations` (PEP 563) is used only when circular imports prevent type annotations from being evaluated, not required in every file. In Python 3.11+ projects, `str | None` syntax is natively supported, and `TYPE_CHECKING` guards already handle most circular import scenarios — there is no need to add boilerplate to every file. `__init__.py` is responsible for re-exporting the public API so external consumers don't need to know the internal file structure.

### 8.7 Version Number: Single Source of Truth

The project's version number is **automatically derived from git tags via `setuptools-scm`**. `pyproject.toml` declares `dynamic = ["version"]`. This is a stronger embodiment of Constitution 1.4 (Single Source of Truth) and 2.1 (Foolproof Design):

- `pyproject.toml`'s `[tool.setuptools_scm]` section configures version derivation rules (tag format, prefix, etc.) — this is the **single configuration source** for the versioning mechanism
- The actual version string does not live in any file — it is derived from `git describe --tags`. To release: `git tag vX.Y.Z`
- **Forbidden:** defining `__version__` in `__init__.py` — creates two sources of truth
- **Forbidden:** writing version numbers in config comments (`config.toml`, `config.override.sample.toml`) — config files are for users, not version records
- **Forbidden:** hardcoding version strings in source code

At runtime, use `importlib.metadata.version("package-name")`. For users to check the version: `git tag --sort=-v:refname | head -1` or `pip show package-name`.

**Why not use `pyproject.toml`'s `version` field?** `pyproject.toml` carries two entirely unrelated pieces of information: the version number and the dependency declarations. If the version number were hardcoded in `pyproject.toml`, Docker builds would use the file hash for layer caching — changing the version number would change the hash, invalidating the dependency layer cache and forcing a full re-download of all packages. `setuptools-scm` + `dynamic = ["version"]` decouples the version number from the file into git tags — `pyproject.toml` contains no version string, so version bumps do not change the file's hash, making it safe to include in the dependency layer. Version bumps then only affect the source layer (`COPY src`), while the dependency layer cache is fully reused. This is §1.4 (Single Source of Truth) and §14.3 (Docker layer caching) working in concert.

**Litmus test:** How many files need to change for a release? If more than 0, this clause is violated.

- **Forbidden:** embedding constitution version references (`BADGE Constitution vX.Y`,
  `constitution vX.Y §Z.W`, or similar patterns) in source code files.  The
  constitution version is maintained only in the constitution repository itself.
  Scattering version references across project source files creates drift and
  violates the same single-source-of-truth principle that §8.7 applies to project
  versions.  The constitution repo's own `tools/` scripts are exempt — they
  are part of the constitution's own content, not project code.

---

## IX. Data and Interfaces

### 9.1 Data Models: Pydantic

All core data structures use pydantic `BaseModel`. Passing bare `dict` or `list` for business data is forbidden. `extra = "forbid"` rejects unknown fields. Nested structures use nested pydantic models — no dict of dicts.

**Model purity:** Data models follow the same single-responsibility principle as module boundaries (§1.1). A model should contain only data that belongs to its conceptual domain. When you need to attach unrelated metadata, don't add fields to the existing model — create a new model and use composition (nesting) instead of pollution. For example, an observation model should stay clean, containing only observation data; additional control flags (such as reset_task_done) belong in a wrapper model, with the observation as one of its fields.

`frozen = True` is recommended for pure data objects loaded from external sources that are never modified afterward (e.g. training samples, scoring results) — it prevents accidental mutation. For configuration objects that may need to be overridden by CLI arguments during initialization, `frozen` is not required; in that case, ensure the config object is not modified after initialization completes.

### 9.2 Class Inheritance: ABC Template Method

When there are multiple implementations, an ABC base class defines the process skeleton (public methods), with each step calling a `_`-prefixed private hook. Concrete subclasses only override hooks, never public methods. The base class provides default hook implementations, minimizing subclass boilerplate. To extend with a new implementation, define a new class and register it — no existing code changes.

### 9.3 Registry: Dynamic Extension

Multiple implementations of the same type are managed through a registry (string-to-class mapping). Look up by name at runtime and instantiate. On lookup failure, give a clear error message listing all available options. Adding a new implementation requires only one line of registration code.

---

## X. CLI Design

### 10.1 Config-Driven Commands

**Principle: the config file is the sole description of run output.** Run output includes everything written to disk (model weights, datasets, evaluation results, log and record files) — the on-disk location is part of the output (output_dir and run_name are both config-driven); content sent to external systems counts as output too. The only exception: content printed directly to stdout without touching disk is not output.

**Reproducibility definition:** with the same config + seed, on-disk output matches after excluding uncontrollable randomness (wall-clock timing differences from machine load, GPU kernel selection, and other differences outside your control) — that is reproduction (§6). Reproduction is the basis for judging parameter placement: **whether the config.toml backed up in the output directory (§8.5) alone can reproduce all on-disk output is the single standard for judging where a parameter belongs.**

**Corollary 1: every parameter that participates in deciding output must live in the config file.** Otherwise the same config would produce different results under different CLI flags — the one-to-one mapping between config and output breaks, and the §8.5 "back up config.toml and reproduce" promise fails.

**Corollary 2: CLI flags and config fields have zero intersection.** A parameter has exactly one source of truth (§1.4). A mechanism where "the config holds a value and the CLI overrides it" is forbidden — override means two sources of truth. Adding a new command is acceptable when it represents a fundamentally different lifecycle operation (training vs. exporting) that cannot be naturally expressed as a config toggle, but the command itself is subject to this section.

**CLI parameters follow three principles (applies to every CLI command):**
1. **Input-locating parameters**: point at input files or data — they locate input, they are not configuration content. `--config` is the canonical example; others like `--data`, `--limit`, `--checkpoint` must be judged by project semantics;
2. **Runtime-environment parameters**: never written to disk, never part of output, only affect "where it runs" (e.g. `--gpus`, `--master_port`);
3. **Run-boundary parameters**: do not produce a complete run output (e.g. `--smoke` smoke test — equivalent to a one-step config, no training semantics changed).

**`--config` is the only explicitly named parameter** — other parameter names vary by project and must be reviewed against the three principles: under the same config + seed, does a different value of this parameter change on-disk output? If yes, it must move into config.

**Judgment criteria (technique):** for any parameter X — under the same config + seed, if different values of X change the existence, location, or controllable content of any on-disk output, X must move into the config.

**Output constraint (technique):** every CLI command's on-disk output is decided by the config — "output-locating" flags (`--output`, `--output-dir`, etc.) are forbidden. Tool commands (validate/evaluate/analyze, not part of training output) are equally constrained, with three options only: print without writing to disk; accept `--config` and write into a config-decided directory; or demote to a scripts/ script (§10.2).

**Poka-yoke (technique):**
- The CLI parameter list is enumerated once in code and locked by tests — a new CLI flag must pass a "no-disk-diff" test (run twice with the same config, only X differs, assert identical on-disk output)
- Log and record files must not contain runtime-environment metadata (GPU IDs, host paths, container names) — they are not reproducible and not output
- Except for the §7.1 third-party adapter cases, custom environment variables must not carry configuration or path parameters; standard CUDA/NCCL/PyTorch infrastructure variables are unaffected; host-path injection goes through CLI flags (e.g. run.sh `--model-dir`)
- `run.sh` (§4.1) CLI parameters are equally subject to the three principles of this clause — it is a config launcher, not a config substitute

### 10.2 CLI vs. Scripts Boundary

**CLI is the stable user-facing interface. Scripts are temporary developer tools.** CLI parameters and output formats are contracts — don't change them casually. Scripts are one-off, experimental, deletable at any time, with no backward compatibility obligations.

**Institutionalization criteria:** a script becomes an institutionalized interface the moment any of these holds — it must then be promoted to a CLI subcommand or deleted:
- Tests exist for it in tests/
- It is referenced by the README or docs/
- It is used repeatedly by workflows or beyond the original developer

scripts/ keeps only one-off, experimental, non-institutionalized tools. Scripts promoted to CLI subcommands are subject to §10.1 (input-locating flags + config-decided output).

**Root startup scripts are not `scripts/`:** `run.sh` (§4.1) and `build.sh` (§14.3) are stable user-facing entry points placed at the project root. They do not belong to the `scripts/` directory. Their lifecycle is synchronized with the project — the "temporary tool" designation does not apply.

---

## XI. Testing

### 11.1 Toolchain

pytest runs tests, ruff formats and lints (`ruff format` + `ruff check --fix`), mypy checks types. All three are configured in `pyproject.toml` with versions pinned in dev dependencies.

### 11.2 Directory Structure

The `tests/` directory tree mirrors the `src/` directory tree. Finding a test file requires zero thought: the test for `src/project/core/schema.py` is at `tests/core/test_schema.py`. End-to-end tests go in a separate `tests/e2e/` directory.

### 11.3 Testing Standards

Unit tests cover public interfaces, with external dependencies mocked. End-to-end tests cover the full pipeline. Parametrized tests cover boundary conditions. Test function names describe three elements: what was done, under what conditions, with what expected result. Every test is independent — no dependency on execution order. For the methodology of how tests drive algorithm development, see §11.4.

### 11.4 Test-Data-Driven Development

For adaptation algorithms in complex scenarios (e.g. model adapters, protocol converters, format compatibility layers), the completeness of generalized scenarios is extremely difficult to exhaustively guarantee through formal analysis. In such cases, test-data-driven development is an effective alternative path.

**Principle:** Use continuously enriched test scenarios as empirical anchor points for the algorithm, in place of formal completeness proofs. The richer the test scenarios, the higher the marginal cost of "cheating" through hardcoded branches, and the algorithm is forced toward genuine logical generalization. However, this is not "add an if for each new case" — each batch of new test scenarios should be followed by an abstraction refactor, so the algorithm covers more scenarios with simpler logic, rather than stacking patches on a branching tree.

**Rule:** Cheating and hardcoding to pass test data is forbidden. Specifically: do not add hardcoded branches in the algorithm targeting specific test inputs; do not relax assertions in tests to "pass" them; when a new test scenario fails, cover it by refactoring the algorithm's logic, not by appending conditional branches to existing logic.

**Technique:** Start from a small set of typical scenarios, progressively expand to boundary and edge cases, and after each iteration, examine whether the algorithm's logic has become simpler or more complex. If the algorithm's line count grows linearly with the number of test scenarios, cheating or patch accumulation is at work — re-abstract. The sign of convergence: new test scenarios pass without modifying the algorithm's logic.

---

## XII. Code Style

### 12.1 Type Annotations

**Principle:** Type annotations are not decoration — they are contracts. Every function signature is a type contract — callers can understand input and output types without reading the implementation. When you change a type, mypy forces you to review every affected file — this is not a maintenance burden, it is a fail-safe device (§2.1) applied at the type level.

**Rules:**

1. **Every function must have complete parameter and return type annotations.** This includes public methods, private methods (`_` prefix), and utility functions. Only the following are exempt:
   - `__init__` methods may omit the return annotation (`-> None` is the Python convention and can be omitted)
   - Abstract methods may annotate the return as `None` or omit it (subclasses may return different types)
   - Functions in one-off debugging scripts

2. **Class attributes must be annotated at the declaration site.** Instance attributes first assigned in `__init__` should use PEP 526 annotation syntax:
   ```python
   self.running_models: dict[str, InferenceFramework] = {}
   ```

3. **Optional types must use the `X | None` syntax (PEP 604).** Use `str | None` rather than `Optional[str]`. `| None` is the native syntax since Python 3.10, the standard form of PEP 604, and the recommended form for Python 3.14+ lazy annotation evaluation (PEP 649/749); `Optional` remains valid but is not the project convention, avoiding extra `typing` imports and `from __future__` boilerplate.

4. **Replace complex nested types with classes.** Anonymous nested types like `dict[str, list[tuple[int, float]]]` should not exist — replace them with pydantic BaseModel or dataclass. Classes have named fields and docstrings; when you need to change the structure, you only change the class definition. This is friendly to both humans and AI.
   ```python
   # ❌ Prohibited
   def process(data: dict[str, list[tuple[int, float]]]) -> dict[str, float]:
       ...

   # ✅ Correct
   class SamplePoint(BaseModel):
       index: int
       value: float

   class ProcessingInput(BaseModel):
       samples: dict[str, list[SamplePoint]]

   class ProcessingOutput(BaseModel):
       results: dict[str, float]

   def process(data: ProcessingInput) -> ProcessingOutput:
       ...
   ```

5. **The `py.typed` marker file must exist** under `src/package_name/` (PEP 561).

6. **mypy type checking** is already required by §11.1; the `[tool.mypy]` section must be configured in `pyproject.toml` (see §20 skeleton). Type annotations + mypy together form a complete fail-safe device — neither is sufficient alone.

7. `from __future__ import annotations` should only be used when circular imports prevent type annotation evaluation (see §8.6).

**Litmus test:** Open any function — can you accurately state the type of every parameter and the return type just from the signature? If not, the annotations are incomplete. Are there any anonymous nested types (e.g., `dict[str, list[tuple[...]]]`)? If so, they should be replaced with classes.

### 12.2 Naming

Classes PascalCase, functions and variables snake_case, private members `_`-prefixed, constants UPPER_SNAKE_CASE, type aliases PascalCase, module files snake_case.

**Naming as documentation:** File names are the first line of documentation for a codebase. From directory hierarchy and file names alone, a reader should be able to infer the file's purpose, its owning module, and its inheritance relationships. File names are not labels for yourself — they are navigation signals for future readers (including AI agents). When a file must be renamed for a new reader to understand its responsibility, the original naming was a failure.

**Class-path mirroring:** A class name should encode two pieces of information — its **domain** and its **function**. The domain must map to a directory level in the path; the function must map to a file level in the path. `ModelAdapter` should live at `.../models/adapter.py`, not scattered inside `utils.py`. The mechanical rule follows: **a class name's CamelCase words decompose into path components — package → directory → filename (snake_case), one word per level.** `FlowTrainer` → `flow/trainer/trainer.py` (`Flow`=directory, `Trainer`=file), `RippleLoss` → `ripple/loss.py` (`Ripple`=directory, `Loss`=file). **The directory hierarchy already provides domain context; the filename only needs to encode the functional part** — `flow_trainer.py` or `ripple_loss.py` would be redundant, repeating path information already encoded in the directory structure. Exemptions: inside class directories (§8.3), files are named by functional domain and the directory name carries class-name locality; mixin classes (`_`-prefixed or `*Mixin`-suffixed) are named by function (`_ModelGenerationMethods` in `generation.py`, `CheckpointMixin` in `checkpoint.py`); same-family multi-class files (§8.4) are named by functional family (`ModelStageOp` classes in `ops.py`); data-container types (frozen dataclass, pydantic models) are attached to the function family that operates on them and are named by that family (`CompareResult` in `compare.py`); test files are named after the module under test (§11.2), and their helper classes are exempt.

**Why constrain classes but not functions?** Functions get their domain context from the file that contains them — locality is the file's job. Classes are self-locating units referenced across files, and a class may outgrow into a directory (§8.3) — a class name must carry its own locality.

**Litmus test:** Given a class name, can you say where it should live without reading the code? Given a path, can you say which class families it should contain? Naming passes only if both directions answer yes.

### 12.3 Language Convention

**Except as exempted by §17.6**, `README.md` and `README.zh-CN.md` are bilingual — the project's front door is accessible to both the English and Chinese developer communities, the two most active language groups in open source.

All other files — comments, docstrings, architecture documentation, config annotations — use **either Chinese or English, at the author's discretion**. No other languages are permitted. Keep language broadly consistent within a file; a small amount of technical terms, code references, or structural separators may remain in English.

**Config comments** (base `config.toml` and override template `config.override.sample.toml`) default to **English** — they are a user-facing interface, and English is the common language of the global developer community.

**Commit messages** use **English** (see 19.1).

**Technical terms, algorithm names, framework names, and academic concepts** are kept in their original English form — e.g. Flink, 1F1B, KV cache, attention mask, backpressure. These are the shared vocabulary of engineers across all languages. Forcing translation loses information density. The principle is: **accuracy first — do not sacrifice technical expression for language purity.**

Comments explain **why**, not **what**. No useless comments.

### 12.4 File Header Comments: Responsibility Declarations

Every source file must open with a comment declaring the file's function and scope of responsibility, in one sentence. This is a boundary declaration for AI (and for humans) — when AI wants to stuff unrelated methods or classes into a file, the file header is the first line of defense (foolproof design, §2). If the responsibility cannot be stated in one sentence → the file should be split (§1.1).

- The header may be a module docstring or a comment block; language follows §12.3
- `__init__.py` is exempt — its responsibility is re-exporting the public API (§8.6), no need to declare it again
- A responsibility declaration is navigation and foolproofing information, not the "useless comment" §12.3 prohibits — it answers "why does this file exist, and what belongs in it"

**Litmus test:** Can the file header's responsibility declaration answer in one sentence "should this piece of code go into this file"? If not, either the comment isn't clear, or the file boundary has already been breached.

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

### 13.4 Debugging: Simplicity is Reliability

**Principle:** The complexity of your debugging tools must not exceed the complexity of the system being debugged. For the general execution methodology (simple first, assess before acting), see §6.1. Debugging tools are themselves code, and they can have bugs too. When a complex logging framework, distributed tracing system, or async sampler becomes part of the problem, fall back to the simplest reliable tool.

**Technique:** `print()` + stdout redirection is the last and most reliable fallback. This is not a step backward — it is the fallback design principle (§3.1) applied to debugging: degrade to a simpler but more reliable approach to ensure that debugging information is never lost.

**Litmus test:** How long does it take to set up your debugging environment? If the debugging environment itself is more complex than the bug you're trying to fix, your debugging tooling is the problem.

---

## XIV. Dependencies and Deployment

### 14.1 License Constraints

All dependencies must be MIT, Apache 2.0, or equivalent permissive licenses suitable for commercial use. GPL, AGPL, and other viral (copyleft) licenses are forbidden. Check license compatibility before introducing any new dependency.

### 14.2 Dependency Management: uv

All projects use `uv` as the sole package manager. `.python-version` pins the Python version. `pyproject.toml` declares dependency constraints (package name + version bounds). `uv.lock` is **generated from** `pyproject.toml` via `uv lock` and records the fully resolved dependency graph with exact versions and content hashes. Together they form the single source of truth for all dependencies — there is no other dependency specification. Both files are committed to git. `uv sync` sets up the development environment in one command.

**Never edit `uv.lock` by hand.** It is a generated artifact. The dependency change workflow is: `pyproject.toml` → `uv lock` → `uv.lock`. No `requirements.txt`, no `Pipfile`, no environment-variable overrides for dependency versions.

### 14.3 Docker Required

Every project must support Docker deployment. Base image is pinned to a specific version tag (never `latest`). Dockerfile uses two-stage caching (dependencies layer + source layer). Dependencies are installed via `uv sync` or `uv pip install` with `uv.lock` to guarantee the same versions as the development environment. `build.sh` encapsulates the build command.

**Docker layer cache design:** The dependency layer copies both `uv.lock` and `pyproject.toml`. The version number is derived by `setuptools-scm` from git tags (§8.7), and `pyproject.toml` uses `dynamic = ["version"]` (no version string in the file), so version bumps do not change `pyproject.toml`'s file hash. The dependency layer is only rebuilt when `uv.lock` or `pyproject.toml` actually changes — routine version releases and code changes never trigger a dependency layer rebuild.

**BuildKit cache mount:** All `uv sync` and `uv pip install` commands use `RUN --mount=type=cache,target=/root/.cache/uv`. BuildKit persists the `/root/.cache/uv` directory across builds, so even when the dependency layer is rebuilt (e.g., `uv.lock` changed), packages are read from local cache rather than re-downloaded from PyPI. This is the Docker-recommended pattern and should be standard in every modern Dockerfile.

**Version in Docker builds:** `build.sh` obtains the version via `git describe --tags`, passes it as `--build-arg VERSION=X.Y.Z` to the Dockerfile, and the Dockerfile sets `SETUPTOOLS_SCM_PRETEND_VERSION=${VERSION}`. This ensures correct builds in shallow clones, CI environments, and COPY-only contexts (no `.git` directory), while maintaining a single source of truth for the version.

**Recommended Dockerfile template:**

```dockerfile
# Layer 1: dependencies (cached when uv.lock AND pyproject.toml unchanged)
# pyproject.toml IS copied here — version is managed by setuptools-scm
# (dynamic = ["version"]), so version bumps don't change this file's hash
# and don't invalidate this layer.
COPY uv.lock pyproject.toml .python-version README.md LICENSE ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-install-project --frozen --no-dev

# Layer 2: source code
COPY src ./src
COPY configs ./configs
COPY data ./data

ARG VERSION=0.0.0
ENV SETUPTOOLS_SCM_PRETEND_VERSION=${VERSION}

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev
```

**Recommended build.sh template:**

```bash
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")
IMAGE_NAME="${IMAGE_NAME:-project:${VERSION}}"
docker build --build-arg VERSION="${VERSION}" -t "${IMAGE_NAME}" -f docker/Dockerfile .
```

- **build.sh version:** The version MUST be obtained via `git describe --tags`, not hardcoded. The `IMAGE_NAME` environment variable override remains available for manual testing, but the default MUST come from git tags.

**Proxy configuration must not enter the image:** When a proxy is needed during builds to access external networks (e.g. `HTTP_PROXY`, `HTTPS_PROXY`), proxy environment variables **must not** be written into the Dockerfile via `ENV`. Pass them via `--build-arg` in `build.sh` and declare them only as `ARG` in the Dockerfile, so the final image contains no residual proxy configuration. `ARG` values do not persist into the final image; `ENV` values do — a running container that inherits unreachable proxy environment variables will suffer network failures. Internal proxy addresses also constitute secret information as defined in §15.1 — writing them into a Dockerfile is equivalent to permanently embedding internal addresses in git history.

**Anti-pattern (forbidden):**
```dockerfile
ENV HTTP_PROXY=http://proxy.internal.example.com:8080
ENV HTTPS_PROXY=http://proxy.internal.example.com:8080
```

**Correct pattern (recommended):**
In Dockerfile:
```dockerfile
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
```

In build.sh:
```bash
docker build \
    --build-arg HTTP_PROXY="${HTTP_PROXY:-}" \
    --build-arg HTTPS_PROXY="${HTTPS_PROXY:-}" \
    --build-arg NO_PROXY="${NO_PROXY:-}" \
    -t "${IMAGE_NAME}" -f docker/Dockerfile .
```

This rule applies to all configuration that is only needed at build time and must not persist into the runtime image — proxy settings are the most common case, but it also covers private pip mirror URLs, build cache configuration, and similar. Litmus test: is this configuration still needed when the container runs? If not, it must not appear in the final image.

> For constraints on the source of code used during image builds, see §14.4 — regardless of where the image is built, the source code must come from a definite version from the development machine.

### 14.4 Code Sync: One-Way Flow

**Principle:** Code modifications happen in the development environment; the deployment environment only receives code. The flow of code from development machine to deployment machine is one-way — the dev machine is the source of modifications, the deployment machine is the destination. This is §1.4 (Single Source of Truth) extended to the deployment workflow: code content and modification behavior each have their own single authoritative source.

Editing code directly on a deployment machine is a breeding ground for engineering disasters — a fix is made and forgotten, then overwritten on the next deploy; two people edit the same file on the dev machine and the deployment machine, and when it's time to merge, no one can say which version is correct. Code on a deployment machine must be **traceable and reproducible**, which means it must come from a definite version on the development machine, not from someone's impromptu edits in an SSH session on the deployment machine. The deployment machine may not have git access (network isolation, security policies, etc.) — this does not affect the principle: after committing on the dev machine, package the code (tar/zip) and scp it to the deployment machine, and it is still code from a definite version. The key is not the transport mechanism; the key is that code modifications happen only on the dev machine, and the deployment machine only receives code.

**Rule:**
- Code on a deployment machine **must** come from a definite version on the development machine. Direct editing of source files on deployment machines is forbidden. Preferred method: dev machine git commit → deployment machine git pull (when git is accessible from the deployment machine). Alternative method: dev machine git commit → package (tar/zip) → scp/rsync to deployment machine (when git is inaccessible from the deployment machine).
- The **only** allowed form of code modification on a deployment machine is: dev machine edit → dev machine git commit → sync to deployment machine (git pull or scp/rsync). Regardless of the transport method, the code version on the deployment machine must be traceable to a definite commit on the dev machine.
- "Manually sync back to the dev machine" after editing on a deployment machine is forbidden — this is not synchronization; it is dual sources of truth.
- Docker image builds are recommended to happen on the dev machine or CI environment (push image to registry, deployment machine pulls image). Building on the deployment machine from code synced from the dev machine is also acceptable, but building from manually modified code on the deployment machine is forbidden.

**Technique:**
- Set the project directory on deployment machines to read-only (for non-root users), physically preventing direct edits at the filesystem level — this is foolproof design (§2) applied to deployment.
- Deployment scripts (`deploy.sh` or CI pipeline) should start from obtaining a definite version of the code — either `git checkout <tag>` (when git is accessible from the deployment machine) or scp a packaged file from a specific commit on the dev machine (when git is inaccessible). Either way, the deployment script should record the version identifier (commit hash or tag) for this deployment.
- If temporary debugging is needed during deployment, reproduce the issue on the dev machine, modify the code, commit, and deploy the new version — never take the "edit on deployment machine then sync back" path.
- If the deployment machine has git access, keeping the `.git` directory is recommended so you can verify via `git status` that the working tree is clean, and confirm the running version with `git log -1`. If the deployment machine cannot access git, the deployment script should record the version identifier in a `VERSION` file in the deployment directory.

**Litmus test:** Can the code on the deployment machine be traced to a definite version on the development machine (git commit or version marker in the packaged file)? Are there any source code modifications on the deployment machine that were not committed on the dev machine? If the first answer is "yes" and the second is "no," code sync is healthy.

---

# Layer 3: Security and Project Governance

## XV. Security and Secrets

Security is not an afterthought bolted on before release. It is a design constraint that shapes every commit. The principle is simple: **if you don't want it on GitHub, it doesn't belong in any tracked file.**

### 15.1 Pre-Commit Verification

Every commit must pass the following checks. These checks should be integrated into CI or pre-commit hooks, executed by the companion `tools/` scripts, not left to human memory. The constitution defines the categories — the scripts define the exact patterns.

> **A push publishes three things:** ① the content of tracked files; ② the entire git history (including deleted files); ③ commit metadata (author/committer names and emails) and commit messages. All three must be verified before pushing — scanning only the working tree is not enough.

**1. Secrets scan:** No tracked file may contain any secret information. Secrets include:
- Keys, passwords, tokens, private keys of any form
- Internal IP addresses, internal domain names, internal file paths
- Any information you would not want public after open-sourcing

**2. File-type check:** The following must not appear in tracked files:
- `.env` file (only `.env-example` may be committed)
- Build artifacts, caches, virtual environments
- IDE configuration files
- AI-assistant-generated local files (assistant-specific instruction/draft files; must be excluded in `.gitignore`)
- Local and temporary files — all such files must live in `.local/` (see §16)

**3. Content review (human + AI assisted):**
- No training data, user data, or private datasets
- No internal resource references in README

**4. Personal information (PII) scan:** No tracked file or git history may contain information that can be linked to a specific natural person, whether or not it falls under category 1:
- Personal email addresses; instant-messaging accounts such as QQ or WeChat; mobile and landline phone numbers
- National ID / passport numbers, bank card numbers, student IDs, employee badge numbers
- A real name combined with other identity fields (anything that alone or in combination points to a specific person)
- **Exemptions:** public project mailboxes (`noreply@`, maintainer mailboxes), example/reserved domains (`example.com`, `example.org`), and explicit placeholders (`REPLACE_ME`, `your-email@…`)

**5. Commit metadata and message privacy:** For public repositories, `user.name` / `user.email` must not be a personal mailbox or an address containing a personal account (e.g. a QQ mailbox); use the hosting platform's `noreply` address or a project mailbox. Commit messages are scanned as well. Entry points: `git log --all --format='%an <%ae> %cn <%ce>'` covers metadata, `git log --all -p` covers committed content. See §15.3 for remediating historical leaks.

### 15.2 Secrets Management

Secret information must not enter git. Secrets include: keys, passwords, tokens, internal IPs, internal domain names — any information you would not want to appear on GitHub after open-sourcing.

**Secrets storage (TOML override preferred; `.env` is an optional user-side channel):**

1. **`.env` file** (for third-party components that read nothing but environment variables, or for flat key-value cases the user explicitly chooses): e.g., `API_KEY`, `DATABASE_URL`. Store in `KEY=VALUE` format in `.env` (local, **never tracked**). `.env-example` serves as a template in git, listing all required environment variable names and descriptions, without real values. Per §7.1, `.env` is not the preferred source of truth for project configuration — anything that can go into the TOML override should not live here.

2. **TOML override file** (for secrets nested within configuration structures): e.g., `[task.llm].endpoint`, `[database].password`. Use `.local/config.override.toml` (gitignored), following the §7.1 layered configuration pattern — the base TOML contains all fields (secret fields left empty), and the override TOML only fills in the secret values. The program deep-merges them into a single dict on startup.

**Selection criteria:** Prefer the TOML override (the single source of truth for configuration). Use `.env` only when a third-party component reads nothing but environment variables, or when the user explicitly chooses so. **Mixing both approaches for the same field is prohibited** — each secret field must have exactly one source.

**Rules:**
- No literal secret values may appear in any code, documentation, configuration templates (including `.sample` and `.env-example`), or example files
- `.env` and override files must be excluded in `.gitignore`
- Template files (`.env-example` or `config.override.sample.toml`) must be tracked in git, using placeholders (e.g., `REPLACE_ME`) to guide deployers
- Personal information (email, phone numbers, instant-messaging accounts, etc.) that must exist in configuration should go into the TOML override (§7.1); use `.env` only when environment variables are genuinely required. It must not be hardcoded in the base config or templates

**Litmus test:** Can an outsider clone the project and run it (in degraded mode) without access to any secrets? Does the git history contain any secret or personal information?

### 15.3 Post-Leak Response

If secret information was ever committed to git history:
- Confirm via `git log --all --full-history` that no sensitive file history remains
- Use `BFG Repo-Cleaner` to thoroughly purge all traces, then rotate every leaked key
- Confirm `LICENSE` file exists and is correct
- Confirm README contains no references to internal resources

If what leaked is personal information (PII) rather than a secret, the history-rewrite exception still applies (see §19.1). BFG only purges file content — it **cannot** change author/committer emails; doing that requires `git filter-repo --email-callback` (or `git filter-branch --env-filter`), with tags rewritten in step. Afterwards, force-push and ask the hosting platform to purge cached views; forks and third-party mirrors cannot be guaranteed.

---

## XVI. Local and Temporary Files

Every project generates files that are useful during development but have no place in the permanent codebase — run logs, migration plans, deployment notes, personal experiments. Without a designated home, these files scatter across the repository, and sooner or later one of them gets committed with internal IPs or passwords still in it.

### 16.1 `.local/` — The Sole Home for Local and Temporary Files

The `.local/` directory at the project root is the **only** permitted location for local and temporary files. It is excluded entirely in `.gitignore` — nothing inside it will ever be committed.

`.local/` is not a suggestion. It is a rule: any local or temporary file found in a tracked path outside `.local/` is a violation.

`.local/` carries two categories of files:
- **Local deployment files** (long-term): deployment configuration overrides (`config.override.toml`, etc.), localized startup scripts (`run.local.sh`), and other deployment-specific artifacts that are not part of the permanent codebase but persist across sessions.
- **Temporary files** (short-term): run logs, migration plans, deployment notes, personal experiments, debug logs, and other transient artifacts.

### 16.2 What Belongs in `.local/`

A file belongs in `.local/` if it meets any of these criteria:
- Contains runtime environment information (IPs, hostnames, container names, SSH users, internal paths)
- Is a deployment configuration override (`config.override.toml`, etc.)
- Describes a one-time operation (migration plans, deployment records, experiment tracking)
- Is a personal note, debug log, or run monitor
- Is temporary data or an experimental config
- Is any engineering artifact that does not belong in the permanent codebase

If a file has long-term value to the project, turn it into formal documentation under `docs/`. If it only has short-term value to you or the current phase, put it in `.local/`.

**The one exception: the work log (§17.5).** It has long-term value but necessarily contains environment information (resources and environment), so its only home is `.local/` — it must never be promoted to a `docs/` document. This is part of the data boundary (§1.4): environment information never enters tracked files.

### 16.3 Relationship with `scripts/`

§10.2 defines `scripts/` as the directory for shared temporary code tools. The two directories serve different purposes:
- `scripts/` — shared temporary code tools (committed to git, no backward-compatibility obligation)
- `.local/` — private temporary files (never committed, never shared, no obligations whatsoever)

---

## XVII. Documentation System

### 17.1 Bilingual Documentation

**Except as exempted by §17.6**, `README.md` (English) and `README.zh-CN.md` (Chinese) must be **content mirrors**, not just structural mirrors. The same operation instructions, configuration descriptions, and FAQ entries must exist in both versions — one version must never contain information absent from the other. Both READMEs must be updated simultaneously on every release.

Chapter structure: Introduction → Quick Start → Data Format → Configuration Reference → Output Description → Development Guide → FAQ.

### 17.2 Architecture Documentation

Split by topic under the `docs/` directory, each file focused on one concern. The content boundary of documentation is defined by §1.6: **write module boundaries, responsibilities, and interfaces — write structural "why"** — implementation details live in code comments (§12.4), not in docs.

**All diagrams in documentation must be drawn with Mermaid — ASCII hand-drawn diagrams are prohibited.** Mermaid is machine-parseable, natively rendered by GitHub/IDEs, and AI can generate and modify it; ASCII diagrams cannot be maintained, and AI cannot reliably redraw them. Node names must always be wrapped in English double quotes (`"Training Loop"`) for compatibility across renderers. Architecture, flow, data-flow, and swimlane diagrams are essential elements of architecture documentation — after reading it, you know how the system works. Directory trees, tables, and other plain-text structures are not "diagrams" and are exempt from this rule.

**`docs/` is for project-level architecture documentation, not deployment-specific experiment records.** Deployment notes, experiment logs, run monitors, and similar artifacts are temporary files as defined in §16.2 and belong in `.local/`.

**Litmus test:** After reading `docs/`, can a reader (human or AI) describe the system's module boundaries, data flows, and key processes? Can they say why a class is designed the way it is? If the first is yes and the answer to the second lives in code comments rather than docs, the docs/comments boundary is correct.

### 17.3 AI Assistant Documentation

If a project uses AI coding assistants, it may generate assistant-specific local instruction files on demand (high information density, structured) to help AI understand the project's architecture and conventions. These files are **not committed to git** (excluded in `.gitignore`) — they are part of the local development environment. If the project does not use AI assistants, there is no need to create these files.

Projects that use the work log (§17.5) should place a one-line pointer to `work_log_current.md` in the AI assistant's local instruction file, noting that its state section opens with the "User's Original Prompt" anchor, which must be read at the start of every session — so AI discovers both the log entry point and the intent anchor.

### 17.4 Version History

Projects do not maintain a standalone Changelog file. The git commit log is the single, authoritative change history. On release, tag the version with `git tag`. To review changes, use `git log`. Commit messages must follow the format specified in §19.1 so that `git log --oneline` is a readable project history.

### 17.5 Work Log: Continuous Handover

Handover is not an event; it is a continuous state. Instead of writing a compressed handover document at each transition, maintain a work log — essentially a continuously updated handover document that lets any successor (human or AI) continue the work at any time, without asking the original author.

The work log consists of two files under `.local/`, never committed to git (they necessarily contain environment information, §16.2):

- **`work_log_current.md` — the state section, read at every session.** It holds only the latest values, updated in place, never pruned; **the sole exception is the leading "User's Original Prompt" anchor — append-only, never overwritten**. Organized into the following sections: user's original prompt (one sentence recording the user's original task intent, frozen after first write, with new lines appended only when the user explicitly changes the goal; it is the intent anchor across sessions and context compactions, preventing drift in long tasks), current progress, current major difficulties and problems, task plan (checklist format, `[ ]` todo / `[x]` done), unresolved questions (decision points requiring user confirmation), planned solutions to try, resources and environment (servers, GPUs, available tool scripts, etc.), technical conventions and tooling notes (frameworks, design patterns, coding conventions). Keep it under about 100 lines — it carries the "understand the state in 30 seconds" responsibility.
- **`work_log_history.md` — the event section, read on demand.** User original requests, completed tasks, and resolved problems are appended incrementally with timestamps (entries start with `YYYY-MM-DD HH:MM`), newest at the end. When the log grows long, prune selectively: delete from the head (oldest) entries that are **already absorbed into code or docs and no longer worth referencing**; important decision context may be kept forever. **Pruning is a trade-off, not a truncation** — if after pruning a successor cannot understand the current state faster than from reading git log, you pruned too much.

Relationship with git: the git commit log is the authoritative record of changes (immutable, §17.4); the work log is the narrative layer of decision context (selectively compressible). The log records what git doesn't — why, difficulties, plans, next steps. The log is not a Changelog replacement and carries no authority; every statement in it should be cross-verifiable against git or the code.

Division of labor between the state-section anchor and the event section: the event section keeps the **verbatim original request** (prunable with history), while the state-section anchor keeps the **stable intent summary** (never pruned). Different purposes, no duplication.

**When to update:** at the end of each working session or when a phase completes — append 3–5 lines to the event section and refresh the state section (the "User's Original Prompt" anchor stays unchanged unless the goal changes). Projects that use AI assistants place a pointer to `work_log_current.md` in the AI assistant's local instruction file (§17.3).

**Litmus test:** Can a newcomer (human or AI) fully continue the work reading only the work log and the codebase, without asking the original author? If not, the log is incomplete.

### 17.6 Single-Language and Private Projects

**Principle:** Bilingual READMEs (§12.3, §17.1) serve a clear goal: letting open-source projects reach both the English and Chinese developer communities. When that goal does not exist, the bilingual requirement no longer applies — the project should choose the language of its widest target audience and stay consistent.

**Rule:** A project meeting either of the following conditions may keep only a single `README.md`, with language kept consistent (Chinese or English at the author's discretion):

1. **Private project**: the project is not pushed to any public repository (GitHub, GitLab, Gitee, etc.) and is used only within an intranet or private repository.
2. **Single-language audience project**: the target user community is clearly a single-language group (e.g. Chinese-only or English-only), and the maintainer judges that a bilingual README would not yield practical community coverage benefits.

**Technique:**
- Exempt projects should clearly state the document language in the sole README (e.g. "This document is in Chinese") to avoid reader confusion.
- Choose the language based on the target audience: Chinese for Chinese-speaking communities, English for English-speaking communities.
- If the project later becomes open-source or expands its audience, add a bilingual README at that point — this is not debt; it is a scope change.

**Litmus test:** Does the project's target audience include both Chinese and English-speaking communities? If not, and the project is not in a public repository, a bilingual README produces no practical value.

---

## XVIII. Version Evolution and Debt Management

Technical debt is the cancer of engineering quality. Today's shortcut becomes tomorrow's double workload, and the day after tomorrow's untouchable forbidden zone. The core principle is one sentence: **once the new architecture is validated, the old architecture must be eradicated.**

### 18.1 No Debt Left Behind

- After the new architecture is online, tested, and stable, old code is **deleted immediately**. No "compatibility mode" kept around. No `legacy/` directory. No `# TODO: remove after v2` comments. The codebase contains exactly one current architecture (migration scripts are an explicit exception, see §18.2).
- When deleting old code, simultaneously update: naming (no more `v2`, `new`, `legacy` prefixes/suffixes), config templates (`config.toml` and `config.override.sample.toml` reflect the current architecture), documentation (architecture descriptions in README and docs/), tests (delete tests for the old architecture — don't keep them "just in case").
- Version numbers are updated on every release, following `MAJOR.MINOR.PATCH`: architecture refactors and incompatible config changes bump MAJOR, new features bump MINOR, bug fixes bump PATCH.

### 18.2 Legacy System Migration

When users of an old version need to upgrade to the new architecture, provide a one-click migration path:

- Migration scripts go in the `scripts/` directory, named as: `migrate_v1_to_v2.py`, `migrate_config_v2_to_v3.sh`
- The script header comment states: source version → target version, what is being migrated (config file format, checkpoint format, data format), parts that cannot be auto-migrated (requiring manual user action)
- Migration scripts are not the old-architecture code referred to in §18.1; they are modules in the new codebase responsible for upgrading old data/old configuration. Migration proceeds generation by generation: upgrading across several major versions may require running multiple migration scripts in order, so older migration scripts remain in `scripts/` as an upgrade chain for users who skip versions.

**Litmus test:** When a new person clones the project, can they see traces of the old architecture? If so — leftover code, outdated comments, un-updated config templates — version management has failed.

---

## XIX. Open Source Management

### 19.1 Git Workflow

- Direct commits to `main` / `master` are forbidden
- **Solo projects:** a single-developer project may push directly to the main branch. Good commits are sufficient — the PR workflow overhead is unnecessary when there is no second pair of eyes to review. If the project later gains additional contributors, adopt the branch-and-PR workflow at that point.
- All development happens on feature branches: `feature/<description>`, `fix/<description>`, `docs/<description>`
- Merging to main requires a PR — at minimum, self-review the diff
- Commit messages are **recommended** to be in English, format: `type: short description` (feat, fix, docs, refactor, test, chore). English is the de facto standard of the open source community — the `git log --oneline` toolchain is English-first, and it enables international contributors to understand the project's history. Projects whose primary contributor community uses another language (e.g. Chinese) may use that language, but should stay consistent within one repository.
- **History continuity over retroactive fixes.** Commits already pushed to a public repository MUST NOT be rewritten to fix message language — changing pushed history breaks every collaborator's local clone. The specification takes effect from the current commit forward. The exception is security: if a historical commit contains leaked secrets or personal information, history MUST be rewritten (see §15.3).
- One commit does one thing

### 19.2 .gitignore Must Cover

- Python runtime: `__pycache__/`, `*.pyc`
- Virtual environments: `.venv/`, `venv/`, `venvs/`
- Test and type check caches: `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`
- Build artifacts: `dist/`, `build/`, `*.egg-info/`
- Environment config: `.env`, `*.env` **must always be ignored** (`.env` is never tracked, §15.1); `.env-example` is only needed when the project has non-infrastructure environment variables — infrastructure-only projects
  (e.g. those using only standard CUDA/NCCL/PyTorch distributed env vars
  like `CUDA_VISIBLE_DEVICES`, `NCCL_*`, `PYTORCH_*`, `RANK`, `LOCAL_RANK`,
  `WORLD_SIZE`, `MASTER_ADDR`, `MASTER_PORT`) may omit `.env-example`
- Configuration overrides: `config.override.toml`, `my_config*.toml`, `config.local.toml`, `*.local.toml`
- Outputs and data: `outputs/`, `data/` (except sample data)
- IDE: `.idea/`, `.vscode/`
- AI assistant local files: assistant-specific local instruction/draft files (must be excluded in `.gitignore`)
- Local and temporary files: `.local/`
- System files: `.DS_Store`, `Thumbs.db`

### 19.3 Open Source License

Default: MIT license. `LICENSE` file at the project root. If the project depends on Apache 2.0-licensed libraries, consider using Apache 2.0 for compatibility.

---

## XX. pyproject.toml Skeleton

```toml
[project]
name = "my-project"
dynamic = ["version"]
description = "One-sentence description"
readme = "README.md"
license = {text = "MIT"}
requires-python = ">=3.11"
dependencies = [
    "pydantic>=2.0",
]

[project.scripts]
my-project = "my_project.cli:main"

[project.optional-dependencies]
dev = ["pytest>=8.0", "ruff>=0.6", "mypy>=1.0"]

[build-system]
requires = ["setuptools>=75.0", "setuptools-scm>=8.0"]
build-backend = "setuptools.build_meta"

[tool.setuptools.package-dir]
"" = "src"

[tool.setuptools_scm]
tag_regex = "^(?:v)?(?P<version>[0-9]+\\.[0-9]+\\.[0-9]+)$"

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