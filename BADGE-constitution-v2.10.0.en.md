# BADGE Development Constitution v2.10.0

> **B**oundary **A**nd **D**efensive **G**uard for **E**ngineering — Boundary and Defensive-Guard Engineering Development Constitution
>
> Great projects aren't built by checking harder — they're built by designing so that mistakes are impossible.
> This constitution is the distillation of engineering taste — it tells you why a design is right, not just what to do.
>
> **The three-layer structure of this constitution:** Principles tell you why a design is right. Rules tell you what you must do. Techniques tell you how to do it. Principles without rules are empty words. Rules without techniques are unenforceable. Techniques without principles leave you not knowing why you're doing them. All three are essential — none is optional.

> **How to read this constitution.** Every clause of this constitution is a **conceptual statement**: it gives concepts, criteria, and general explanations. The concrete instances, specific values, specific forms, and literal values that appear in a clause **are examples, not a closed list** — replacing them with other values of the same kind does not change the clause's meaning, and **you must not infer from one example that other cases do not hold**. Concrete samples and decision rules that a tool can mechanically verify **are not in this constitution**; they are carried by the `tools/` scripts (the division of labor in §15.1's first paragraph). The complete rules for the text's writing style, their exceptions, and the revision process are in **§17.8**; this paragraph is only a **reading guide** — **it sets no criterion and carries no mandatory force**.

---

# Preamble: The Execution-First Principle

**Faithfully understand and implement the user's instructions and goals, at minimum cost and maximum speed: fidelity first, cost second, speed third.**

When you receive a task, first ask: **What does the user actually want? Is this task hard?** Once you have assessed complexity, reversibility, and ready-made entry points, decide in order:

1. **Fidelity first**: Make implementing the user's instructions and goals the sole yardstick — no more, no less; understand the intent faithfully before acting.
2. **Cost second**: Provided fidelity and risk are under control, finish at minimum cost; if it can be done in one pass, do it in one pass; if a simplest path exists, take it. **Entry points first** — look for existing scripts, README, docs, and other entry points in the directory the user gave you to build the full picture, then decide whether to read the source in depth.
3. **Speed third**: Never sacrifice fidelity or safety for speed, and never sacrifice cost for "comprehensiveness."

**Why simple-first:** Simple operations are hard to get wrong — this is Occam's razor applied to engineering execution, and one of the means of foolproofing (§2) and raising task success rate.

Here **cost** means effort and resource consumption (tokens, tool calls, footprint of change); **speed** means wall-clock time and number of interaction rounds. When the two conflict, cost wins — rework is the largest time expense.

**Litmus test (without violating this constitution's mandatory clauses):** Can every unit of work in the deliverable be traced to "the user explicitly asked for it" or "it is necessary to fulfill that request"? Anything that cannot is over-execution. If any explicit requirement in the user's goal is unmet, that is under-delivery — "do no more" is never a license to "do less."

**Risk gate (deciding whether to spend more cost): The cost paid to control a risk must be far smaller than the cost if the risk materializes.**

- **Reversible**: the consequence is minor, controllable, and rollback-able — **all three at once** (e.g., editing docs, editing **local** config, a re-runnable script) → **just do it**; inspecting every circuit in the whole building for this is a huge waste.
- **Irreversible**: **any one** of the three fails (e.g., deletion, **data** migration, external release, production config change) → **pay the necessary cost of one quick verification first** (backup, boundary validation, pre-authorized fallback). **When in doubt, treat it as irreversible.**

**This principle only adjusts the depth of execution and the completeness of the deliverable; it exempts no mandatory clause** — security and secrets (§15), contracts and interfaces (§2.1), boundary validation (§2.3), operational foolproofing (§2.4), Single Source of Truth (§1.4), task decomposition (§1.5), fallbacks (§3), and all other mandatory clauses apply in full, **regardless of whether the consequence is reversible.** For reversible tasks the deliverable takes these mandatory clauses and the user's explicit acceptance criteria as its floor and is **minimally sufficient** — stop once the acceptance criteria are met, and do not add unrequested refinements, examples, or review rounds; the floor is not lowered. **§6 reproduction is not among them** — it has its own applicability precondition (see §6): it is pursued only when "the result needs to be produced a second time in the future, and the second time must be consistent with this time", and the meaning of "consistent" is determined by the effect defined by the requirement.

**Escalation signal:** Only escalate to root-cause investigation when a simple approach fails once, or the same problem recurs.

**Complexity discipline (the mirror of the escalation signal):** Complexity may only be added one layer at a time, and every layer must prove that it is necessary.

- **Start from the minimal viable form**: deliver the simplest form that meets the requirement first; do not introduce the next layer of complexity before that one works.
- **Every layer must be ablated** (an ablation experiment: remove the layer, then re-measure): each added layer (module, parameter, abstraction, branch, dependency) must be justified by an ablation — remove that layer: does the requirement-defined effect degrade noticeably? If you cannot answer, or removing it changes nothing, delete the layer rather than keeping it "just in case."
- **Never invent requirements for the user**: function and form are defined by the user. The "more general / more complete / more elegant" the user never asked for is not a requirement — it is over-execution.

---

# Layer 0: Project Classification and Compliance Scope

The BADGE Constitution classifies projects into three categories, each with a different scope of applicable clauses. This constitution targets Python projects, and its design philosophy (Layer 1) is language-agnostic and can be applied to other languages by analogy.

## Three Project Categories

- **Category A (Open-source Python projects)**: Public repositories, community audience. The full constitution applies (§1–§20; §6 reproduction takes effect according to its applicability precondition and the effect defined by the requirement, see §6).
- **Category B (Closed-source Python projects)**: Private repositories, internal teams. Apart from the explicit relaxations listed below, all other clauses of this constitution apply: bilingual README exemption (§17.1, taking effect per §17.6), config format is a suggestion rather than a mandate (§7), the `__main__.py` exemption for Docker-deployed projects (§8.1, see that clause for the applicable conditions), and the graded exception for non-credential company-internal information (§15.4, limited to projects not pushed to a public repository). The mandatory core is security (§15), foolproofing (§2), and reproducibility within the scope of §6.
- **Category C (Other infrastructure projects)**: Projects that are neither Category A nor Category B (see "Classification Determination"). Design principles (§1–§5) must be followed; §6 reproduction takes effect according to its applicability precondition, see §6; §11.5 (acceptance is user-facing acceptance), §15 Secrets Management, §15.4 (graded exception, applicable when the project is not pushed to a public repository), §16 `.local/`, §17.3–§17.5 and §17.7–§17.8 Documentation System, §19.1–§19.3 Open Source Management apply mandatorily; the remaining clauses of §7–§20 do not apply by default.

**Classification decides the scope of clauses, not how §6 reproduction is judged**: across all three categories, §6 reproduction asks only "will it run a second time, and does the second run have to be the same", and judges by the effect defined by the requirement.

## Classification Determination

A project has a `pyproject.toml` and builds a Python package → Category A (public repository) or Category B (private repository). Otherwise → Category C. If it's not A or B, it's C.

## Conflict Resolution Framework

When a project's current state conflicts with a constitutional clause, use the three-question framework:

1. What is the project's core objective?
2. How can this project align with BADGE design principles and philosophy?
3. Does the specific constitutional clause help achieve BADGE design principles and philosophy, or does it impose unnecessary burden that violates the project's core objective? Is this restriction reasonable?

## Litmus Tests by Category

**Category A litmus test**: Is this clause necessary for the open-source community?

**Category B litmus test**: Is this clause about making the team safer and more efficient, or about satisfying the open-source community? The former must be kept; the latter may be relaxed.

**Category C litmus test**: Is this clause a concrete engineering embodiment of BADGE design principles (§1–§5), or is it a detailed requirement specific to Python software projects? The former must be followed; the latter is exempt for Category C. §6 reproduction does not participate in this litmus test; it takes effect according to its own applicability precondition (see §6).

## Compliance Detection

Project classification is not hardcoded within the project itself. When running compliance detection scripts, the classification is passed via a command-line argument (e.g. `--class A`), allowing flexible adjustment of the detection level.

## Configuration Format: TOML First

New projects should use TOML as the configuration format. Existing projects using YAML should not be changed unless actively migrated. The constitution does not mandate migration for existing YAML projects, but recommends migrating during refactoring.

---

# Layer 1: Design Philosophy

## I. Boundary Thinking

Boundaries are the first step of system design. From network boundaries between services down to parameter boundaries between functions — where you draw the line determines the complexity distribution, testability, and extensibility of your entire system. Draw boundaries first, then fill in the implementation.

### 1.1 Module Boundaries: One Thing Well

Each module does one thing and does it well. If a module's responsibility can't be described in a single sentence, split it. The internals of a module can be complex, but the boundaries between modules must be clean and simple.

**The practical effect of good boundaries:** when modifying upper-layer code, you never need to open lower-layer files — you only need to know the lower-layer module's interface and responsibility, not read its implementation.

**Litmus test:** Can you, without reading the code, accurately describe a module's responsibility from its name and interface signature alone? If not, the boundary isn't clear. When modifying a module, does the number of downstream files you need to open approach zero? If not, the boundary needs reinforcing.

### 1.2 Interface Boundaries: Stable Abstractions, Swappable Implementations

Modules communicate through stable abstract interfaces, never depending on each other's concrete implementations. To add any new kind of implementation — just implement the interface and register it, without modifying any existing code. Open for extension, closed for modification.

**Litmus test:** How many lines of existing code need to change to add a new implementation? If the answer is more than zero, the interface boundary needs redesign.

### 1.3 Layer Boundaries: Computation vs. Infrastructure

There are only two kinds of code: code that does **computation** (algorithms, business rules, data transformations), and code that does **infrastructure** (access to external resources such as hardware, networks, filesystems, and databases). Computation code depends on zero infrastructure — it can run single-threaded locally, be tested independently, and reproduce in any environment (same input, same output). Infrastructure code connects computation results to the real world.

This idea comes from distributed big-data systems like Flink and Hadoop — don't make engineers juggle business logic, low-level implementation, and infrastructure simultaneously. No one can do all three well at once.

**Litmus test:** Can you run the core computation logic tests without starting a GPU, without a network connection, without reading files? If not, the layers aren't separated.

### 1.4 Data Boundaries: Single Source of Truth

Every piece of information in the system has exactly **one** authoritative source. Configuration has exactly one authoritative entry point (single source of truth) — no environment variable fallback chains (the narrow env-var exceptions are in §7.1). State is maintained in one place — no multi-copy synchronization. Data flows in only one direction — no callbacks, no circular dependencies.

"The value can come from three places" sounds flexible, but in practice it leaves the user changing a parameter and not knowing why it doesn't take effect.

**Litmus test:** If someone asks "where does this value come from?", can you give the unique answer in one second? If not, there are too many sources.

> This principle extends to deployment workflows: on deployment machines, the development machine is the sole source of code — see §14.4.

> This principle extended to where documentation lands: **every piece of information needs only one authoritative source; it is not that every piece of information needs a document.** When a piece of information is implemented by code, **the code is its authoritative source** (§1.6) — check scripts, tests, config schemas, and `--help` are naturally versioned and naturally reviewable, so the problem of "a second document that is not versioned" does not arise, because there is no second document at all. The only form that violates this principle is: **the same piece of information exists both in code and in an independently editable explanatory document, and both can be treated as authoritative** — the solution is to **eliminate the second one** (push it down into code, or delete it), **not to add a directory**. The only home for repository documentation is `docs/` (§17.2); no separate documentation directory is set up; content that is neither user-facing nor acceptance-facing lands in `.local/` (§16.2) or in code comments (§1.6).

### 1.5 Task Boundaries: Decomposition is Execution

Module boundaries constrain code structure. Task boundaries constrain the development process. The same principle: **one task does one thing. Finish one thing before starting the next.**

When facing a complex problem, the human instinct is to "solve everything at once." The result: context bloat, declining decision quality, and unverifiable intermediate states. The principle: complex problems must be decomposed into independent sub-tasks with clear boundaries — each sub-task has explicit inputs, verifiable outputs, and no dependency on other sub-tasks' internal state.

**Rule:** A sub-task must be independently completable and produce a verifiable result. Sub-tasks communicate through explicit input/output interfaces — never through shared implicit state. The caller must be able to determine whether a sub-task succeeded solely from its output.

**Technique (AI-assisted development):** Break a large task into multiple specific, single-responsibility sub-tasks. Dispatch them to agents in parallel, each producing independently verifiable results. Aggregate at the end. Benefits: saves context window, yields more detailed output, reduces total elapsed time, and each sub-task's correctness is independently verifiable.

**Granularity fit:** Decomposition granularity is determined by task complexity — simple tasks are not split by force. For execution-level assessment and path selection, see the Preamble "Execution-First Principle".

**Litmus test:** Can a sub-task be completed independently and produce a verifiable result without relying on the context of other sub-tasks? If not, the decomposition isn't fine enough. After a sub-task completes, can the caller determine success solely from its output? If not, the output boundary is unclear.

### 1.6 Documentation Boundaries: Details in Comments, Structure in Docs

In the AI era, code is the first document — AI reads and writes code directly, and maintaining a detailed architecture document that stays in sync with the code is both expensive and inevitably stale. The boundary between architecture documentation and code comments is itself a boundary decision:

- **Architecture documentation** — for humans and AI. It describes module boundaries, responsibilities, and interfaces, with architecture, flow, data-flow, and swimlane diagrams — after reading it, you know how the system works. No implementation details.
- **Code comments** — for AI. First, they explain the logic of key code and the design rationale (why it is designed this way). Second, each file opens with a responsibility declaration — what this file does and its scope of responsibility — drawing a boundary around the file so that AI doesn't pile unrelated methods or classes into it during modification (a foolproofing device, see §2).

**Litmus test:** Can the architecture documentation explain how the system works without containing implementation details? If not, details haven't been pushed down into comments. Can the file header's responsibility declaration answer in one sentence "should this piece of code go into this file"? If not, the file boundary isn't clear.

---

## II. Foolproof Design

Automotive design has a principle: a floored accelerator has a rev limiter, a gearshift has a synchronizer, brakes override throttle, and the defog button is placed within easy reach. The manual is hundreds of pages — few owners ever read it — yet accidents are rare, because **the system doesn't allow people to make mistakes.**

Software should be the same. Don't pray for careful developers or hope users read the docs carefully. Design so that mistakes are literally impossible.

### 2.1 Contracts as Foolproofing

Every interaction across a boundary is governed by a **verifiable contract**, never by convention or guesswork. Pydantic models validate config fields. ABC abstract classes force subclasses to implement hooks. Type annotations let mypy check data flow. These aren't "best practices" — they're foolproofing devices. Developers don't avoid mistakes because they're careful; they avoid them because the system won't let them happen.

### 2.2 Explicitness as Foolproofing

No magic in the code. State is explicit. Data flow is visible. Dependencies are declared. No string-concatenated paths. No `**kwargs` passed all the way through, leaving parameter origins untraceable. No `hasattr` probing for business interfaces. Implicit behavior is the biggest obstacle to understanding code — for humans and AI alike. When everything is explicit, errors have nowhere to hide.

**Reasonable use of `**kwargs`:** In the adapter pattern for ABC abstract methods, `**kwargs` is allowed as an extension point — different subclasses may need different domain parameters, and the base class should not modify its interface for each subclass's special needs. The key: `**kwargs` must document in the docstring what additional parameters subclasses may accept, so callers know what to pass.

**Reasonable use of `hasattr`:** The following three scenarios allow `hasattr`:
1. **Runtime capability detection**: detecting whether the runtime environment supports a certain feature — more reliable than parsing version strings
2. **Cross-version compatibility handling**: handling the case where upstream libraries of different versions return different output types
3. **Duck-typing type judgment**: determining an object's type affiliation without introducing a hard dependency

What is forbidden: using `hasattr` to probe business interfaces in your own project — that means the interface contract is unclear. Use ABC or Protocol to define explicit interfaces instead.

**Null-value semantics: `None` is the only legal null value.** Using `0`, `-1`, `""`, `[]`, `{}`, or any other non-None value to express "absent/not-provided/invalid" semantics is prohibited. `None` is the only value in Python's type system with "null" semantics; using other sentinel values bypasses the type checker's null detection and introduces the ambiguity of "is this an invalid value or a real value". `None` has no such ambiguity.

**Exception:** The natural zero point of a numeric value does not carry "null" semantics and is not subject to this rule. Using other non-None values as sentinels is allowed only when the value has clear, irreplaceable semantics in the domain and cannot be expressed with `None`. Such exceptions must be justified in a comment.

**Serialization-boundary exception (TOML):** TOML has no null literal. The base configuration may use `""`, `0`, and `[]` to mean "not provided", but **only at the serialization/deserialization boundary**, and the loader must immediately normalize them to `None` before any business code sees them (see §7.1). This exception does not apply to semantic expression inside Python code.

**`= None` must be paired with an optional type annotation.** When a parameter or attribute defaults to `None`, the annotation must be written `X | None` (i.e., `x: str | None = None`, not `x: str = None`). The type annotation is part of the contract — `str = None` tells the type checker "this value is always a str", but at runtime it may be `None`, which is a self-contradictory contract.

**Null-value checking:** When checking values of an optional type (`X | None`), use `is None` / `is not None`, not `if not x`. `if not x` treats `0`, `False`, `""`, and `[]` all as "empty", causing logic errors. `is None` matches only `None`, with no semantic ambiguity.

**Litmus test:** Does the codebase use `0`, `-1`, `""`, or other non-None values with "null/invalid" semantics? If so, does each have a comment justifying the choice? Are all `= None` defaults paired with `X | None` annotations?

### 2.3 Boundary Validation as Foolproofing

Data must be validated when crossing boundaries. Validate all config fields at load time, reject unknown fields, check required fields. Validate request format before an API request is sent; validate response structure on receipt. Check before output is written to disk — whether it would overwrite existing data, whether it would leak sensitive information. Errors are intercepted at the boundary — illegal data never flows inward, sensitive data never flows outward.

Boundary validation rejects an illegal request — that is not a "fallback", it is a "defense line".

### 2.4 Operational Foolproofing

**Principle:** A destructive operation must make "what is about to happen" visible to the operator before execution. Deletion commands must not rely on implicit wildcard expansion — the result of wildcard expansion is invisible to the operator before execution, and this is the root cause of accidental deletion. The way to foolproof is not to trust the operator to be careful; it is to make it impossible for the operator not to see.

**Rule:** Before executing any deletion command, first list the targets to be deleted with a listing command; once confirmed correct, delete them item by item using specific names. **Wildcards (`*`, `?`, `[...]` and other shell glob patterns) are strictly forbidden in deletion commands.**

**Technique (wildcard exception handling):** When the number of files to delete is genuinely large and a wildcard is truly needed, output the complete deletion command to the user, who reviews it manually and executes it themselves. AI assistants must not automatically execute deletion commands containing wildcards. This is not a matter of judgment — it is a design constraint: not distrusting the driver, but giving no one the opportunity to make a mistake.

**Litmus test:** Before executing a deletion, can you name every single target that will be deleted? If not, the operation does not comply with this clause.

---

## III. Fallback Design

The core principle of fallbacks: **degradation may change the cost, but never the result.**

### 3.1 Same-Result Fallbacks

The system may execute these automatically, without notifying the user. The result is unchanged — only the cost changes (time, resources, speed).

Fallbacks the system may execute automatically: the result is unchanged and only the cost changes (time, resources, speed). The concrete form is determined by each project according to this criterion.

### 3.2 Transparent Fallbacks

The result may be affected, and the system must clearly inform the user. Log at WARNING level, expose in metrics, let the user decide whether to intervene.

When the result may be affected, the system must clearly inform the user (logs, metrics, etc.) and let the user judge whether to intervene. The concrete form is determined by each project according to this criterion.

### 3.3 Pre-Authorized Fallbacks

The result changes significantly, and the user must **explicitly declare acceptance** in configuration. Default: off. This is not a runtime decision — it's a pre-deployment decision.


The constitution does not prescribe specific config key names — each project defines its own toggles. The principle is: if the result changes significantly, the user must say "yes" before deployment, not discover it only afterward.

### 3.4 Fallbacks vs. Defense Lines

A rejection that belongs to boundary validation is not a fallback — it is a defense line; a degradation that changes the result while the user is unaware is a bad fallback.

---

## IV. Zero-Step Onboarding

A new user clones the project and gets results with the fewest possible commands. No extra system dependencies to install (all in Docker). No manual configuration (defaults are production-grade reasonable values). No need to understand the internal architecture (copy the example config and go).

**Zero-step does not mean zero configuration. It means the default configuration is a working configuration.** If the user must understand the meaning of 10 parameters before they can begin, zero-step onboarding has failed.

**Litmus test:** How many steps does it take for a new user to go from clone to first output? If it's more than 5, rethink.

### 4.1 Startup Script

**Principle:** If a project requires a shell script as the user entry point (wrapping Docker startup, environment variable setup, CLI parameter passing, etc.), that script must be placed at the project root so the user can spot it immediately without searching the directory tree.

**Rule:**
- At most **one** startup script at the project root (build scripts do not count as the "startup script" of this clause, see §10.2, §14.3), recommended name `run.sh`. This is the project's first interface to the user — after cloning, `ls` reveals it immediately.
- This script is part of the user contract and is subject to §10.2 institutionalization criteria: it is referenced by the README, used repeatedly by workflows, and is a stable interface — do not casually change its parameter signature.
- CLI parameters passed by this script must obey the three principles of §10.1 — only input-locating parameters, runtime-environment parameters, and run-boundary parameters (for the definitions and judgment of the three kinds, see §10.1). All output-affecting parameters must go into the config file and must not be hardcoded in `run.sh`.
- This script does not belong to the `scripts/` directory (§10.2) — `scripts/` holds temporary developer-oriented tools, while `run.sh` is a stable user-facing entry point. The two must not be confused.

**Technique:**
- The minimal `run.sh`: set the necessary environment variables, then start with `python -m <package>`, passing `--config` through to the user.
- If the project also has Docker deployment (§14.3), `run.sh` may wrap the `docker run` command so the user can start the project without knowing Docker details.
- If the project does not need a shell wrapper (i.e. `pip install` followed by `python -m project` works directly), `run.sh` is not required. Not every project needs one.

**Litmus test:** After cloning, can a new user find the startup entry point within 5 seconds? Seeing `run.sh` with a single `ls` is a pass. If they need to `cd scripts/`, scan the README, or search, it's a failure.

### 4.2 Startup Script Localization

**Principle:** `run.sh` should work in any deployment environment without modification.

**Rule:**
- Localization should prefer `run.sh`'s own parameters (CLI flags, see §4.1 and §10.1) or a local override file under `.local/`; do not treat environment variables as the project's normal source of configuration (the narrow exceptions are in §7.1).
- When localization is needed, the user creates `.local/run.local.sh`, which calls the base `run.sh` with explicit parameters. The base `run.sh` remains the authoritative, portable entry point.
- `run.local.sh` is the localized variant — it is gitignored and only forwards parameters or overrides values; it must not duplicate the base logic.
- Only when a third-party component (e.g. a Docker/container interface) accepts nothing but environment variables may `${VAR:-default}` be used inside that adapter boundary. Such usage must be centralized, explicit, and commented — never scattered across the project.

**Technique:**
- The recommended pattern: `run.sh` defines paths and settings as script variables with defaults and exposes matching `--xxx` flags; `run.local.sh` calls the base `run.sh` with explicit parameters.
- If a third-party tool can only be configured through environment variables, export those variables in `run.local.sh`, mark them as a "third-party adapter" in a comment, and keep the base `run.sh` independent of them.

**Litmus test:** Can a new deployment environment start the project without editing `run.sh`? If environment variables must be set first, is it confirmed to be an allowed §7.1 third-party adapter case, clearly documented, and with reasonable defaults?

---

## V. Correct First, Optimize Later

Performance optimization is necessary, but not at the cost of correctness and maintainability. The principle: **guarantee correctness first, then pursue performance. But never design an architecture that cannot be optimized.**

The computation-infrastructure separation already provides a natural foundation for optimization — core algorithms can be independently tuned, decoupled from distributed communication or I/O. Stable abstract interfaces guarantee that replacing an inefficient implementation doesn't affect upper layers. If "code elegance" couples together multiple operations that should be executed independently, so that later you want to parallelize them and find they simply can't be separated — that's over-design. It sacrificed optimization potential for nothing in return.

**Litmus test:** If you discover a component is a performance bottleneck, can you replace it without touching the code above it? If not, the architecture needs rethinking.

---

## VI. Reproduction: The Effect Defined by the Requirement

**When reproduction is needed:** Only when this result **needs to be produced a second time in the future, and the second result must be consistent with this one**, is reproducibility pursued; otherwise reproduction is not pursued — no reproduction-specific mechanism is added, and bit-for-bit consistency is not pursued for tasks whose fluctuation is allowed; the mandatory force of mechanisms such as §14.2, §14.3, and §8.5 is independent of whether reproduction is needed, and each applies according to its own scope. The judgment is one sentence: **Will it run again? Does the second run have to be the same as this one?**

**What counts as reproduction: the effect defined by the requirement is achieved again.** Reproduction has no fixed threshold — the meaning of "consistent" is determined by **the effect defined by the requirement**. First clarify what the requirement asks for, then judge reproduction on that basis:

- The requirement is "the result is completely correct" → reproduction means complete consistency with the correct answer defined by the requirement;
- The requirement is "the picture looks the same" → looking the same is reproduction;
- The requirement is "the task is completed" → task completion is reproduction;
- The requirement is "a certain metric is reached" → the metric being reached is reproduction.

The key is **first clarifying what the effect defined by the requirement is**. When the requirement does not define "consistent", do not default to executing at the strictest degree (e.g. bit-for-bit consistency) — that may both exceed the requirement and drag a task whose fluctuation is allowed into pointless cost. Fluctuation itself is not a defect: as long as the effect defined by the requirement is achieved, that is reproduction. When the requirement is undefined, **do not unilaterally presume a threshold**: first clarify with the requirement owner "what effect counts as achieved"; before that clarification, do not treat "error-free" as the default criterion for having reproduced; neither default to the loosest degree nor default to tightening at the strictest degree — tighten only when the requirement explicitly demands stronger consistency.

**How to implement reproduction: use this constitution's existing engineering mechanisms to make "running it again" achieve consistency under conditions.**
- Dependencies and environment: `uv` + `uv.lock` pin exact versions (§14.2), `.python-version` pins the interpreter; the run carrier (e.g. the Docker base image) is locked to a specific version tag per §14.3
- Version management: code and configuration go into git, and the code comes from a definite commit (output is additionally determined by config and seed) (§14.4, §17.4)
- Explicit configuration: parameters that affect output go into the config file (§10.1); if the task involves randomness and its effect is sensitive to randomness, the random seed is explicitly set in the configuration, never dependent on system time or hardware state
- Output archival: the configuration of each run is backed up together with the output (§8.5), and when needed it is recorded together with the criterion by which this run is "consistent" (into this run's config backup or work log, §17.5)

The presence of the mechanism is verified by `tools/check_reproducibility.sh`.

**Litmus test:** Can you state in one sentence what the effect defined by the requirement for this run's "consistent" is? Calling "consistent" "bit-for-bit identical" when the requirement does not demand it is over-execution; failing to state the effect clearly means reproduction has not yet been defined.

**Boundary:** The reproduction mechanism itself is also subject to the Preamble's "risk gate" — additionally building reproduction-specific gates for a result that will never run a second time, or pursuing bit-for-bit consistency for a task whose fluctuation is allowed, costs far more than it gains and is over-execution. Parameter placement is decided by the principles of §10.1, together with §1.4 (Single Source of Truth) and §7.1 (single configuration entry point); reproduction is only the means of verification (see §10.1).

---

# Layer 2: Engineering Standards

## VII. Configuration System

### 7.1 Single Configuration Entry Point

**Principle:** Configuration has exactly one authoritative entry point: a git-tracked base `config.toml` holds the defaults, organized into sections by functional domain, optionally overlaid by a gitignored override configuration; after deep merge there is only one configuration in the program. TOML is the standard configuration format of the Python ecosystem (same format as `pyproject.toml`), with a type system that natively supports nested tables and arrays. Except for the environment-variable exceptions this section explicitly allows, do not use environment variables to carry configuration values, and do not use CLI arguments to implicitly override the configuration file. Configuration is configuration, environment is environment — keep them separate.

> This constitution targets Python projects. This section and all subsequent concrete rules are anchored in the Python ecosystem. The design philosophy (Layer 1) is language-agnostic and can be applied to other languages by analogy.

**Environment-variable policy:** Environment variables are an invisible, hard-to-control configuration channel and must not be the single source of truth for configuration. They are allowed only for these three uses: ① standard infrastructure variables — **the exact matching is defined by `tools/check_config_system.sh`** (§15.1 first-paragraph division of labor); ② third-party components that accept nothing but environment variables and cannot be adapted through configuration (an adapter layer for that component); ③ genuinely tiny projects that have exactly one configuration. Outside these three cases, environment variables must not carry configuration or path parameters (§10.1). Any configuration that arrives via environment variables must be read centrally at startup and normalized into the same configuration-loading path — never read ad hoc at usage sites. A user's own choice to keep local secrets in `.env` is not restricted by this policy, but the project must never treat it as the configuration source of truth (see §15.2).

**Layered Configuration Pattern:** When a project needs to separate deployment configuration from public configuration, use a two-layer TOML approach with deep dict merge. Deployment configuration includes two categories of fields:

- **Secret fields**: sensitive values that must not appear in git-tracked files.
- **Environment fields**: configuration values that vary by deployment environment but are not themselves secret.

- **Base configuration** (`config.toml`, git-tracked, loaded by default at startup): Contains **all fields** and is the **single authoritative source** of the configuration schema. Non-deployment fields have production-grade defaults. Secret fields are left empty (`""`, `0`, `[]`, normalized to `None` at load time — see §2.2). Environment fields have **development defaults** (reasonable values usable locally) rather than being left empty — this ensures the project runs out of the box in a development environment.
- **Override configuration** (recommended location: `.local/config.override.toml`, gitignored, deployment machine only): Overrides only the fields that need deployment-specific values. Copy from the git-tracked `config.override.sample.toml` template and fill in real values. **Must not add fields that do not exist in the base configuration** — the override "fills holes", it does not "dig new ones". By default the template lists only the common fields that need overriding; when the total number of config fields is small, the template may directly mirror all fields for easier comparison.
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

**1. No useless parameters.** If a value can be derived automatically, don't make the user specify it. A parameter that is uniquely determined by other parameters should not exist — every extra parameter is one more opportunity for user error. `decay_steps` is the decay span of the schedule (the semantics the user genuinely cares about); don't make them derive it from training length. `num_layers` is known once the config file is loaded, so don't ask the user to fill it in manually. The principle: **the user should only specify what they genuinely care about and what the system cannot decide for them.**

**2. Orthogonal parameters.** Parameters should be independent of each other — adjusting one should not change the semantics of another. If changing `warmup_steps` requires also changing `total_steps` for the scheduler to work correctly, the two parameters are coupled and the design is flawed. Orthogonal configuration lets users independently optimize each dimension without maintaining a mental "parameter linkage table."

**Litmus test:** Can the user independently adjust each parameter and get a predictable result? If changing parameter A requires also changing parameter B, they are not orthogonal — they should be merged into one parameter, or one of them should be auto-derived.

**3. Self-explanatory names.** Parameter names can be long, but must communicate their meaning at a glance — no documentation lookup required. `learning_rate` is better than `lr`. `warmup_steps` is better than `ws`. `min_lr_ratio` is better than `min_lr` (the latter reads as an absolute LR value, not a ratio). Abbreviations are acceptable in only one case: the abbreviation is a domain term that **everyone knows**, such as `lr`, `tp`, `pp`, `lora`. Even then, prefer full names as top-level config keys — `learning_rate` is less ambiguous than `lr`.

**Litmus test:** Show only the parameter name and comment to someone unfamiliar with the project. Can they accurately state what the parameter does? If they get the function right but the unit or range wrong, the name is good but the comment is insufficient. If they get the function wrong, the name itself is ambiguous. Beyond that: when you change this parameter, does the system behavior actually change as intended? If nothing changes, it was never wired into the code — a phantom config, not a parameter design problem.

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
├── configs/                 # Example configs (required for long-running services; batch/training tasks may omit — place example configs in samples/configs/)
├── docs/                    # User-facing documentation: how to use it, the architecture, whether it works well (§17.2); includes the capability and usable-tier matrix (§17.7)
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

**`configs/` directory**: Projects that need runtime configuration for long-running services should use `configs/`; projects that obtain configuration via CLI arguments may omit the root-level `configs/`, and placing example configs under `samples/configs/` is sufficient. **The mechanical validation of the directory structure is carried by `tools/check_directory_layout.sh`** (this project is judged by the same template, and `--class` differences are likewise defined by it).

**Directory organization principle:** The directory structure is a navigation system for the codebase, not a filing cabinet. From directory hierarchy and file names alone, a reader should roughly understand what the code does, which module it belongs to, and its inheritance relationships — without opening any files. A directory should not contain more than 10 code files. When it does, the directory contains multiple sub-domains that can be independently named — create categorized sub-directories and group files by functional domain. This is not a hard limit, but a signal: when you see the 11th file, ask yourself "can this directory's responsibility still be described in a single sentence?"

> The directory layout template shows both `README.md` and `README.zh-CN.md`. For projects exempt under §17.6, a single `README.md` is sufficient.

> `__main__.py` in the directory tree above may likewise be omitted as needed: when a Category B project uses Docker as its unified deployment method and already has another entry point (`run.sh`, see §4.1, or `cli.py`), it is not required to provide `__main__.py`. This is where the Category B definition in Layer 0 — "Docker-deployed projects may be exempt from `__main__.py`" — lands.

**`cli.py` may be upgraded to a `cli/` directory:** When the CLI logic is complex enough to warrant splitting into multiple sub-modules (e.g. subcommand dispatch, training worker process entry point), follow the same logic as §8.3 (Class-to-Directory) — `cli/__init__.py` is responsible for external transparency, so external consumers only see the `package_name.cli:main` entry point and are unaware whether the internals are a single file or a directory.

**`domain/` may be omitted as needed:** Not every project has an independent domain logic layer. If the project's domain logic naturally coheres within `core/` computation modules, or if the domain concepts themselves are not yet stable enough to justify a separate layer, leaving it empty is better than forcing it in. The core principle of module boundaries (§1.1) is to describe responsibilities in a single sentence — if you cannot describe what `domain/` is responsible for, it should not exist.

### 8.2 File Granularity: Neither Too Large Nor Too Fragmented

A file of thousands of lines is hard to read and modify, and even slow for the IDE to open. But split too finely, and a single feature is scattered across a dozen files — the reader jumps around, their thinking fractured. The ideal granularity: **one file corresponds to one clear conceptual unit.** The reader should be able to fully understand that concept by opening that file.

Litmus test: Can you fully understand a concept in one file? If you need to jump between multiple files to piece together the full picture, it's too fragmented. **Aim to keep files under 1000 lines** — if a file exceeds that, ask yourself: is it cramming in two concepts? However, if the logic genuinely belongs to a single conceptual unit (e.g., a pure-function toolkit, a complex model adapter), exceeding 1000 lines is acceptable; in that case, ensure the file is internally organized by functional domain with clear separators and comments so readers can quickly navigate.

### 8.3 Class-to-Directory: When a Class Is Too Large

When a class has so many methods that a single file bloats to hundreds or even thousands of lines, don't force the methods into one file. Upgrade the class to a directory:

```
backends/models/my_model/
├── __init__.py          # Re-exports MyModelAdapter from adapter.py
├── adapter.py           # Main class definition + template method skeleton
├── forward.py           # Forward-pass methods
├── generation.py        # Generation-related methods
├── checkpoint.py        # Save/load-related methods
└── helpers.py           # Pure utility functions
```

**Principle:** `adapter.py` keeps the class skeleton — `__init__`, template methods, abstract methods. Each file split out by functional domain contains a group of related methods of that class. External consumers only import the class name, completely unaware whether the internals are a single file or a directory. `__init__.py` is responsible for this "external transparency."

Internal methods that need shared state access it through `self` — they remain methods of the same class, just physically distributed across files. Pure functions that don't need `self` state go into `helpers.py` — they are independent and individually testable.

File names inside a class directory need not match class names — the directory name carries the locality of the domain (the class name stem), and inner files are named by functional domain (§12.2 class-path mirroring).

### 8.4 OOP and FP: Each Has Its Place

Object-oriented and functional programming have debated for decades which is better. The answer is: **they are not rivals — they are tools.** The key is letting each do what it's best at.

**OOP excels at:** stateful scenarios, scenarios with a lifecycle, scenarios with multiple implementations needing a unified interface. Class inheritance expresses "same kind of thing, different implementations". Template methods let the base class control the flow while subclasses fill in the differences.

**FP excels at:** stateless, pure computation, data transformation scenarios. Functions receive input, return output, no side effects.

**Don't OOP for OOP's sake:** if a piece of logic doesn't need `self` state, don't force it into a class. A standalone pure function is clearer, easier to test, and easier to reuse than a class with a single method.

**Mixing styles within a module requires nuanced grading:**

The following mixing is **benign** (Type A) and does not need splitting:
- A file defines frozen dataclasses that serve only as function return types, alongside pure functions that operate on those dataclasses — they are naturally cohesive.
- A file is primarily a pure-function toolkit, and the "classes" within it are essentially small data structures (typed tuples, frozen containers), not stateful service objects — they are naturally cohesive.
- Multiple sibling classes share the same file — they share the same responsibility, and keeping them together is reasonable.

The following mixing **needs splitting** (Type B):
- A stateful, lifecycle-bearing service class sits alongside unrelated standalone functions — they should be extracted into a helpers module.
- Complex state-management classes mixed with pure computation functions, making it impossible for the reader to tell at a glance the scope of a function's side effects.

**Litmus test:** Can the reader tell at a glance whether the functions in this file have side effects? If seeing a class in the file leaves them unsure whether a function depends on the class's state — that's Type B, and it needs splitting.

### 8.5 Output Directory Isolation

This section applies to runs that produce on-disk output. Source code and data are assets; run output is a consumable. The two must be physically separated — the output directory is not inside the source tree, and is specified by the `output` field in the config file. The default points to `outputs/` under the project root, and this directory is excluded in `.gitignore`.

```
outputs/<run_name>/
├── config.toml           # Config backup for this run (output description, §10.1; for reproduction see §6)
├── checkpoints/          # Model checkpoints
├── logs/                 # Logs, split into files by functional domain
└── results/              # Final outputs (datasets, models, evaluation results)
```

Each run automatically generates a unique `run_name` (default: timestamp-based), preventing accidental overwrites. After the run completes, the user can reproduce this run from the config backup under `outputs/` according to the effect defined in §6 — no need to hunt down the original config file. The backup uses the same format as the project config (for a TOML project, `config.toml`).

### 8.6 Imports and File Headers

Always use absolute imports — relative imports are forbidden. `from __future__ import annotations` (PEP 563) is used only when circular imports prevent type annotations from being evaluated, not required in every file. In Python 3.11+ projects, `str | None` syntax is natively supported, and `TYPE_CHECKING` guards already handle most circular import scenarios — there is no need to add boilerplate to every file. `__init__.py` is responsible for re-exporting the public API so external consumers don't need to know the internal file structure.

### 8.7 Version Number: Single Source of Truth

The project's version number is **automatically derived from git tags via `setuptools-scm`**. `pyproject.toml` declares `dynamic = ["version"]`. This is a stronger embodiment of Constitution §1.4 (Single Source of Truth) and §2.1 (Foolproof Design):

- `pyproject.toml`'s `[tool.setuptools_scm]` section configures version derivation rules (tag format, prefix, etc.) — this is the **single configuration source** for the versioning mechanism
- The actual version string does not live in any file — it is derived from `git describe --tags`. To release: `git tag vX.Y.Z`
- **Forbidden:** defining `__version__` in `__init__.py` — that would in fact create two sources of truth
- **Forbidden:** writing version numbers in config comments (`config.toml`, `config.override.sample.toml`) — config files are for users, not version records
- **Forbidden:** hardcoding version strings in source code

At runtime, obtain the version through the standard-library metadata interface; users can check the version via a git tag or the package manager.

**Why not use `pyproject.toml`'s `version` field?** Because `pyproject.toml` carries two entirely unrelated pieces of information: the version number and the dependency declarations. If the version number were hardcoded in `pyproject.toml`, changing the version number during a Docker build would change the file's hash, invalidating the dependency layer cache and forcing a full re-download of all packages. `setuptools-scm` + `dynamic = ["version"]` decouples the version number from the file into git tags — `pyproject.toml` contains no version string, so a version change does not change the file's hash, and `pyproject.toml` can safely go into the dependency layer without triggering a dependency rebuild. A version change then only affects the source layer (`COPY src`), while the dependency layer cache is fully reused. This is §1.4 (Single Source of Truth) and §14.3 (Docker layer caching) working in concert.

**Litmus test:** How many files need to change for a release? If more than 0, this clause is violated.

**Forbidden** to embed constitution version references in source code files. The constitution version number is maintained only in the constitution repository itself, so that it is likewise a single source of truth alongside the project version number. **The exact literal patterns are defined by `tools/check_constitution_refs.sh`** (the hardcoded-version check for this project is carried by `tools/check_version.sh`).
  `tools/check_constitution_refs.sh` and `tools/check_version.sh` are part of the constitution's own content, not project code.

---

## IX. Data and Interfaces

### 9.1 Data Models: Pydantic

All core data structures use pydantic `BaseModel`. Passing bare `dict` or `list` for business data is forbidden. `extra = "forbid"` rejects unknown fields. Nested structures use nested pydantic models — no dict of dicts.

**Model purity:** Data models follow the same one-thing-one-responsibility principle as module boundaries (§1.1). A model should contain only data that belongs to its conceptual domain. When you need to attach unrelated metadata, don't add fields to the existing model — create a new model and use composition (nesting) instead of pollution.

`frozen = True` is recommended for pure data objects loaded from external data sources that are never modified afterward — it prevents accidental mutation. But for scenarios such as configuration objects that need to be overridden by CLI arguments during initialization, `frozen` is not required; in that case, ensure the config object is not modified after initialization completes.

### 9.2 Class Inheritance: ABC Template Method

When there are multiple implementations, an ABC base class defines the process skeleton (public methods), with each step calling a `_`-prefixed private hook. Concrete subclasses only override hooks, never public methods. The base class provides default hook implementations, minimizing subclass boilerplate. To extend with a new implementation, define a new class and register it — no existing code changes.

### 9.3 Registry: Dynamic Extension

Multiple implementations of the same type are managed through a registry (string-to-class mapping). Look up by name at runtime and instantiate. On lookup failure, give a clear error message listing all available options. Adding a new implementation requires only one line of registration code.

---

## X. CLI Design

### 10.1 Config-Driven Commands

**Principle: the config file is the sole description of run output.** Run output includes everything written to disk, as well as content sent to external systems; the on-disk location is part of the output (output_dir and run_name are both config-driven). The only exception: content printed directly to stdout without touching disk is not output.

**Reproduction definition:** Reproduction means **the effect defined by the requirement is achieved again** (§6) — there is no fixed threshold, and the meaning of consistency is determined by the requirement. **Parameter placement does not depend on whether reproduction is needed**: it is decided by the principles of this section, together with §1.4 (Single Source of Truth) and §7.1 (single configuration entry point) — every parameter that participates in deciding on-disk output must live in the config file; reproduction (§6) is the means of verifying that placement. Whether the config.toml backed up in the output directory (§8.5) alone can make the effect of this run achieved again in a second run is the criterion of that verification.

**Corollary 1: every parameter that participates in deciding output must live in the config file.** Otherwise the same config would change the effect defined by the requirement (§6) under different CLI parameters — the one-to-one mapping between config and output breaks, and the §8.5 promise of reproduction from the config archived in the output directory fails.

**Corollary 2: CLI flags and config fields have zero intersection.** A parameter can have only one source of truth (§1.4). A mechanism where "the config holds a value and the CLI overrides it" is forbidden — override means two sources of truth. Adding a new command is acceptable when it represents a fundamentally different lifecycle operation (training vs. exporting) that cannot be naturally expressed as a config toggle, but the command itself is subject to this section.

**CLI parameters follow three principles (applies to every CLI command):**
1. **Input-locating parameters**: designate input files or data — locating input, not configuration content. The most typical example is `--config`; whether the remaining parameter names belong to this category must be judged by project semantics;
2. **Runtime-environment parameters**: never written to disk, never part of output, only affect "where it runs";
3. **Run-boundary parameters**: do not produce a complete run output (e.g. smoke verification — equivalent to a restricted run, without changing run semantics).

**`--config` is the only explicitly named parameter** — other parameter names vary by project and must be reviewed one by one against the three principles above: under reproduction conditions (the same config; the same seed if the task involves randomness), does a different value of this parameter change the effect defined by the requirement (§6)? If yes, it must move into config.

**Judgment criteria (technique):** for any parameter X — under reproduction conditions (the same config; the same seed if the task involves randomness), if different values of X change the effect defined by the requirement (§6), or change the existence, location, or controllable content of any on-disk output, then X must go into config. (This criterion is independent of whether §6 reproduction is needed: participating in deciding output is enough to be constrained.)

**Output constraint (technique):** every CLI command's on-disk output is decided by the config — "output-locating" parameters are forbidden. Tool commands that do not participate in output are equally constrained, with three options only: print without writing to disk; accept `--config` and write into a config-decided directory; or demote to a scripts/ script (§10.2).

**Foolproofing (technique):**
- The CLI parameter list is enumerated once in code and locked by tests — a new CLI flag must pass a "does not change the effect" test (run twice with the same config, only X differs, assert that the output is unaffected according to the effect defined in §6: for deterministic tasks compare value by value directly; for tasks involving randomness fix the seed, or compare only the parts unaffected by randomness)
- Log and record files must not contain runtime-environment metadata — they are not decided by config, are not part of the effect defined by the requirement, and belong to §16.2 environment information
- Except for the §7.1 third-party adapter cases, custom environment variables must not carry configuration or path parameters; standard CUDA/NCCL/PyTorch infrastructure variables are unaffected; host-path injection goes through CLI flags (e.g. run.sh `--model-dir`)
- `run.sh` (§4.1) CLI parameters are equally subject to the three principles of this clause — it is a config launcher, not a config substitute

### 10.2 CLI vs. Scripts Boundary

**CLI is the stable user-facing interface. Scripts are temporary developer-oriented tools.** CLI parameters and output formats are contracts — don't change them casually. Scripts are one-off, experimental, deletable at any time, with no backward compatibility obligations.

**Institutionalization criteria:** a script becomes an institutionalized interface the moment any of these holds — it must then be promoted to a CLI subcommand or deleted:
- It is locked in by tests (a corresponding test exists in tests/)
- It is referenced by the README or docs/
- It is used repeatedly by workflows, beyond the developer's own use

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

For complex algorithms whose generalization completeness is extremely difficult to exhaustively establish through formal analysis, test-data-driven development is an effective alternative path.

**Principle:** Use continuously enriched test scenarios as empirical anchor points for the algorithm, in place of formal completeness proofs. The richer the test scenarios, the higher the marginal cost of "cheating" through hardcoded branches, and the algorithm is forced toward genuine logical generalization. However, this is not "add an if for each new case" — each batch of new test scenarios should be followed by an abstraction refactor, so the algorithm covers more scenarios with simpler logic, rather than stacking patches on a branching tree.

**Rule:** Cheating and hardcoding to adapt to test data is forbidden. Specifically: do not add hardcoded branches in the algorithm targeting specific test inputs; do not relax assertions in tests to "pass" them; when a new test scenario fails, cover it by refactoring the algorithm's logic, not by appending conditional branches to existing logic.

**Technique:** Start from a small set of typical scenarios, progressively expand to boundary and exception scenarios, and after each iteration, examine whether the algorithm's logic has become simpler rather than more complex. If the algorithm's line count grows linearly with the number of test scenarios, cheating or patch accumulation is at work — re-abstract. The sign of convergence: new test scenarios pass without modifying the algorithm's logic.

**The legitimate standing of negative-sample fixtures:** The detection capability of the security and compliance checks (§15) itself also needs to be tested. Synthetic fixtures (negative samples) used to prove that a rule **really fails** are part of the detection capability, not noise to be cleaned up — **fixtures must not be deleted just to make things green**, nor may assertions be relaxed to make a scan pass (see "Rule" in this clause). Such fixtures must use the **acceptable forms** defined in §15.1 item 1 (the same holds under Category A, see that item's "Category A has no named exemption channel"); a conforming form does not constitute a hit and needs no exemption list. **Fixtures must not use real credentials, real personal information, or internal addresses** — even "just for testing". **The fixture list, and each fixture's intent and criterion, are carried by the test file's own comments and naming** (§1.6: code is the first document); no separate fixture documentation is created.

### 11.5 Acceptance Is User-Facing Acceptance

**The purpose of acceptance is to answer "what can users use, how does it perform (VRAM, speed), and how many tiers really work."** Therefore **acceptance-facing artifacts are naturally user-facing artifacts — the two are aligned, not two different kinds of thing**. This is what "acceptance is user-facing acceptance" means.

**Corollary (the only mandatory content of this clause):** When the object of acceptance is **user-facing capability, tiers, effect, or performance**, the acceptance output is **not merely an acceptance record** — the same machine-readable data must **simultaneously** support the capability and usable-tier matrix in `docs/` (§17.2, §17.7). That one matrix document carries two responsibilities: **① the acceptance record; ② the user-facing statement of capability and tiers**. **"Killing two birds with one stone" is a design goal, not a by-product**: one of the marks that such acceptance is complete is that users can already answer "how many tiers are usable, how do they perform, and where are the boundaries".

**The division between what is committed and what is not (two clauses; do not merge):**

- **What is committed = the usability and performance baseline under platform-side datasets and platform-side parameters** — **① it can run through to completion**; **② the effect meets the standard under platform-side datasets and platform-side parameters**; **③ VRAM usage and speed are within the committed range**. All three are **objects of acceptance**, and acceptance must give a conclusion on them.
- **What is not committed = how it will turn out under users' own tasks, datasets, and hyperparameters.** The matrix may and should **record** the baseline effect values observed on the platform-side dataset (together with their basis, and marked "for reference only"), but **makes no effect commitment to users on that basis**. **The effect depends on users' own tasks, datasets, and parameters and is not within the commitment scope of acceptance** (§17.7).

**The applicability boundary of this clause (to prevent padding documents):** What this clause requires is that "**the conclusions and evidence of acceptance must be captured where users can access them**", **not** that "every acceptance must add or produce a document". The form of the output is decided by the nature of the acceptance object:

- When the acceptance object **has user-facing explanatory value** (capability, tiers, parameters, performance, **and whether it meets the standard on the platform-side dataset and criteria**) → the conclusions and evidence are captured into the matrix in `docs/` (generated data-first, see §17.7).
- When the acceptance object **has no user-facing explanatory value**, this clause **requires no document to be produced**; the conclusions land in the same run's acceptance record and git commit record (§17.4), and a document **must not** be fabricated to satisfy this clause — that is exactly the "documentation that duplicates the code and therefore inevitably goes stale" that §1.6 opposes.
- The judgment needs to answer only one sentence: **Among this acceptance's conclusions, which one is something users have a right to know and that currently has nowhere to be found?** If you cannot answer, do not produce a document.
---

## XII. Code Style

### 12.1 Type Annotations

**Principle:** Type annotations are not decoration — they are contracts. Every function signature is a type contract — callers can understand input and output types without reading the implementation. When you change a type, mypy forces you to review every affected file — this is not a maintenance burden, it is the foolproofing device (§2.1) embodied at the type level.

**Rules:**

1. **Every function must have complete parameter and return type annotations.** This includes public methods, private methods (`_` prefix), and utility functions. Only the following are exempt:
   - `__init__` methods may omit the return annotation (`-> None` is the Python convention and can be omitted)
   - Abstract methods may annotate the return as `None` or omit it (subclasses may return different content)
   - Functions in one-off debugging scripts

2. **Class attributes must be annotated at the declaration site.** Instance attributes first assigned in `__init__` should use PEP 526 annotation syntax:
   ```python
   self.running_models: dict[str, InferenceFramework] = {}
   ```

3. **Optional types must uniformly use the `X | None` syntax (PEP 604).** Use `str | None` rather than `Optional[str]`. `| None` is the native syntax since Python 3.10, the standard form of PEP 604, and the recommended form against the backdrop of Python 3.14+ lazy annotation evaluation (PEP 649/749); `Optional` remains valid but is not the project convention, to avoid introducing further `typing` imports and `from __future__` boilerplate.

4. **Replace complex nested types with classes.** Anonymous nested types like `dict[str, list[tuple[int, float]]]` should not exist — replace them with pydantic BaseModel or dataclass. Classes have field names and docstrings; when you need to change something, you only change the class definition, and all references stay in sync automatically. Friendly to both humans and AI.
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

6. **mypy type checking** is already required by §11.1; the `[tool.mypy]` section must be configured in `pyproject.toml` (see §20 skeleton). Type annotations + mypy together form a complete foolproofing device — neither is sufficient alone.

7. `from __future__ import annotations` should only be used when circular imports prevent type annotation evaluation (see §8.6).

**Litmus test:** Open any function — can you accurately state the type of every parameter and the return type just from the signature? If not, the annotations are incomplete. Are there any anonymous nested types (e.g., `dict[str, list[tuple[...]]]`)? If so, they should be replaced with classes.

### 12.2 Naming

Classes PascalCase, functions and variables snake_case, private members `_`-prefixed, constants UPPER_SNAKE_CASE, type aliases PascalCase, module files snake_case.

**Naming as documentation:** File names are the first line of documentation for a codebase. From directory hierarchy and file names alone, a reader should be able to infer the file's purpose, its owning module, and its inheritance relationships. File names are not labels for yourself — they are navigation signals for future readers (including AI agents). When a file must be renamed for a new reader to understand its responsibility, the original naming was a failure.

A class name should decompose into path components — the class name's CamelCase words correspond in order to package name → directory name → filename (snake_case), one word per level. **The exact validation is implemented by `tools/check_class_file_naming.sh`** (§15.1 first-paragraph division of labor). **The exempt categories** (files inside a class directory, mixin classes, same-family multi-class files, data containers, test helper classes) are kept as-is; the named instances in parentheses are deleted.

**Why constrain classes but not functions?** Functions get their domain context from the file that contains them — the responsibility for locality lies with the file. Classes are self-locating units referenced across files, and a class may be upgraded into a directory (§8.3) — a class name must carry its own locality information.

**Litmus test:** Given a class name, can you say where it should live without reading the code? Given a path, can you say which class families it should contain? Naming passes only if both directions answer yes.

### 12.3 Language Convention

**Except as exempted by §17.6**, `README.md` and `README.zh-CN.md` are bilingual — the project's front door is accessible to both the English and Chinese developer communities, the two most active language groups in open source.

All other files — comments, docstrings, architecture documentation, config annotations — use **either Chinese or English, at the author's discretion**. No other languages are permitted. Keep language broadly consistent within a file; a small amount of technical terms, code references, or structural separators may remain in English.

**This constitution's own two language versions are not subject to this clause's "either one" rule** — the Chinese version is the sole source of truth and the English version is a full translation of the Chinese version, see §17.8.

**Config comments** (base `config.toml` and override template `config.override.sample.toml`) default to **English** — they are a user-facing interface, and English is the common language of the global developer community.

**Commit messages** use English (see 19.1).

Technical terms, algorithm names, framework names, and academic concepts are kept in their original English form — their original English is the shared language of engineers in the field; forcing translation loses information density instead. The principle is: **accuracy first — do not sacrifice technical expression for language purity.**

Comments explain **why**, not **what**. No useless comments.

### 12.4 File Header Comments: Responsibility Declarations

Every source file must open with a comment declaring the file's function and scope of responsibility, in one sentence. This is a boundary declaration for AI (and for humans) — when AI wants to stuff unrelated methods or classes into a file, the file header is the first line of defense (foolproof design, §2). If the responsibility cannot be stated in one sentence → the file should be split (§1.1).

- The header may be a module docstring or a comment block; language follows §12.3
- `__init__.py` is exempt — its responsibility is re-exporting the public API (§8.6), no need to declare it again
- A responsibility declaration is navigation and foolproofing information, not the "useless comment" §12.3 prohibits — it answers "why does this file exist, and what content belongs in it"

**Litmus test:** Can the file header's responsibility declaration answer in one sentence "should this piece of code go into this file"? If not, either the comment isn't clear, or the file boundary has already been breached.

---

## XIII. Error Handling and Logging

### 13.1 Exceptions: Never Swallow

**Absolutely forbidden:** `except Exception: pass` or bare `except: pass`. Every `except` block must contain explicit handling logic (retry, degrade, or convert to user-readable information and exit). In principle, exceptions are handled uniformly at boundary layers and exposed as early as possible in internal layers.

### 13.2 Log Levels

DEBUG for developers debugging, INFO for users tracking progress, WARNING for users evaluating run quality, ERROR for telling users why something failed.

**Every project must provide at least one standard Python `logging` channel** using these four levels. This ensures compatibility with log aggregation tools, CI pipelines, and debugging workflows. Beyond this required channel, projects may add domain-specific log files (structured JSONL for metrics, timing event logs, raw rollout records, etc.) — these are system-specific extensions and are not constrained to the four-level scheme.

### 13.3 Log Files by Module Boundary

Log file granularity mirrors module boundaries (§1.1): **independent modules each get their own log files; tightly-coupled pipeline steps share a single log file.** Each independent log domain is split into **readable logs** (human-readable, INFO level) and **raw logs** (machine-parseable, DEBUG full detail). ERROR-level logs are aggregated into a common error log file. All log files live under a `logs/` subdirectory of the output directory (see 8.5 Output Directory Isolation).

The specific filenames and module splits are defined by each project according to its own architecture.

**Core principle: splitting is meant to prevent investigators from having to open irrelevant modules' logs at the same time, but it must not force investigators to stitch together a timeline across files when tracing a single causal chain.** Structured domain-specific logs (e.g., JSONL rollout records, timing event logs) are system-specific extensions (see 13.2) and are not constrained by this rule — they serve machine analysis, not human investigation.

**Litmus test:** When investigating an event, how many log files do you need to open and correlate timelines across? If you keep jumping back and forth, the split is too fine — merge.

### 13.4 Debugging: Simplicity is Reliability

**Principle:** The complexity of your debugging tools must not exceed the complexity of the system being debugged. For the general methodology (simple first, assess before acting), see the Preamble "Execution-First Principle". Debugging tools are themselves code, and they can have bugs too. When a complex logging framework, distributed tracing system, or async sampler becomes part of the problem, fall back to the simplest reliable tool.

**Technique:** `print()` + stdout redirection is the last and most reliable fallback. This is not a step backward — it is the fallback design principle (§3.1) applied to debugging: degrade to a simpler but more reliable approach to ensure that debugging information is never lost.

**Litmus test:** How long does it take to set up your debugging environment? If the debugging environment itself is more complex than the bug you're trying to fix, your debugging tooling is the problem.

---

## XIV. Dependencies and Deployment

### 14.1 License Constraints

All dependency packages must be under **permissive licenses suitable for commercial use**; **viral (copyleft) licenses** are forbidden. Check license compatibility before introducing a new dependency. **The exact license list and the FAIL/WARN dividing line are defined by the judgment logic and runtime output of `tools/check_dependencies.sh`** (§15.1 first-paragraph division of labor) — the license categories are defined by this clause, and the concrete determination is not carried by a second document.

### 14.2 Dependency Management: uv

All projects use `uv` as the sole package manager. `.python-version` pins the Python version. `pyproject.toml` declares dependency constraints (package name + version bounds). `uv.lock` is **generated from** `pyproject.toml` via `uv lock` and records the fully resolved dependency graph with exact versions and content hashes. Together they form the single source of truth for all dependencies — there is no other dependency specification. Both files are committed to git. `uv sync` sets up the development environment in one command.

**Never edit `uv.lock` by hand.** It is a generated artifact. The dependency change workflow is: `pyproject.toml` → `uv lock` → `uv.lock`. `pyproject.toml` + `uv.lock` form the single source of truth for dependencies — **there is no other dependency specification**; **the specific forbidden dependency-specification file names are defined by `tools/check_dependencies.sh`.**

### 14.3 Docker Required

Every project must support Docker deployment. Base image is pinned to a specific version tag (never `latest`; a tag can be overwritten — use a digest when strong determinism is required). Dockerfile uses two-layer build (dependencies layer + source layer), exploiting layer caching. Dependencies are installed via `uv sync` or `uv pip install` with `uv.lock` to guarantee the same versions inside the container as in the development environment. `build.sh` encapsulates the build command.

**Docker layer cache design:** The dependency layer copies both `uv.lock` and `pyproject.toml`. The version number is derived by `setuptools-scm` from git tags (§8.7), and `pyproject.toml` uses `dynamic = ["version"]` (no version string in the file), so a version change does not change `pyproject.toml`'s file hash. The dependency layer is only rebuilt when `uv.lock` or `pyproject.toml` actually changes — routine version releases and code changes never trigger a dependency layer rebuild.

All dependency-install commands use a BuildKit cache mount so that packages are read from the local cache instead of over the network (the concrete mount target is defined by `tools/check_dockerfile.sh`).

`build.sh` obtains the version number from a git tag and injects it at build time, for use by build environments without `.git`, while keeping the version number single-sourced (the mechanism is verified by `tools/check_docker_version.sh`).

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
# COPY configs ./configs    # keep only when the project has a root-level configs/; batch/training task example configs live in samples/configs/, see §8.1
# COPY data ./data          # keep only when the project has a data directory distributed with the image; data/ is in .gitignore by default (§19.2)

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

**Proxy and build-time parameters must not pollute the runtime:** When a proxy is needed during builds to access external networks (e.g. `HTTP_PROXY`, `HTTPS_PROXY`), proxy environment variables **MUST NOT** be written into the Dockerfile's `ENV` instruction, and the final image must contain no residual proxy configuration. Internal proxy addresses also constitute secret information as defined in §15.1 — writing them into a Dockerfile is equivalent to permanently embedding internal addresses in git history. **How a value is passed is chosen per the "Value-Passing Rules" table below and is not restated here; for where `ENV` and `ARG` values each end up, see "The two kinds of metadata for build-time parameters" below.** Contamination of the runtime must be avoided entirely: **proxy-class variables MUST NOT be passed via `ENV`**; see "Proxies Must Not Pollute the Runtime" below for the complete constraints.


**Correct pattern 1 (recommended) — secret scenario: Category A / public repositories, or any credential-bearing proxy, go through secret.**

In the Dockerfile, each `RUN` that needs the proxy mounts it separately (a secret is visible only inside the `RUN` that mounts it):
```dockerfile
RUN --mount=type=secret,id=proxy,env=HTTP_PROXY \
    --mount=type=secret,id=proxy,env=HTTPS_PROXY \
    --mount=type=secret,id=proxy,env=NO_PROXY \
    --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev
```

In build.sh (the proxy value lives in a gitignored file — it enters neither git nor the image):
```bash
docker build \
    --secret id=proxy,src="${PROXY_FILE}" \
    -t "${IMAGE_NAME}" -f docker/Dockerfile .
```

**Correct pattern 2 (usable) — non-secret scenario: Category B / private Category C, addresses that are only internally reachable and carry no credentials, may use `--build-arg`.**

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
> Usable only when these addresses contain **no credentials** and are not pushed to a public repository. It does **not** pollute the runtime environment (`ARG` does not enter `Config.Env`), but it does appear in `docker history` (see below) — and it **must never** be switched to passing the value via `ENV`.

This rule applies to all configuration that is only needed at build time and must not persist at runtime — proxy settings are the most typical case, but it also covers private pip mirror URLs, build cache configuration, and similar. Litmus test: is this configuration still needed when the container runs? If not, it must not appear in the final image.

**The two kinds of metadata for build-time parameters: configuration metadata and build history metadata.** "`ARG` does not enter the image" is an incomplete statement — what it does not enter is **configuration metadata**; what it does enter is **build history metadata**. To judge whether a value pollutes the runtime environment or leaks, the two locations must be assessed separately:

- **Configuration metadata** (`docker inspect`'s `Config.Env`/`CMD`/`LABEL`, the image configuration exported by `docker save`): `ENV` values enter it, and the running container inherits them; `ARG` / `--build-arg` values do **not enter** it — which is why passing a proxy via `ARG` does not pollute the runtime environment.
- **Build history metadata** (`docker history`, the image's layer records): the **literal values** of `ARG` / `--build-arg` do enter. BuildKit writes them into the history as a standalone `ARG NAME=VALUE` entry and as a `RUN |N NAME=VALUE /bin/sh -c …` prefix, **even if the parameter is never referenced by any instruction**; `docker inspect` cannot see these values, but `docker history --no-trunc` shows them plainly. (The index `N` is determined by the build process and is not necessarily 1. In addition, BuildKit emits a `SecretsUsedInArgOrEnv` warning when an ARG carries sensitive data.)

**Value-Passing Rules (graded by the kind of value and by project class, not decided by the single dimension of "build time vs. runtime"):**

| Kind of build-time value | Category A / any public repository | Category B / Category C that is not pushed to a public repository | Rationale |
|---|---|---|---|
| **Credential kind** (§15.1): keys, passwords, tokens, private keys, private source URLs with credentials or signatures | **MUST** use a BuildKit secret: `--mount=type=secret,id=<id>,env=<VAR>` | **MUST** use a BuildKit secret (no relaxation) | A secret's value enters neither configuration metadata nor build history metadata; credentials are not eligible for any graded exception (§15.4) |
| **Credential-free internal addresses**: internal proxy addresses, internal mirror addresses, internal domain names / IPs | Counts as secret under §15.1, **MUST** use a BuildKit secret or switch to a public source; `--build-arg` is **forbidden** | `ARG` + `--build-arg` is allowed (the value enters `docker history`); the value is internal topology information, and the **push scope is the confidentiality boundary** (§15.4) | Images for Category A and public repositories may become public, so internal addresses must not enter an uncontrolled scope; B/C is not published publicly by default, so the risk is bounded by the push scope |
| **Non-secret**: version numbers, build switches, public source addresses | `ARG` + `--build-arg` (existing rule retained) | `ARG` + `--build-arg` (existing rule retained) | The value being visible in history is beneficial: it makes the build process traceable (§1.4 Single Source of Truth) and reproducible (§6) |

> The relaxation for Category B and Category C is bounded by repository visibility: once a repository becomes public, it is treated as Category A (§15.4).

**The table above is authoritative for how values are passed. Confidentiality grading does not change the runtime non-contamination constraint — the two are separate matters** — grading governs only "how the value is passed", while runtime non-contamination governs only "the value must not remain in the runtime environment"; neither substitutes for the other. See "Proxies Must Not Pollute the Runtime" below for the complete constraints.

**When a controlled value is passed via `ARG` because of toolchain limits or a graded relaxation:** the image's **push scope** MUST be managed as the confidentiality boundary (push only to controlled registries, never to public repositories); "flattening/deleting layer history" **MUST NOT** be treated as a secrecy mechanism — it is only a cleanup measure, not secret protection. Writing a secret value into a Dockerfile's `ARG NAME=default` or `ENV` is **forbidden** — that enters git (§15.1).

**BuildKit / buildx notes:**
1. A clean `docker inspect` **does not** mean nothing leaked — `ARG` values are not in `Config.Env`, but they are in `docker history`. "It is not in `inspect`" **MUST NOT** be used to prove that a secret was not carried into the image.
2. A `--mount=type=secret` value enters neither configuration metadata nor build history; but a secret is **visible only inside the `RUN` that mounts it** — if several `RUN`s need the proxy, all of them must mount it. This is the common cause of "the build-time proxy stopped working" after switching to a secret.
3. `--no-cache` is only a cleanup measure; it does not change the fact that "the value was already generated during the build and may already have left traces in pushes, caches, or CI logs" (the same holds for flattening measures such as `--squash`; for the prohibitive statement see "When a controlled value is passed via `ARG` because of toolchain limits or a graded relaxation" above).
4. Whether `max`-mode provenance attestations and `--cache-to` cache metadata carry build parameters has **not been measured**; verify it yourself before relying on it, and **MUST NOT** be treated as a known conclusion.

**Proxies Must Not Pollute the Runtime (applies to every project that builds an image, not relaxed by project class):**

> **Scope (relation to Layer 0):** This clause is **not** a requirement to "provide a Docker deployment" — Category C does not apply §7–§20 by default (Layer 0), so a project that builds no image has nothing for this clause to govern; but **once** a Category C project does provide a Docker deployment, every constraint of this clause applies to it as well — environment contamination is a correctness problem of the image itself and has nothing to do with project class. The applicability precondition of the "Category B / Category C that is not pushed to a public repository" column in the Value-Passing Rules table above is likewise **that the project provides a Docker deployment**.

1. **Forbidden** to pass build-time variables (proxies, private mirror sources, registries, and the like, including uppercase and lowercase forms) via `ENV`; the equivalent form of `ARG X` followed by `ENV X=$X` is **likewise forbidden**. They write the value into the container's runtime environment, and once the runtime depends on that variable an error occurs, while troubleshooting rarely locates it back to build time. **The exact variable-name list and the class grading are defined by `tools/check_dockerfile.sh`.**
2. **Forbidden** to write build-time configuration into **persistent** files inside the image (shell startup files, package-manager/build-tool configuration, git/container configuration, etc.). If a build-time tool must read the configuration, it may be generated **only within the same `RUN`** and must be deleted before that `RUN` ends — no residue across layers. **The exact path list is defined by `tools/check_dockerfile.sh`.**
3. Proxies take effect at **build time** only, and the passing method **MUST be chosen per the "Value-Passing Rules" table above**; no unconditional recommendation is given — the complete grading is in that table and in §15.4 and is not restated here.

**Acceptance (run after the build):** Confirm item by item that there is no build-time configuration residue in the configuration metadata, the login-shell environment, or the contents of persistent configuration files — **all three outputs must be empty**. **The concrete acceptance commands are chosen by the project and pinned in its build chain; `tools/check_dockerfile.sh` currently performs only static Dockerfile checks and does not cover runtime image acceptance — that runtime check is not yet implemented in the `tools/` scripts.**

The match patterns for the configuration metadata and the login-shell environment target **build-tool-class** variables (proxies, build-time mirror sources / registries), not runtime business variables; configuration of this kind is likewise build-time only and must not linger in the image's runtime environment.

The output for all three kinds of residue **must be empty** — any matching line (even if only one kind matches) means failure; there is no "only irrelevant entries" exemption. The login-shell environment kind cannot be omitted: a login shell reads shell startup files and injects the proxy variables from them into the process environment, which looking at configuration metadata alone cannot detect. The persistent-configuration-file-content kind checks file **content**: `ls` only proves that a file exists and cannot reveal the proxy inside it. **Category A / public repositories additionally require** confirmation that no internal address or credential literal value appears in the build history — that check serves **only** to confirm that no literal value is in the history; `ARG` carrying a secret is therefore not allowed, which is a separate matter from "not polluting the runtime environment" (the commands are chosen by the project; **the history literal scan of built images is not yet implemented in the `tools/` scripts**).

> For constraints on the source of code used during image builds, see §14.4 — regardless of where the image is built, the source code must come from a definite version on the development machine.

### 14.4 Code Sync: One-Way Flow

**Principle:** Code modifications happen in the development environment; the deployment environment only receives code. The flow of code from development machine to deployment machine is one-way — the dev machine is the source of modifications, the deployment machine is the destination. This is §1.4 (Single Source of Truth) extended to the deployment workflow: code content and modification behavior each have their own single authoritative source.

Editing code directly on a deployment machine is a breeding ground for engineering disasters — a fix is made and forgotten, then overwritten on the next deploy; two people edit the same file on the dev machine and the deployment machine, and when it's time to merge, no one can say which version is correct. Code on a deployment machine must be **traceable and reproducible** (here "reproducible" means traceable to a definite commit, which belongs to §1.4 Single Source of Truth and is not subject to §6's precondition of re-running), which means it must come from a definite version on the development machine, not from someone's impromptu edits in an SSH session on the deployment machine. The deployment machine may not have git access (network isolation, security policies, etc.) — this does not affect the principle: after committing on the dev machine, package the code (tar/zip) and scp it to the deployment machine, and it is still code from a definite version. The key is not the transport mechanism; the key is that code modifications happen only on the dev machine, and the deployment machine only receives code.

**Rule:**
- Code on a deployment machine **must** come from a definite version on the development machine. Direct editing of source files on deployment machines is forbidden. Preferred method: dev machine git commit → deployment machine git pull (when git is accessible from the deployment machine). Alternative method: dev machine git commit → package (tar/zip) → scp/rsync to deployment machine (when git is inaccessible from the deployment machine).
- The **only** allowed form of code modification on a deployment machine is: dev machine edit → dev machine git commit → sync to deployment machine (git pull or scp/rsync). Regardless of the transport method, the code version on the deployment machine must be traceable to a definite commit on the dev machine.
- "Manually sync back to the dev machine" after editing on a deployment machine is forbidden — this is not synchronization; it is dual sources of truth.
- Docker image builds are recommended to happen on the dev machine or CI environment (push image to registry, deployment machine pulls image). Building on the deployment machine from code synced from the dev machine is also acceptable, but building from manually modified code on the deployment machine is forbidden.

**Technique:**
- Set the project directory on deployment machines to read-only (for non-root users), physically preventing direct edits at the filesystem level — this is foolproof design (§2) applied to deployment.
- Deployment scripts (`deploy.sh` or CI pipeline) should start from obtaining a definite version of the code — either `git checkout <tag>` (when git is accessible from the deployment machine) or scp a packaged file of a specified commit from the dev machine (when git is inaccessible). Either way, the deployment script should record the version identifier (commit hash or tag) for this deployment.
- If temporary debugging is needed during deployment, reproduce the issue on the dev machine, modify the code, commit, and deploy the new version — never take the "edit on the deployment machine then sync back" path.
- If the deployment machine has git access, keeping the `.git` directory is recommended so you can verify via `git status` that the working tree is clean, and confirm the currently running version with `git log -1`. If the deployment machine cannot access git, the deployment script should record the version identifier in a `VERSION` file in the deployment directory.

**Litmus test:** Can the code on the deployment machine be traced to a definite version on the development machine (git commit or version marker in the packaged file)? Are there any source code modifications on the deployment machine that were not committed on the dev machine? If the first answer is "yes" and the second is "no," code sync is healthy.

---

# Layer 3: Security and Project Governance

## XV. Security and Secrets

Security is not a patch bolted on just before release. It is a design premise constraining every commit. The principle is simple: **if you don't want it on GitHub, it doesn't belong in any tracked file.**

### 15.1 Pre-Commit Verification

Every commit must pass the following checks. These checks should be integrated into CI or pre-commit hooks, executed by the companion `tools/` scripts, not left to human memory. The constitution defines the check categories — the scripts define the exact patterns.

> **A push publishes three things:** ① the content of tracked files; ② the entire git history (including deleted files); ③ commit metadata (author/committer names and emails) and commit messages. All three must be verified before pushing — scanning only the current working tree is not enough.

**1. Secrets scan:** No tracked file may contain any secret information. Secrets include:
- Keys, passwords, tokens, and private keys of any form
- Internal IP addresses, internal domain names, internal paths
- Any information you would not want on GitHub after open-sourcing

(For the graded exception for Category B and private Category C projects, see §15.4; credential-class information is not eligible for any exception.)

**Acceptable forms: synthetic values and reserved values.** The preceding sentence "credential-class information is not eligible for any exception" targets **real credentials**. If a value can be **mechanically determined** to be in a synthetic or reserved form, it does not belong to the credential class at the moment of determination and does not fall under this item's prohibition — such values appearing in documentation examples, templates, and test fixtures are legal, **with no exemption list required**. The exact match patterns are defined by `tools/check_secrets.sh` (see this section's first-paragraph division of labor).

**What is let through is the form, not the category.** This paragraph does not constitute an exemption for the information category "credentials"; it merely separates mechanically determinable synthetic/reserved values from real credentials. The following are **not accepted** under any circumstances and must be rewritten in form: credential strings bearing a real issuance prefix, random strings or passwords indistinguishable from real values, **internal addresses** (including internal domain names and internal paths), and real names/emails/phone numbers — these must be rewritten into documentation-example addresses or placeholder forms. The exact match patterns are defined by `tools/check_secrets.sh`.

**Category A has no named exemption channel.** The named-exemption-list mechanism for Category B and Category C projects not pushed to a public repository is **not loaded and does not take effect** under Category A or any project pushed to a public repository: Category A projects **must not** register false positives in any named list, nor let any hit through on the grounds that it is "already registered". The mechanism's syntax, scope of effect, and match patterns are defined by `tools/check_secrets.sh` together with its inline comments and `--help` (§15.1 first-paragraph division of labor), and no separate explanatory document is created. Category A test fixtures have only two compliant paths — use the **acceptable forms** above, or rewrite the fixture into an acceptable form (see §11.4).

**2. File-type check:** The following must not appear in tracked files:
- `.env` file (only `.env-example` may be committed)
- Build artifacts, caches, virtual environments
- IDE configuration files
- AI-assistant-generated local files (assistant-specific local instruction/draft files; must be excluded in `.gitignore`)
- Local and temporary files — all such files must live in `.local/` (see §16)

**3. Content review (human + AI assisted):**
- No training data, user data, or private datasets
- No internal resource references in README

**Definition of "training data":** the training data referred to in this item means specifically data that can be used to train a **model for a specific function** — private corpora, labeled sample sets, user behavior data, datasets used to train model weights, and the like; it does **not** include **public** seed data and Ontology data (public vocabularies, schemas, category tables, mapping tables, public corpus indexes, etc.) used to implement a feature. Test: can this data be obtained unconditionally from public channels, and does it not itself constitute a project-unique asset? If so, it is public seed data / Ontology data and is not subject to this item.

**4. Personal information (PII) scan:** No tracked file or git history may contain information that can locate a specific natural person, whether or not it falls under category 1 secrets:
- Personal email addresses; instant-messaging accounts such as QQ or WeChat; mobile and landline phone numbers
- National ID numbers, passport numbers, bank card numbers, student IDs, employee badge numbers
- A real name combined with other identity fields (anything that alone or in combination points to a specific person)
- **Exemptions (reserved domains, reserved number ranges, and placeholders):** public project mailboxes, example and reserved domains, explicit placeholders, pure filler number ranges, reserved fictional phone number ranges — the exact match patterns are defined by `tools/check_secrets.sh`.

**Per-form basis (test fixtures and documentation examples):** Four "accept / do not accept" **category criteria** are retained — (a) example email addresses: those using a reserved domain or a placeholder are **accepted**; an address under any real domain is **not accepted**; (b) example mobile numbers: pure fillers, placeholders, or reserved fictional number ranges are **accepted**; a number with any real country code plus a real structure is **not accepted**; (c) example keys / passwords: only the "acceptable forms" defined in §15.1 item 1 are accepted, and they **must not carry a real issuance prefix**; (d) internal addresses vs. documentation example addresses: **internal addresses are not accepted**, while **documentation example address ranges are accepted** (for the basis see item 1; internal IPs fall under item 1's prohibition, not under a PII entry). The exact form values are defined by `tools/check_secrets.sh`.


(For the graded exception for Category B and private Category C projects, see §15.4; employee personal sensitive information is not eligible for any exception.)

**5. Commit metadata and message privacy:** For public repositories, author/committer emails and commit messages must be included in the scan; the verification entry point is provided by `tools/check_secrets.sh` (including git history and metadata). See §15.3 for remediating historical leaks.

### 15.2 Secrets Management Principles

Secret information must not enter git. Secrets include: keys, passwords, tokens, internal IPs, internal domain names — any information you would not want to appear on GitHub after open-sourcing. **In Category B and private Category C projects, non-credential information is handled under the graded exception of §15.4; credential-class information is not eligible for any exception.**

**Secrets storage (TOML override preferred; `.env` is an optional user-side channel):**

1. **`.env` file** (for third-party components that read nothing but environment variables, or for flat key-value cases the user chooses): store in `KEY=VALUE` format in `.env` (local, **never tracked**). `.env-example` serves as a template in git, listing all required environment variable names and descriptions, without real values. Per §7.1, `.env` is not the preferred source of truth for project configuration — configuration that can go into the TOML override should not live here.

2. **TOML override file** (for secrets nested within configuration structures): use `.local/config.override.toml` (gitignored), following the §7.1 layered configuration pattern — the base TOML contains all fields (secret fields left empty), and the override TOML only fills in the secret values. The program deep-merges them into a single dict on startup.

**Selection criteria:** Prefer the TOML override (the single source of truth for configuration). Use `.env` only when a third-party component reads nothing but environment variables, or when the user explicitly chooses so. **Mixing both approaches for the same field is prohibited** — each secret field must have exactly one source.

**Rules:**
- No literal secret values may appear in any code, documentation, configuration templates (including `.sample` and `.env-example`), or example files
- `.env` and override files must be excluded in `.gitignore`
- Template files (`.env-example` or `config.override.sample.toml`) must be tracked in git, using placeholders to guide deployers (the forms are defined by `tools/check_secrets.sh`)
- Personal information (email, phone numbers, instant-messaging accounts, etc.) that must appear in configuration should go into the TOML override (§7.1) in preference; use `.env` only when environment variables are genuinely required. It must not be hardcoded in the base config or templates

**Litmus test:** Can an outsider clone the project and run it (in degraded mode) without access to any secret information? Does the git history contain any secret information or personal information?

### 15.3 Post-Leak Response

If secret information was ever committed to git history:
- Confirm via `git log --all --full-history` that no sensitive file history remains
- Use `BFG Repo-Cleaner` to thoroughly purge all traces, then rotate every leaked key
- Confirm `LICENSE` file exists and is correct
- Confirm README contains no references to internal resources

If what leaked is personal information (PII) rather than a secret, the history-rewrite exception still applies (see §19.1). BFG only purges file content — it **cannot** change author/committer emails; changing emails requires `git filter-repo --email-callback` (or `git filter-branch --env-filter`), with tags rewritten in step. Afterwards, force-push and ask the hosting platform to purge cached views; forks and third-party mirrors cannot be guaranteed.

### 15.4 Graded Exception: Project Class and Repository Visibility

**Principle:** The grading baseline is the **project class** (Category A is strict; Category B and Category C that are not pushed to a public repository are lenient), because the latter two are not published publicly by default. Once the grade is set, what decides the consequence is whether the information can enter an **uncontrolled public scope** — once a repository becomes public, the exception immediately ceases to apply (see "Applicability" below for the concrete boundary). The real risk is not "this information is in git" but "this information is pushed to an uncontrolled public scope". §15.1 item 5 is already limited by "public repository"; this section generalizes that same approach to the remaining check items.

**Applicability:** Category B (closed-source private repositories) and Category C projects not pushed to any public repository. Category A and any project pushed to a public repository **are not eligible for any exception**. **Once a repository becomes public** (including a newly added public fork, public mirror, or public release attachment), the exception immediately ceases to apply, and history is cleaned up per §15.3.

**Red lines (all classes, all visibilities, never relaxed):**
- Keys, passwords, tokens, private keys, certificates, SSH private keys, passwords in connection strings
- Credential-bearing addresses: URLs with a username/password, token, or signature (private sources, webhooks, pre-signed links)
- `.env`, `config.override.toml`, and other override/local files — they MUST always be excluded in `.gitignore` (§16.1, §19.2)

> **Boundary with §15.1 item 1 (this is not an exception):** The object of this section's red lines is the **information category** — real credentials have no exemption whatsoever; §15.1 item 1's "acceptable forms" judge the **form** — a value mechanically determined to be synthetic/reserved does not belong to the credential class at the moment of determination and therefore does not fall under this section's red lines. The two are two different levels, "category vs. form", and read together they do not conflict: **no** real credential may be exempted on the grounds of being a "fixture" or "example"; and a synthetic/reserved form **must not** be treated as a credential (that would force fixtures to be deleted, violating §11.4). Category A and public repositories have no named exemption channel (§15.1 item 1).

**Grading table:**

| Information kind | Category A / public repository | Category B / private Category C |
|---|---|---|
| Credentials (keys, passwords, tokens, private keys) | Forbidden | **Forbidden** (no relaxation) |
| Internal IPs, internal domain names, internal paths | Forbidden | Allowed |
| Company email addresses, real names, employee IDs / badge numbers, departments, internal IM group IDs | Forbidden | Allowed |
| Private datasets, internal data samples, internal documents | Forbidden (for the definition of "training data" see §15.1) | Allowed (you must confirm you hold the right to distribute internally) |
| Commit author / committer names and emails | MUST be a `noreply` or project mailbox (§15.1 item 5) | Company mailboxes allowed; `noreply` still recommended |

**Conditions that must also be met for the relaxation:**
1. `git remote -v` contains no public repository address; the repository is hosted on an internal network or under a controlled private organization
2. `.gitignore` still excludes `.env`, override configuration, and `.local/` (§16.1, §19.2)
3. **Live information about this project's own runtime environment** may still be written only into `.local/` per §16.2, and this exception does not relax §16.2 — what this exception relaxes is "company-internal information appearing as project content" (the non-credential information kinds listed in the table above, i.e. every row other than the credentials row), not "runtime environment records"; the boundary between this section and §16.2 is: the information kind is judged by the table above, the storage location by §16.2 (see also §17.5 for where the work log goes)
4. What is relaxed is "company-internal information"; it does not include **employee personal sensitive information** — national ID numbers, passport numbers, bank card numbers, home addresses, private mobile numbers, private email addresses — which must not enter the repository even in an internal repository

**Disambiguation for §15.1 item 4:** With this item-by-item relaxation, the "real name **combined** with other identity fields" referred to in §15.1 item 4 **no longer by itself constitutes a violation** for Category B and Category C projects not pushed to a public repository (real names, employee IDs / badge numbers, and departments are all relaxed in the table above); however, **employee personal sensitive information** must still not appear in any form or in any combination.

**Litmus test:** If this repository were made public tomorrow, what would be exposed in tracked files and git history? Only credentials and employee personal sensitive information are **unacceptable** answers; internal addresses and internal data are acceptable — but at that point the visibility change must be handled per §15.3, and it cannot be left to "we'll deal with it later".

---

## XVI. Local and Temporary Files

Every project generates local files that are useful during development but do not belong in the permanent codebase — run logs, migration plans, deployment notes, deployment configuration, personal experiments. Without a designated home, these files scatter across the repository, and sooner or later one of them gets committed with internal IPs or passwords still in it.

### 16.1 `.local/` — The Sole Home for Local and Temporary Files

The `.local/` directory at the project root is the **only** permitted location for all local and temporary files. It is excluded entirely in `.gitignore` — nothing inside it will ever be committed to the codebase.

`.local/` is not "suggested here" but "only here". Any local or temporary file found in a tracked path outside `.local/` constitutes a violation.

**The criterion for "local and temporary" is the nature of the file, not its extension or carrier.** Machine-readable data files (such as the capability and usable-tier matrix data defined by §17.7), configurations, templates, generators, and the human-readable views deterministically generated from them are permanent-codebase content; their home is tracked paths such as `docs/`, `configs/`, and `tools/`, and they **do not fall under this clause just because they are "not documentation"**. The "local and temporary files" constrained by this clause refer specifically to the six criteria listed in §16.2 — especially "contains runtime environment information", "describes a one-time operation", "personal notes", and "any engineering artifact that does not belong in the permanent codebase" — and the judgment is based on the nature of the content. **A machine-readable data file must not be judged a local file merely because its extension is not among the Markdown ones.**

`.local/` carries two categories of files:
- **Local deployment files** (long-term): deployment configuration overrides, localized startup scripts, and other deployment-specific artifacts that persist across sessions.
- **Temporary files** (short-term): run logs, phase materials, debug records, and other one-off artifacts.

### 16.2 What Belongs in `.local/`

A file that meets any of the following criteria is a local or temporary file and must go into `.local/`:
- As a runtime-environment record, contains runtime environment information
- Is a deployment configuration override
- Describes a one-time operation
- Is a personal note, debug record, or run monitor
- Is temporary data or an experimental config
- Is any engineering artifact that does not belong in the permanent codebase

If a file has long-term value to the project, first use the decision tree below to decide where it goes; only if none of them apply does it stay in `.local/`:

1. **User-facing, or referenced by `docs/`, and its content cannot be expressed by code** → turn it into formal documentation in `docs/` (§17.2).
2. **Its content can be expressed by code or tools** (the FAIL/WARN dividing line of check rules, match patterns, tool mechanisms, usage parameters) → **do not make it a standalone document**; let the code itself carry it — in-script comments, `--help`, the config schema (§1.6 "code is the first document").
3. **The rest** (personal records, phase materials, drafts nobody references) → stay in `.local/`.

**Note: a standalone document that is maintainer-specific and neither user-facing nor acceptance-facing has no home in the repository** — **unless it also has user-facing value (i.e. it satisfies one of the three content criteria of §17.2), in which case it may exist as the corresponding subsection in `docs/`**; otherwise it must go through item 2 (push it down into code/tools) or item 3 (`.local/`), and there is no third destination beyond those two. This is the direct consequence of this constitution having no documentation directory, and it is also §1.6's positive requirement: explanatory documentation that duplicates the code inevitably goes stale — do not write it.

**The sole exception: the work log (§17.5).** It has long-term value, but necessarily contains environment information (resources and environment), so it can only exist in `.local/` — it must never be turned into a `docs/` document. This is part of the data boundary (§1.4): environment information is not allowed to enter tracked files.

**Internal implementation plans and schedules do not enter the repository.** Implementation plans, schedules, and gap-closing plans that contain internal nodes, internal paths, internal accounts, or staffing **do not belong in** `docs/` — they do not satisfy §1.4's requirement of being externally obtainable and reviewable, and they violate the §15.1 item 1 prohibition on internal addresses and internal paths. The capability matrix in `docs/` **may** record "items to be filled in and the target state" (for the state values see §17.7), but **must not** record who will implement it, at which internal node, or via which internal path.

**Division of labour with §15.4:** This section governs the **storage location**, not the grading of the information kind — "what information may enter tracked files" is decided by the §15.4 grading table (e.g. an internal service address appearing as project content in a Category B project), while "where a file that is a record of the runtime environment goes" is decided by this section (into `.local/` only). Read together they do not conflict: information that may be committed under §15.4 is not thereby allowed to live outside `.local/` as a runtime environment record.

### 16.3 Relationship with `scripts/`

§10.2 defines `scripts/` as the directory for shared temporary code tools. The two directories divide the work as follows:
- `scripts/` — shared temporary code tools (committed to git, no backward-compatibility obligation)
- `.local/` — private temporary files (never committed, never shared, no obligations whatsoever)

---

## XVII. Documentation System

### 17.1 Bilingual Documentation

**Except as exempted by §17.6**, `README.md` (English) and `README.zh-CN.md` (Chinese) must be **content mirrors**, not just structural mirrors. The same operation instructions, configuration descriptions, and FAQ entries must exist in both versions — one version must never contain information absent from the other. Both READMEs must be updated simultaneously on every release.

> **This clause governs only the project `README`, and its exemption is bounded by the conditions of §17.6.** This constitution's own two language versions are two different objects: the Chinese version is the sole source of truth and the English version is its **full translation** (the direction is fixed as Chinese → English), see §17.8. The two are isomorphic in that "the two versions' content sets must be identical"; the difference is that §17.8 prescribes a direction, whereas this clause does not prescribe which of the two README versions comes first. **The §17.6 exemption removes only the formal requirement of "bilingual coexistence"; it does not remove any secrets-scanning requirement** — an exempted project is still bound by all of §15.1 and §15.2, and the single README must not contain literal secret values (§15.2).

Chapter structure: Introduction → Quick Start → Data Format → Configuration Reference → Output Description → Development Guide → FAQ.

### 17.2 User-Facing Documentation (`docs/`)

**`docs/` holds what is meant for users — the project's users and AI Agents, not collaborators in the development process.** Users care about only three things, and the content criteria of `docs/` are exactly these three kinds:

1. **How to use it** — how this software is actually used: quick start, installation and configuration, usage guide, command and parameter reference, minimal runnable example, typical usage, configuration examples, FAQ and troubleshooting.
2. **What the architecture looks like** — let users understand how the system works so they can use it correctly: module boundaries, responsibilities, interfaces, data flow, key processes, with the necessary structural-level diagrams.
3. **Whether it works well** — capability and boundaries (what it can do, what it cannot do, where the limits are), **usable tiers and performance baselines**, and the **capability and usable-tier matrix**.

**The basis for judging the reader and the content is "for whom, facing what", not "at which stage it was produced".** A document does not belong to the intermediate products merely because it "was generated from machine-readable data"; conversely, **things from the development process do not enter `docs/`** — how tests were done, how development was done, the judgments and decisions reached along the way, process records of runs, review records, task plans: **users do not care about them**; they care only about the **finished product already built and already pushed to GitHub**: how the product is, how to use it, what its architecture is, and whether it is good to use.

**Content that goes into `docs/`** (split by topic, each file focused on one concern; the following are examples, not a closed list):
- Quick start, installation and configuration, usage guide, command and parameter reference
- Capability and boundary statements — what this project can do, what it cannot do, where the limits are
- **Capability and usable-tier matrix** — list tier by tier whether each tier is usable (including the list and count of usable tiers), performance and baselines; one document carries two responsibilities at once: **① the acceptance record; ② the user-facing statement of capability and tiers**. See §17.7 for details; **the matrix must explicitly state the commitment boundary (see §17.7 "Boundary-statement obligation")**.
- Examples: minimal runnable example, typical usage, configuration examples
- FAQ, troubleshooting
- User-facing architecture explanation: module boundaries, responsibilities, interfaces, data flow

**Content that does not go into `docs/`:** things from the development process — how tests are done, how development is done, the judgments and decisions reached along the way, process records of runs, review records, task plans; as well as what has only short-term value to an individual or the current phase (§16.2), and what can be expressed by code or tools and therefore needs no standalone document (§1.6). **Note: "does not go into `docs/`" does not mean "has no home"** — they land in `.local/` (§16.2) or in code/tools (§1.6). **The concrete matching rules are carried by the `tools/` scripts themselves** (§15.1 first-paragraph division of labor).

**The boundary with §1.6 still applies:** the **architecture explanation** in `docs/` writes only the structural-level "what" and "why" (module boundaries, responsibilities, interfaces); implementation details live in code comments (§12.4); the usage documents in `docs/` serve "how to use it" and are not allowed to copy implementation details just because they are user-facing.

**All diagrams in documentation must be drawn with Mermaid — ASCII hand-drawn diagrams are prohibited.** Mermaid is machine-parseable, natively rendered by GitHub/IDEs, and AI can generate and modify it; ASCII diagrams cannot be maintained, and AI cannot reliably redraw them. Node names must always be wrapped in English double quotes for compatibility across renderers. **The necessary structural-level diagrams (architecture, flow, data flow, etc.) are essential elements of an architecture explanation** — after reading it, you know how the system works. Directory trees, tables, and other plain-text structures are not "diagrams" and are exempt from this rule.

**Tracked documentation contains no deployment environment records.** Deployment notes, experiment records, run monitoring, and similar artifacts are local files as defined in §16.2 and belong in `.local/`. `docs/` **is allowed** to contain opaque run IDs, acceptance criteria, per-tier conclusions, and failure attribution (acceptance is user-facing acceptance; both the conclusions and the attribution are things users have a right to know).

**The commit rules for internal-network information in `docs/` are judged per the existing division of labor between §15.4 and §16.2; this clause sets up no stricter prohibition of its own.** Specifically: **whether it can enter tracked files** is decided by the §15.4 grading table by **project class and repository visibility** (in Category B and Category C projects not pushed to a public repository, internal IPs / domain names / paths as internal service addresses in project content are allowed); **whether it is a runtime environment record** is decided by §16.2 (host paths, hostnames, container names, and other runtime environment records may only go into `.local/`); internal nodes, internal accounts, and staffing are handled per §15.1 item 1 and §16.2. **The sole exception is the landing point of the capability and usable-tier matrix** — the matrix has its own stricter basis (because it is user-facing and AI-facing), see §17.7 "Relation to the §15.4 graded exception". For the verbatim basis see §17.7.

**Litmus test:** Can a user who **does not know this project** answer three things from `docs/` alone — **① how to use this software** (install it, run the minimal example, find the parameters)? **② what its architecture looks like**? **③ whether it works well** (how many tiers are usable, how VRAM and speed are, where the boundaries are)? If all three are answerable, `docs/`'s positioning is correct.

### 17.3 AI Assistant Documentation

If a project uses AI coding assistants, it may generate assistant-specific local instruction files on demand (high information density, structured) to help AI understand the project's architecture and conventions. These files are **not committed to git** (excluded in `.gitignore`) — they are part of the local development environment. If the project does not use AI assistants, there is no need to create these files.

Projects that use the work log (§17.5) should place a one-line pointer to `work_log_current.md` in the AI assistant's local instruction file, explaining that its state section opens with the "User's Original Prompt" anchor, which must be read at every session — so AI discovers the log entry point and the intent anchor at every session.

### 17.4 Version History

Projects do not maintain a standalone Changelog file. The git commit log is the single, authoritative change history. On release, tag the version with `git tag`. To review changes, use `git log`. Commit messages must follow the format specified in §19.1 so that `git log --oneline` is a readable project history.

### 17.5 Work Log: Continuous Handover

Handover is not an event; it is a continuous state. Instead of writing a compressed handover document at each transition, maintain a work log — essentially a continuously updated handover document that lets any successor (human or AI) continue the work at any time, without asking the original author.

The work log consists of two files under `.local/`, never committed to git (they necessarily contain environment information, §16.2):

- **`work_log_current.md` — the state section, read at every session.** It holds only the latest values, updated in place, never pruned; **the sole exception is the leading "User's Original Prompt" anchor — append-only, never overwritten**. Organized into the following sections: user's original prompt (one sentence recording the user's original task intent, frozen after first write, with new lines appended only when the user explicitly changes the goal; it is the intent anchor across sessions and context compactions, preventing gradual drift from the original goal in long tasks), current progress, current major difficulties and problems, task plan (checklist format, `[ ]` todo / `[x]` done), unresolved questions (decision points requiring user confirmation), planned solutions to try, resources and environment (servers, GPUs, available tool scripts, etc.), technical conventions and tooling notes (frameworks, design patterns, coding conventions). Keep it under about 100 lines — it carries the "understand the state in 30 seconds" responsibility.
- **`work_log_history.md` — the event section, read on demand.** Appended incrementally with timestamps (entries start with `YYYY-MM-DD HH:MM`). It records the user's original requests, completed tasks, and resolved problems, newest at the end. When the log grows long, prune selectively: delete from the head (oldest) entries that are **already absorbed into code or docs and no longer worth referencing**; important decision context may be kept forever. **Pruning is a trade-off, not a truncation** — if after pruning a successor cannot understand the current state faster than from reading git log, you pruned too much.

Relationship with git: the git commit log is the authoritative record of change facts (immutable, §17.4); the work log is the narrative decision context (selectively compressible). The log records what git doesn't — why, difficulties, plans, next steps. The log is not a Changelog replacement and carries no authority; every statement in it should be cross-verifiable against git or the code.

Division of labor between the state-section anchor and the event section: the event section keeps the **verbatim original request** (prunable with history), while the state-section anchor keeps the **stable intent summary** (never pruned). Different purposes, no duplication.

**When to update:** at the end of each working session or when a phase completes — append 3–5 lines to the event section and refresh the state section (the "User's Original Prompt" anchor stays unchanged unless the goal changes). Projects that use AI assistants place a pointer to `work_log_current.md` in the AI assistant's local instruction file (§17.3).

**Litmus test:** Can a newcomer (human or AI) fully continue the work reading only the work log and the codebase, without asking the original author? If not, the log is incomplete.

### 17.6 Single-Language and Private Projects

**Principle:** Bilingual READMEs (§12.3, §17.1) serve a clear goal: letting open-source projects reach both the English and Chinese developer communities. When that goal does not exist, the bilingual requirement no longer applies — the project should choose the language of its widest target audience and stay consistent.

**Rule:** A project meeting any of the following conditions may keep only a single `README.md`, with language kept consistent (Chinese or English at the author's discretion):

1. **Private project**: the project is not pushed to any public repository and is used only within an intranet or private repository.
2. **Single-language audience project**: the project's target user community is clearly a single-language community, and the maintainer judges that a bilingual README would not yield practical community coverage benefits.

**The object of this clause's exemption is the project `README`.** This constitution's own two language versions are not exempted according to project class — the Chinese version is the sole source of truth and the English version is a full translation, see §17.8.

**Technique:**
- Exempt projects should clearly state the document language in the sole README to avoid reader confusion.
- Choose the language based on the target audience: Chinese for Chinese-speaking communities, English for English-speaking communities.
- If the project later becomes open-source or expands its audience, add a bilingual README at that point — this is not debt; it is a scope change.

**Litmus test:** Does the project's target audience include both Chinese and English-speaking communities? If not, and the project is not in a public repository, a bilingual README produces no practical value.

### 17.7 Capability and Usable-Tier Matrix (`docs/`)

**The three things to answer.** The capability and usable-tier matrix answers three things for users: **① how many tiers are usable** (the list and count of usable tiers); **② how performance is**; **③ every listed tier is usable** (for the criteria see "Usability criteria" below). The matrix's smallest entry is the **tier** (see the definition at the end of this section), and the smallest unit of a per-tier conclusion is likewise the tier.

**Positioning: one document, two responsibilities.** The matrix lives in `docs/`. It is **both a user-facing document and an acceptance-facing one** — **acceptance is user-facing acceptance** (§11.5), and the purpose of acceptance is to answer "what can users use, how does it perform, and how many tiers really work". Hence acceptance-facing artifacts are naturally user-facing artifacts, and the two are aligned: one matrix document carries both **① the acceptance record** and **② the user-facing statement of capability and tiers**. **This does not constitute a "one file, two readers" problem** — the readers of both responsibilities are the same: users. Only when the **readers of different responsibilities are not the same group of people** is it necessary to split into two documents; this project's capability matrix is not such a case. **The matrix describes the platform's capability and performance baseline, not a commitment about the training effect on users.**

**The two kinds of "effect" must be stated clearly and must not be conflated (the core of this clause).** Effect information in the matrix comes in two kinds with completely different roles:

- **Effect meets the standard on the platform-side dataset — this is a usability criterion** (see "Usability criteria" below, item 2). It answers "did this tier really produce the effect it should, under our own dataset and parameters", and is therefore **evidence that it is "usable and most likely bug-free"**.
- **The effect under users' own tasks, datasets, and hyperparameters — this is outside the commitment scope.** The training effect depends on users' own tasks, datasets, and parameters; **how users' datasets will turn out and how they will turn out with users' own hyperparameters is not guaranteed by this matrix.** This matrix only guarantees **that it ran on our dataset and produced very good results**. If a user does not get good results on their own data, the cause is most likely their own task, data, or parameters rather than an infrastructure problem — if the infrastructure had a problem, our own dataset should not have produced good results either.

**Usability criteria (determining "usable / unusable" — both must be satisfied):**

1. **Can run through to completion**: exit code zero, the algorithm's mechanism genuinely in effect (not idling), the output can be inferred from or loaded, the output form is compliant, and VRAM and throughput are within the committed range.
2. **Effect meets the standard under platform-side datasets and platform-side parameters**: judged as meeting the standard according to the criteria and thresholds defined by the platform side.

**What is not part of the commitment:** **the effect under users' own tasks, datasets, and hyperparameters** — it does not enter the commitment scope and does not participate in the "usable / unusable" judgment.

**"Unusable" must state which criterion was not met.** When a tier is marked "unusable", it **must** explicitly state whether what it failed is **item 1 (will not run through / mechanism not in effect / output unusable / over VRAM)** or **item 2 (effect did not meet the standard under platform-side datasets and platform-side parameters)**, and the facts of the items it did pass must be retained. **Not** just the word "failed" — that makes users misread "effect did not meet the standard" as "**the platform cannot run it**". **But item 2 must not for that reason be excluded from the usability criteria**: failing to meet the standard on the platform-side dataset is **unusable**, and presenting it as such is all that is required.

**Boundary-statement obligation (must be explicitly written).** Such a user-facing capability and usable-tier matrix **must** **explicitly state its commitment boundary** in the document, in wording **no weaker than**:

> **The capability and usable-tier matrix states each tier's usability and performance baseline: every listed tier has been run through to completion on our dataset with good results (as evidence that it is "usable and most likely bug-free"). The training effect depends on users' own tasks, datasets, and parameters and is not within the commitment scope of this matrix.**

A matrix that does not state **this boundary statement** is **deemed incomplete in its delivery as a matrix document** — the visibility of the boundary is as important as the matrix data itself; it **must not** be left for users to infer on their own, nor **must** it be hidden in a footnote, appendix, or glossary. This is also the Preamble's "never invent requirements for the user" put into practice in this section: counting the effect on users' tasks as a platform commitment is precisely inventing requirements for the user.

**The content requirements of that boundary statement (verbatim copying is not required, but no item may be missing).** The criterion for "state the boundary statement" is that **the content must cover the three points above**: **① each tier's usability** (every listed tier has been run through to completion) / **② the platform-side dataset conclusion** (the effect meets the standard under platform-side datasets and platform-side parameters, and this is evidence that it is "usable and most likely bug-free") / **③ users' effect is outside the commitment scope** (the effect under users' tasks, datasets, and parameters is not committed by this matrix). **Copying the quotation above certainly satisfies it; different wording that covers all three points likewise satisfies it** — what this clause requires is **semantics no weaker**, not verbatim comparison.

**Who judges, and against what checklist.** ① **Existence** is mechanically judged by the `tools/` scripts against the **three-item checklist** above (any missing item is a FAIL, with **no verbatim comparison**); ② **whether the wording is "no weaker"** is executed by the §17.8 final-review reading, checking **item by item against the same three-item checklist**. **Counter-example (counts as "no weaker" not achieved)**: writing only "the effect is not guaranteed" or "for reference only" without positively stating points ① and ② is judged non-compliant — it evades the positive conclusion "the platform side has run it through and met the standard", and what users read is "this thing may not work".

**Baseline values and criterion bases must carry their basis.** Any effect figure presented as a reference, and any criterion used to judge "the effect meets the standard", **must** state the basis on which it holds, complete enough to be **reviewable**; a figure missing either item **must not** be written into the matrix as a baseline or criterion. **The exact field checklist is defined by the completeness check of the `tools/` scripts** (§17.7 tool division of labor).

**Evaluation data and criterion bases must be reviewable.** Concrete implementation of the preceding paragraph: the matrix **must** state the **dataset identifier, criterion identifier, threshold, and target value** on which the judgment that this tier meets the standard is based; datasets that can be made public **should** state how to obtain them, and those that cannot **must** state the fact that they are "platform-owned / not public" and give reviewable alternative anchors (data version identifier, criterion definition, sample size, and evaluation method). **Must not** omit the basis on the grounds that "the dataset is not public" — omitting the basis leaves users unable to review the statement "the effect is good", and **the conclusion ceases to be evidence**. At the same time, **must not**, to satisfy this paragraph, write dataset contents, host paths, internal addresses, internal paths, or dataset storage locations into `docs/` — **what is to be made public is the basis, not the data**.

**Single-source generation (mandatory):**

1. **Machine-readable data is the sole source of truth.** The tier list, per-tier parameters, and per-tier conclusions are carried by one **machine-readable data file** (inside `docs/`, with the extension chosen by the project), which is the matrix's **only editable source**. **Forbidden** to declare that "the human-readable file and the machine-readable file are both sources of truth" or that "the two are each other's source of truth" — that is not a single source of truth but two sources: even if the two are currently consistent, they will inevitably diverge on the next modification.
2. **The human-readable view is deterministically generated from the data.** The human-readable file (Markdown, HTML, etc.) that users read **must** be deterministically produced from **that data + a fixed generator**: the same input must produce the same byte string. The generator **must not** read the clock, the environment, the network, or human-computer interaction results.
3. **No hand-editing.** Any change to the human-readable view must change the **data** or the **generator** and then regenerate. **Manually editing a generated artifact is treated as a violation**, on a par with manually tampering with the data.
4. **Byte-for-byte rebuildable.** The human-readable view in the repository must be **rebuildable byte-for-byte** from the current data and generator; the check is to regenerate and compare byte-for-byte with the on-disk file, and **any differing byte is a failure**. This turns "has it been hand-edited" into a machine-decidable fact rather than relying on people's diligence.
5. **Fixed direction.** The derivation direction between the data and the human-readable view must be unique and fixed; **forbidden** to infer in both directions, synchronize bidirectionally, or "backfill the data from the view".

**Single-source generation is not "two sources of truth", and sharing the same home does not change that.** The data file and the human-readable view are both in `docs/`, but **only one is editable**: the data file is the sole source of truth, and the human-readable view is a read-only artifact deterministically generated from it. The basis for judging "are these two sources" is **"can it be edited independently"**, not "which directory it is in" — putting one source and one derived view in the same directory is still one source. **`docs/` is not limited to Markdown**: machine-readable data files and the human-readable views generated from them both live inside `docs/`; the criterion is always the reader and content criteria of this section and §17.2, not the file extension.

**Coverage threshold and failure states: unverified must not masquerade as usable.**

- Every tier **must be explicitly marked with a verification status** in the matrix, and only four values are allowed: **verified usable / verified unusable / not yet verified / not included in acceptance**. A tier with no measured conclusion in the data **must** be shown as "not yet verified" — **must not** omit the tier, **must not** pass off a design target as verified capability, and **must not** use blank space, a placeholder, or a neutral style so that users misread it as usable. The four states must have **distinguishable text labels** (not relying on color, a legend, or blank space). **"Verified usable" may be given only when both "usability criteria" are satisfied** (can run through to completion **and** the effect meets the standard under platform-side datasets and platform-side parameters); **failing either one makes it "verified unusable"**, and it must state which one was failed (see '"Unusable" must state which criterion was not met' above). **Tiers not yet measured must be marked "not yet verified" and must not be counted into the number of usable tiers.**
- **Coverage threshold:** Only when **all tiers already have a definite conclusion** — a value among "**verified usable / verified unusable / not included in acceptance**" (that is, not "not yet verified") — is it allowed to claim the project's overall capability commitment anywhere in the document. **"Not included in acceptance" must be explicitly marked per tier, stating the reason for exclusion and the applicable scope**, and must not be substituted with a blank space. When this condition is not met, an explicit warning **must** be written on the document's first screen (the warning wording is composed by the project according to this criterion), and the title and summary must not use capability-commitment wording, and the list and count of "not yet verified" tiers must be given at the same time.
- **An overall commitment cannot be proven by individual passes.** When several tiers together constitute one capability commitment (for example, "the full combination is usable"), **must not** declare that commitment to hold because individual tiers passed; the condition for the commitment to hold is that **all** tiers in that commitment set pass; otherwise it must explicitly state "that commitment is not yet met" and list the tiers that failed and those not yet verified.
- The matrix **must not** use "verified unusable" to mask "not yet verified": writing a never-measured tier as "unusable" is just as distorted as writing it as "usable".

**Must not play down platform-side failure by "not committing to the effect".** "The effect on users' tasks is not committed by this matrix" only moves **the effect under users' tasks / data / hyperparameters** out of the commitment scope; it does **not** demote **platform-side failure** to "for reference only": **failure to run through, exceeding VRAM, unusable output, or a non-conforming output form must still be presented truthfully as "verified unusable", with the failed item stated.** The two obligations run in parallel — "not committing to the effect" **does not relax** "truthfully presenting the platform's capability"; the matrix **must not**, on the grounds that "the effect is not ours to manage anyway", write a tier that will not run as "not yet verified" or in vague wording. **Symmetrically**, it must not write "the effect did not meet the standard on the platform-side dataset" as "will not run" or vaguely as "not yet verified" — that too is "verified unusable", only the failed item is criterion 2.

**Auto-generated tracked documents (the matrix's human-readable view is of this kind):**

1. **Explicitly mark the generation relationship.** The file header must have a machine-readable generation marker, and the document's first screen must have a user-visible explanation; both must state "This file is automatically generated by `<generator path>` from `<data path>`; **manual editing is forbidden**".
2. **No scan exemption.** Generated artifacts enter the §15.1 scope of secrets, personal information, and runtime-environment checks **on the same footing** as hand-written documents; **must not** be exempted from scanning on the grounds that "this is machine-produced".
3. **Reviewable diff.** Generated artifacts must be byte-for-byte rebuildable from the data (see "Same-source generation" item 4, "byte-for-byte rebuildable", above), which puts the review cost on the **diff of the data and the generator** — the reviewer need not read the generated artifact line by line, only look at the changes to the data and the generator and then confirm that the on-disk generated artifact can be rebuilt from the current data.

**Matrix data and the compliance floor (single track; division of labor with §15.1 item 1 and §16.2):**

- **What the matrix in `docs/` is allowed to contain:** opaque run IDs, acceptance criteria, per-tier conclusions, and **failure attribution** (cause analysis, criterion threshold details, difference values, identifiers of the criteria not passed). Rationale: acceptance is user-facing acceptance, and **both the conclusions and the attribution are things users have a right to know** — users must be able to judge "does this conclusion still hold, why does this tier not work, and which criterion it fails on".
- **What is still forbidden in the matrix:** host paths, internal addresses, internal domain names, internal paths, machine names, personal names, and **internal nodes and internal accounts**. The basis divides three ways: **host paths and machine names** belong to §16.2's runtime environment records (which may only go into `.local/`); **internal IPs / domain names / paths** belong to the "non-credential company-internal information" of the §15.4 grading table — **the §15.4 relaxation for Category B and private Category C projects does not apply at this landing point, the matrix** (for the reason see "Relation to the §15.4 graded exception" below); **internal nodes, internal accounts, and personal names** belong to the §15.1 item 1 secret categories. **This clause sets up no further prohibition applying to `docs/` as a whole** — the commit rules for non-matrix content in `docs/` follow §15.4 and §16.2 (§17.2).
- **Relation to §16.2:** §16.2 governs the **storage location** (what belongs in `.local/`), while this clause governs the **two lists of matrix content** (what is allowed, what is forbidden). Read together they do not conflict: information that may be committed under §15.1 is not thereby allowed to appear in the matrix as a runtime environment record.
- **Relation to §15.1 item 1:** item 1 defines the **check categories** and the scripts define the **exact match patterns** (§15.1 first-paragraph division of labor). This clause's "forbidden" list is a **restatement** of item 1 at the landing point of the matrix; it adds no independent category and constitutes no exception.
- **Relation to the §15.4 graded exception (Category B and Category C not pushed to a public repository):** what the §15.4 relaxation settles is "whether this information may enter tracked files"; what this clause's forbidden list settles is "whether this information may appear at this user-facing landing point, the capability and usable-tier matrix" — the matrix's readers are users (including external users) and AI, not internal collaborators, so **the matrix does not get the §15.4 relaxation**: Category B and private Category C projects likewise must not write internal IPs, internal domain names, internal paths, machine names, internal nodes, or internal accounts into the matrix; if such information must be recorded, it goes into `.local/` (§16.2). This clause neither relaxes nor tightens the §15.4 grading conclusions for **other** landing points (code, configuration); the commit rules for **non-matrix** content in `docs/` are decided by §15.4 and §16.2 (§17.2).
- **The §15.4 grading table is not changed (except for the tightening of the matrix landing point in the preceding item):** the grading table grades by **project class and repository visibility**. **Category A and any project pushed to a public repository must not, because of this clause, contain any internal information** (they are strict under §15.4 anyway).

**Tier.** A **supported configuration combination** that this project offers to users along one capability dimension; each tier is an independently verifiable, independently referenceable unit with a **stable identifier**. The capability and usable-tier matrix takes the tier as its **smallest entry**; per-tier conclusions take the tier as the **smallest unit of conclusion**; the data, the human-readable view, and the acceptance record are aligned by **the same set of stable identifiers**. A tier's definition and list are governed by its machine-readable data (item 1 of this clause). **Which dimensions make up a configuration combination is defined by each project according to its own capability dimensions and is not fixed by this clause.**

> **Tool division of labor:** This clause only prescribes **categories and criteria** (data uniqueness, deterministic generation, no hand-editing, byte-for-byte rebuildability, prohibition items for desensitization, consistency of states with the usability criteria, completeness of the basis, existence of the boundary statement). The concrete generation commands, the file pairs to compare, the match patterns for "hand-editing", the basis field checklist, and the existence check for the boundary statement are defined by the `tools/` scripts (following the existing §15.1 first-paragraph division of labor). **The matrix's desensitization scan (host paths, intranet addresses/domains/paths, machine names, person names, internal nodes and internal accounts) currently has no supporting script and is not yet implemented in the `tools/` scripts** — the prohibitions prescribed in this clause remain unchanged.

**Litmus test:** If you delete the matrix's human-readable view from `docs/`, can you rebuild every byte of it from the data and the generator alone? If the rebuild result is not completely identical to the on-disk file, there is hand-editing or a second source. **Does the matrix answer those three things — how many tiers are usable (the list and count of usable tiers), how performance is, and whether every listed tier has a conclusion that "both criteria are satisfied"?** Is there any cell so vague that users would mistake it for usable? Is there anywhere that writes only "failed" without stating which criterion was not met, making users think the platform cannot run it? If there is, this clause is violated.

### 17.8 Language, Writing Style, and Revision of the Constitution Text

This clause governs the relationship between **this constitution's own** two language versions and its textual writing style. §17.1 governs the project `README`, §17.6 governs the README's single-language exemption; the three have different objects and read together they do not conflict.

**The Chinese version is the sole source of truth.** The authoritative definition of the constitution's content is the Chinese version (`BADGE-constitution-v<version>.zh-CN.md`). The English version (`BADGE-constitution-v<version>.en.md`) is a **full translation** of the Chinese version, a derived artifact, not a second source of truth — it adds nothing, removes nothing, and independently interprets no clause.

**Revision process: first change the Chinese version and finalize it, then translate the whole thing into the English version.** Any addition, modification, or deletion of a clause is completed and finalized in the Chinese version first; the English version takes the **finalized Chinese version** as its sole input and is retranslated as a whole. **Forbidden** for the two versions to evolve independently: forbidden to change the English version first and "backfill" the Chinese version, forbidden for the two versions to separately absorb content the other does not have, forbidden to change only one place without retranslating the remaining affected clauses.

**The two versions must be consistent:**
- The version numbers are identical — two language versions with the same version number are the product of the same translation relationship and are released together
- The chapter structure and numbering are identical — §a.b points to the same clause in the English version
- The clause sets are identical — every clause the Chinese version has must exist clause by clause in the English version, and vice versa

**The writing style of the constitution text.** This constitution writes only **concepts, criteria, and general explanations**. Any expression that could be replaced by a value of the same kind without changing the clause's meaning — a specific instance, a specific number, a specific form, a literal value, and metaphors/analogies — is not written at all; the exception is enumerations necessary to the criteria — **the reason they cannot be deleted is explained at constitution-revision review and recorded in the revision record** (§17.4's git commit record / revision plan), **not repeated inside the clause**. **Specific examples that a tool can mechanically verify are all pushed down into `tools/`**: the constitution writes only the categories and criteria of checks, and the concrete determination rules are carried by the scripts themselves (§15.1 first-paragraph division of labor).

**Relation to the opening "How to read this constitution".** The opening passage is only a **reading guide**; **it sets no criterion and carries no mandatory force**; all criteria for the text's writing style are governed by this clause. Where the two disagree, this clause prevails.

**Exceptions (forms that may be kept; the reasons they cannot be replaced are uniformly explained at constitution-revision review and recorded in the revision record, see below, and are not repeated inside the clause):**
1. **Standard templates** — **executable landing points** where replacing them would change the reader's actions or the tool's behavior (directory trees, config file skeletons, build scripts, paste-ready command blocks, etc.). They are not "replaceable values of the same kind"; deleting or replacing them would directly change the reader's actions.
2. **Enumerations necessary to the criteria** — **category lists** without which it could not be determined "what to do / what to scan / what to compare" (such as the secret categories in §15.1 item 1, the personal-information categories in item 4, the four state values in §17.7, and the three residue locations in §14.3). Such enumerations are the criteria themselves, not examples.
3. **Bundled examples explicitly marked "not a closed list"** — example lists that are **explicitly marked** with "the following are examples, not a closed list" or an equivalent sentence and that **do not serve as a basis for judgment** (such as the "content that goes into `docs/`" list in §17.2) are **exempt from this clause**: their demonstrative value outweighs the risk of overfitting, and they have been explicitly marked as open sets. **An example list without that marking is not exempt.**

**How the reasons are recorded.** Criterion-necessary enumerations and standard templates **may be kept**, but **their reason for not being deletable must be explained at constitution-revision review and recorded in the revision record** (§17.4's git commit record / revision plan) — **not repeated inside the clause**. The granularity of the reasons: **category 1 (standard templates) uses a single unified reason** — "**executable landing points** where replacing them would change the reader's actions or the tool's behavior" (all 7 standard templates share this one, not expanded one by one); **category 2 (criterion-necessary enumerations) explains item by item** "what could not be determined if it were deleted"; **category 3 (examples explicitly marked "not a closed list") is exempt from the explanation obligation** (it has been marked as an open set).

**Scope of effect:** This clause **takes effect only for newly revised and newly added clauses**; clauses that already existed before this revision **do not immediately violate it because of this clause**, and are **handled in batches** under §18's debt management: at revision time the constitution maintainers create debt entries for existing clauses (recording the clause location, the violation form, and the planned batch), apply it first in newly added and revised clauses, and de-example existing clauses batch by batch. **Forbidden** to use this clause as grounds to launch an unplanned one-off full rewrite of existing clauses.

**Litmus test:** Take any clause of the English version — can you find exactly one corresponding source text in the Chinese version? Does the English version contain any clause the Chinese version does not have at all? Take any clause of the Chinese version — does it contain an instance, number, literal value, or metaphor that "could be replaced by a value of the same kind without changing the clause's meaning"? If it is an exception (a standard template / a criterion-necessary enumeration / an example explicitly marked "not a closed list") yet its reason for not being deletable is **not explained in the revision record**, that likewise counts as a violation. If the former cannot be done, or the latter exists, or the writing-style criteria are violated, this clause is violated.

---

## XVIII. Version Evolution and Debt Management

Technical debt is the cancer of engineering quality. Today's shortcut becomes tomorrow's double workload, and the day after tomorrow's untouchable forbidden zone. The core principle is one sentence: **once the new architecture is validated, the old architecture must be eradicated.**

### 18.1 No Debt Left Behind

- After the new architecture is online, tested, and stable, old code is **deleted immediately**: no "compatibility mode", no old-architecture directory, no version/legacy naming, no "to be deleted" comments — **the exact matching is defined by `tools/check_legacy_cleanup.sh`**. The codebase contains exactly one current architecture (migration scripts are an explicit exception, see §18.2).
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
- **Solo project exception**: a project with only one active contributor may push directly to the `main` / `master` branch, with no PR workflow required. When the project gains a second contributor, it must switch to the PR workflow immediately.
- All development happens on feature branches: `feature/<description>`, `fix/<description>`, `docs/<description>`
- Merging to main requires a PR — at minimum, review the diff yourself once
- Commit messages are **recommended** to be in English, format: `type: short description` (feat, fix, docs, refactor, test, chore). English is the de facto standard of the open source community — the `git log --oneline` toolchain is English-first, and it enables international contributors to understand. Projects whose primary contributor community uses another language (e.g. Chinese) may use that language, but should stay consistent within one repository.
- **History continuity over retroactive fixes.** Commits already pushed to a public repository **MUST NOT** be retroactively rewritten to fix commit message language — changing pushed history breaks every collaborator's local clone. The specification takes effect from the current commit forward. Exception: if historical commits contain leaked secrets or personal information, history MUST be rewritten (see §15.3).
- One commit does one thing

### 19.2 .gitignore Must Cover

`.gitignore` must cover all kinds of runtime caches, virtual environments, build artifacts, environment configuration and secret overrides, outputs and data, IDE and system files, and local temporary files — **the exact entry list and required ignore patterns are defined by `tools/check_gitignore.sh`** (following the §15.1 first-paragraph division of labor). **`.env` and its override files never enter the repository; this is a red line and is not relaxed by the list being pushed down.**

### 19.3 Open Source License

Use a permissive, commercially usable license by default; if the project depends on a library whose license requires compatibility to be maintained, choose a license compatible with it. The concrete determination is carried by `tools/check_dependencies.sh`.

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
