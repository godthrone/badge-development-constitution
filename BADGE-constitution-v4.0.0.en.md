# BADGE Development Constitution v4.0.0

> **B**oundary **A**nd **D**efensive **G**uard for **E**ngineering — Boundary and Defensive-Guard Engineering Development Constitution
>
> Good projects are not checked into existence by diligence — they are designed so that people simply cannot make a mistake.
> This constitution is the sediment of engineering taste — it tells you why designing this way is right, not merely what you should do.
>
> **This constitution is organized in three layers:** **L1 philosophy/methodology, L2 clauses, L3 examples**; the meaning of the three layers and the determination procedure are in "How to read this constitution" below.

> **How to read this constitution.** First identify the layer, then judge applicability, and finally act according to the modality.
>
> **Three layers.**
> - **L1 philosophy/methodology** — answers "why doing it this way is right, how good and bad are judged, and how trade-offs are made". It binds no technology, form, or number, and still holds when applied to another project. **L1 is not changed, and cannot be waived.**
> - **L2 clauses** — provisions that land L1 on concrete engineering behavior. Every L2 clause carries a **modality** and an **applicability condition**: modality `M` = must be achieved, `R` = recommended practice (not adopting it requires being able to state a reason); applicability condition = "which projects, in what form" it governs.
> - **L3 examples/templates** — landing points you can copy directly (directory trees, config skeletons, command snippets, example values). **They are not a criterion** and may be replaced or omitted; only when you decide to adopt this template do you check yourself against it.

> **Section names are not layer names.** The section names "Layer 1 / Layer 2 / Layer 3" of this constitution are **section names**, and are not the same thing as L1/L2/L3: L1 = philosophy/methodology, L2 = clauses, L3 = examples.

> **`self` in a marker.** You will also see `self` in a marker — it means **it binds only this constitution repository itself** (definition in §21.1).
>
> **Whether one requirement applies is asked in three sentences, in order:**
> 1. **What layer is it?** L1 always applies and cannot be waived; L3 constitutes no obligation; only L2 goes on to the questions below.
> 2. **Does its form trigger condition hold here for me?** (code / container / deployment environment / optional tiers or quantified claims / data artifacts / CLI provided / multiple implementations of the same interface ... **the complete vocabulary is in §21.1 "Marker Syntax", and it is a closed set**) If it does not hold → this requirement creates no obligation for you.
> 3. **Does its category include me?** (Category A = public Python project, Category B = closed-source Python project, Category C = other infrastructure project; definitions in Layer 0) If it does not include you → no obligation arises.
>
> All three pass → act according to the modality: `M` must be achieved; `R` is a recommendation, and not adopting it requires being able to state a reason. **When in doubt, treat it as applicable.**
>
> **A marker is a declaration, not a clause.** The concrete instances, concrete values, concrete forms, and literal values that appear in a clause **are examples, not a closed list** — replacing them with values of the same kind while the meaning is unchanged is not a violation; **one must not infer from a single example that the remaining cases do not hold**. Concrete samples and decision rules that a tool can mechanically verify **are not in this constitution**; they are carried by `tools/` (the division of labor in the first paragraph of §15.1).
>
> **This paragraph defines the meaning of the three layers and the determination procedure above** (by it a reader can judge which layer one requirement belongs to and whether it governs them); **how the text is written, how it is changed, and how exceptions are recorded follows §21.1**. This paragraph provides the definitional force; the mandatory force is in §21.1; where the two disagree, §21.1 prevails.

---

# Preamble: The Execution-First Principle 〔L1｜all〕

**Faithfully understand and implement the user's instructions and goals, at minimum cost and maximum speed: fidelity first, cost second, speed third.**

When you receive a task, first ask: **What does the user actually want? Is this task hard?** After completing the assessment around complexity, reversibility, and ready-made entry points, decide in order:

1. **Fidelity first**: Make implementing the user's instructions and goals the sole yardstick — no more, no less; understand the intent faithfully before acting.
2. **Cost second**: Provided fidelity and risk are under control, finish at minimum cost; if it can be done in one pass, do it in one pass; if a simplest path exists, take it. **Entry points first** — first look for ready-made entry points such as scripts, README, and docs under the directory the user gave you to build the full picture, then decide whether to read the source in depth.
3. **Speed third**: Never sacrifice fidelity or safety for speed, and never sacrifice cost for "comprehensiveness".

**Why simple-first:** Fewer steps and fewer judgments mean a lower error rate — it is a means of foolproofing (§2) and of raising the task success rate. **It governs operations, not artifacts**: an artifact's complexity is governed by the entropy criterion (see "Entropy and complexity discipline" below).

Here **cost** means effort and resource consumption (tokens, tool calls, footprint of change); **speed** means wall-clock time and number of interaction rounds. When the two conflict, cost wins — rework is the largest time expense.

**Judgment criterion (without violating this constitution's mandatory clauses):** Can every unit of work in the deliverable point to "the user explicitly asked for it" or "it is necessary to fulfill that request"? Anything that cannot is over-execution. If any one explicit requirement in the user's goal is unmet, that is under-delivery — "do no more" is never a license to "do less".

**Risk gate (deciding whether to spend more cost): The cost paid to control a risk must be far smaller than the cost if the risk once materializes.**

- **Reversible**: the consequence is minor, controllable, and rollback-able — **all three hold at once** (e.g., editing docs, editing **local** config, a re-runnable script) → **just do it**; running a full verification pass for it is a huge waste.
- **Irreversible**: **any one** of the three above fails, which is this class (e.g., deletion, **data** migration, external release, production config change) → **pay the necessary cost of one quick verification first** (backup, boundary validation, pre-authorized fallback). **When in doubt, treat it as irreversible.**

**This principle only adjusts the depth of execution and the completeness of the deliverable; it exempts no mandatory clause** — the mandatory force of these clauses is independent of whether the consequence is reversible, and they all apply in full; **which clauses there are and whom each governs is judged by their own scope of application and markers**. The numbers below are only a navigation index and carry no criterion: security and secrets §15, contracts and interfaces §2.1, boundary validation §2.3, operational foolproofing §2.4, single source of truth §1.4, task decomposition §1.5, fallbacks §3. The **deliverable** takes these mandatory clauses and the user's explicit acceptance criteria as its floor and is **minimally sufficient** — stop once the acceptance criteria are met, without adding unrequested refinements, examples, or review rounds; the floor is not lowered. **Irreversibility adds verification and fallbacks only**; **it adds no functionality and no length**.

**§6 reproduction is not among them** — it has its own applicability precondition (see §6): it is pursued only when "the result needs to be run a second time in the future, and the second time must be consistent with this time", and the meaning of "consistent" is decided by the effect defined by the requirement.

**Escalation signal:** Only when a simple approach fails once, or the same problem recurs, escalate to root-cause investigation.

**Entropy and complexity discipline (symmetrical to the escalation signal):** Complexity may only be added one layer at a time, and every added layer must prove that it is necessary.

**The system's entropy comes in two kinds, pulling in opposite directions:** functional entropy — the number of functions, optional tiers, config items, and interface elements in the artifact: the more, the worse; structural entropy — the degree to which interfaces are unclear, boundaries untidy, naming inaccurate, and tests fail to correspond to functionality: the higher, the worse. The goal is not "simple"; it is **minimal functionality, maximal order**. There is only one test: **is this change serving the user's request, or serving "I think it should be"?** Wherever "simple" is given as a reason for a trade-off, it refers to the artifact complexity defined here; the **cost sense** (the "cost" defined in the paragraph above), the **operational sense** (number of steps, number of judgments, path length), and the **"minimal" inside a term such as "minimal normative unit"** all fall outside the scope of this sentence. **This section is the measure of the whole document, not the property of one chapter**: whichever clause in any chapter asks for a smaller functional surface or a firmer structural surface is one of its landing points — you need not see the word "entropy" in every place.

- **Start minimal and usable**: deliver the simplest form that achieves the requirement first; before it works, do not introduce the next layer of complexity.
- **Every layer must be ablated** (one ablation experiment: remove this layer, then re-measure the effect): every added layer of complexity (parameters, branches, dependencies, extra layers of indirection) must have its necessity judged by one ablation — remove this layer: does the effect defined by the requirement degrade noticeably? If you cannot answer, or removing it makes no difference, delete the layer; do not keep it "just in case". **Structures such as modules, interfaces, and tests are not judged by ablation** — their necessity is decided by the criteria of §1.1, §1.2, and §11 respectively; whatever is required by a **non-exemptible clause** (all of L1, and L2 clauses marked M, such as §1.3's separation of computation and infrastructure) is always kept. **Where the two readings are ambiguous, treat the layer as subject to ablation.**
- **Never invent requirements for the user**: function and form are defined by the user. The "more general / more complete / more elegant" that the user did not ask for is not a requirement — it is over-execution.
- **Add one at a time**: after the first version is delivered and the user confirms it, add only one function or form at a time, and only one that the user explicitly asked for.
- **Structure may be reserved; shells may not**: **structure** may be reserved — interfaces, boundaries, naming; **shells** must not be reserved — config items, extension points with no consumer, empty directories, placeholder sections. **A shell is not structure**: it looks like structure but adds functional entropy.

**Before delivery, ask the reverse question once more: delete which half and the user would still call this what he asked for?** Whatever still stands is, by the criteria of this section, over-execution.

**Must be true.** Every statement made to others (users, colleagues, AI) — documents, conclusions, reports, status — must be consistent with the facts: what is unverified must not be written as verified, and what you do not know must not be written as no problem. In §17.7 "Obligation One: explicit status", the rule that "items not yet verified must not be counted toward the usable total" is its landing point in functional descriptions.

**User-readable.** Someone who does not participate in development must be able to answer from `docs/` alone: what this is, how to use it, how far it goes, and where the boundary is. §17.2 and §17.7 are its landing points.

---

# Layer 0: Project Classification and Compliance Scope

The BADGE Constitution classifies projects into three categories, each with a different scope of applicable clauses. The clauses of this constitution **take Python projects as the reference implementation**: L1 is language-agnostic and can be applied by analogy; **L2 clauses take the trigger condition (project form) as their applicability precondition, not "whether it is Python"**; L3 is replaced with the language stack (when this constitution template is adopted, check against the template). Non-Python projects are judged clause by clause by Layer 0 "Applicability Criteria".

## Three Project Categories 〔L2·M｜all·unconditional〕

- **Category A (open-source Python project)**: public repository, community-facing. The full text of the constitution applies (§1–§20; §6 reproduction takes effect according to its applicability precondition and the effect defined by the requirement, see §6); among them **an L3 example-class clause serves as a basis for checking only when you decide to adopt that template**, and not adopting it does not affect compliance.
- **Category B (closed-source Python project)**: private repository, internal-team-facing. Except for the explicit relaxations listed below, the remaining clauses of this constitution apply; Category B judges exemptions clause by clause by the litmus test of each category (see below), and **the numbers below are only the instances currently confirmed** — newly added or revised clauses enter and leave by their own applicability conditions, neither inheriting automatically nor being excluded automatically: bilingual README exemption (§17.1, effective per §17.6), config format as recommendation rather than mandate (§7), the graded exception for non-credential company-internal information (§15.4, limited to projects not pushed to a public repository). Among them the mandatory core is security (§15), foolproofing (§2), and reproducibility within the scope of §6.
- **Category C (other infrastructure projects)**: projects belonging to neither Category A nor Category B (determination in "Classification Determination"). **Must comply with: all of L1, and the L2-M clauses hit by the trigger condition**; the parts marked L3 in §1–§5 **serve as no criterion** (checked only when you adopt that template). §6 reproduction takes effect according to its applicability precondition, see §6. In addition, the following clauses **are judged by their own markers (layer/modality/category/trigger)**: §11.5, §15, §15.4, §16, §17.3–§17.5, §17.7, §19.1–§19.3, §21.2. **The conservative default that "the remaining clauses of §7–§21 do not apply by default" is retained**.

**Form triggers.** Where a clause carries a trigger form, it applies if the form actually exists in this project. **The category field is a constraint**; whether it vetoes is decided by "Applicability Criteria". The two are not mutually exclusive. **The trigger-form vocabulary is in §21.1 "Marker Syntax"** (e.g.: code / container / optional tiers or quantified claims). Form determination is done by the maintainer; machine checking only checks "whether a clause carries an annotated condition", not "whether the condition holds".

**Classification decides the scope of a clause's application and does not change how §6 reproduction is judged**: across all three categories, §6 reproduction only asks "will it run a second time, and does the second run have to be the same", and judges by the effect defined by the requirement.

## Classification Determination 〔L2·M｜all·unconditional〕

The project has a `pyproject.toml` and builds a Python package → Category A (public repository) or Category B (private repository). Otherwise → Category C. If it is not A or B, it is C. The category is only the default landing point; **hitting a form makes the corresponding L2 clause apply** (whether category vetoes is decided by "Applicability Criteria").

## Conflict Resolution Framework 〔L1｜all〕

When the project's current state conflicts with a constitutional clause, use the three-question framework:

1. What is the project's core objective?
2. How does this project align with BADGE design principles and philosophy?
3. Does this constitutional clause help achieve BADGE design principles and philosophy, or does it impose an unnecessary burden and violate the project's core objective? Is this restriction reasonable?

## Litmus Tests by Category 〔L1｜all〕

**Category A litmus test**: Is this clause necessary for the open-source community?

**Category B litmus test**: Is this clause about making the team safer and more efficient, or about satisfying the open-source community? The former must be kept; the latter may be relaxed.

**Category C litmus test**: Is this clause a concrete engineering embodiment of BADGE design principles (**all of L1, plus the declared L2-M clauses**), or is it a detailed requirement of Python software projects? The former must be complied with; the latter may be exempt for Category C; the parts marked L3 serve as no criterion (checked only when you adopt that template). §6 reproduction does not participate in this determination; it takes effect according to its own applicability precondition (see §6).

## Applicability Criteria 〔L2·M｜all·unconditional〕

Whether a requirement holds for a certain project is judged in order, without skipping steps:

1. **Look at the layer**: what is marked L1 always holds and cannot be waived; what is marked L3 is not a requirement, and is checked against only when the project declares adoption of that template; what is marked L2 goes on to the judgment below.
2. **Look at the form trigger**: the trigger form marked on the clause must **actually exist** in this project. "There may be in the future" and "support is planned" do not count as existing.
3. **Look at the category (the category is a constraint, not a remark)**: the category marked on a clause is a **veto item** — when marked `A/B`, a project not belonging to that category does not apply; when marked `all`, the category constitutes no veto; when it is marked `self`, the clause applies **only to this constitution repository** and takes no part in the Layer 0 classification — every other repository is out of scope. The category is determined by the maintainer, passed in by machine checking via `--class`, and **not written into project files**.
4. **Look at the exception carried by this clause**: where the clause itself or a clause it references states an exemption condition, the exemption is applied once the condition holds.

**All three hold at once for it to apply: form holds ∧ category includes ∧ this clause has no applicable exception.** Layer 0's "Category C does not apply the remaining clauses of §7–§21 by default" is a **conservative default**, which a clause marked "all·some form" lifts according to that form (it applies if the form actually exists); but **a clause marked `A/B` does not enter Category C because the form exists**.

**When in doubt, treat it as holding.** Default to strict: forgetting to declare, or being unable to state the form clearly, never makes checking looser. **The determination result is not persisted** — the project is not required to add an "applicability declaration file"; one more list to maintain is one more source of truth that will go stale (§1.4). This clause changes no clause's substantive requirement; it only decides whether that clause lands on a certain project.

## Compliance Detection 〔L2·M｜all·unconditional〕

Project classification is not hardcoded inside the project. When running the compliance detection script, pass the classification in via a command-line argument (e.g. `--class A`) to adjust the detection level flexibly. Tools **must not** treat one category's implementation (e.g. `uv.lock`, directory templates) as a criterion for all categories; where a clause carries no trigger condition, the tool handles it as the strictest (all·unconditional).

## Configuration Format: TOML First 〔L2·R｜all·config-files〕

**When the project has configuration files**, carrying configuration in TOML is recommended (**a recommended practice**; not doing it does not constitute non-compliance; existing YAML/JSON projects are not forced to migrate). Projects without configuration files do not apply.

---

# Layer 1: Design Philosophy

## I. Boundary Thinking

The boundary is the first step of system design. From the network boundary between services down to the parameter boundary between functions, where the boundary is drawn decides the system's complexity distribution, testability, and extensibility. Draw the boundary first, then fill in the implementation.

### 1.1 Module Boundaries: One Thing Well 〔L1｜all〕

Each module does only one thing and does that thing well. If a module's responsibility cannot be stated clearly in one sentence, it should be split. A module's internals may be very complex, but the boundaries between modules must be clear and simple. **This is structural entropy** — complexity inside a module does not raise the maintenance cost; complexity that crosses a boundary does.

**The practical effect of a good boundary:** When modifying upper-layer code, you do not need to open lower-layer files — you only need to know the lower-layer module's interface and responsibility, without reading its implementation.

**Judgment criterion:** Can you, without looking at the code, accurately state its responsibility from the module name and interface signature alone? If not, the boundary is not drawn clearly. When modifying one module, does the number of downstream files you need to open approach zero? If not, the boundary still needs reinforcing.

### 1.2 Interface Boundaries: Stable Abstractions, Swappable Implementations 〔L1｜all〕

Modules communicate through stable abstract interfaces and do not depend on each other's concrete implementation. To add any new kind of implementation — just implement the interface and register it (**this is a technique example, not a criterion**) — without modifying any existing code. Open for extension, closed for modification.

**Judgment criterion:** How many lines of existing code must change to add one implementation? If it is more than 0 lines, the interface boundary needs redesigning.

### 1.3 Layer Boundaries: Computation and Infrastructure Separated 〔L1｜all〕

There are only two kinds of code: one does **computation** (algorithms, business rules, data transformations), the other does **infrastructure** (access to external resources such as hardware, networks, file systems, and databases). Computation code depends on no infrastructure — it can run single-threaded locally, be tested on its own, and be reproduced in any environment (same input, same output). Infrastructure code is responsible for connecting computation results to the real world.

This idea comes from big-data distributed systems such as Flink and Hadoop — do not make engineers worry about business logic, low-level implementation, and infrastructure all at once. No one can do all three well at the same time.

**Judgment criterion:** Can you run the tests of the core computation without starting an **external acceleration device**, without connecting to the network, and without reading files (e.g. without starting a GPU)? If not, the layers are not separated.

### 1.4 Data Boundaries: Single Source of Truth 〔L1｜all〕

Every piece of information has **exactly one** authoritative source in the system. Configuration has exactly one authoritative entry point (single source of truth); no environment-variable fallback chain (the narrow exceptions for environment variables are in §7.1). State is maintained in exactly one place; no multi-replica synchronization. Data flows in only one direction; no callbacks, no circular dependencies.

"This value can come from three places" sounds flexible, but in practice it leaves the user changing a parameter and not knowing why it does not take effect.

**Judgment criterion:** If someone asks "where does this value come from", can you give the unique answer within one second? If not, there are too many sources. **Duplication is structural entropy**: every additional editable copy is one more place that can drift.

> The extension of this principle in the deployment process: **when the project has a deployment machine or a deployment process**, the code on the deployment machine has only one source, the development machine (see §14.4).

> The extension of this principle in documentation landing points: **every piece of information needs only one authoritative source, not a document for every piece of information.** When some piece of information is implemented by code, **the code is its authoritative source** (§1.6) — check scripts, tests, config schemas, and `--help` are naturally versioned and naturally reviewable, so the problem of "a second document that is not versioned" does not exist, because there is no second document at all. The only form that violates this principle is: **the same piece of information exists both in code and in an independently editable explanatory document, and both can be treated as authoritative** — the solution is to **eliminate the second one** (push it down into code, or delete it), **not to add a directory**.

> **Documentation must have a unique landing point, and must not be editable in two places.** Where the landing point is is decided by the project's form: per this constitution's directory convention, repository documentation lands in `docs/` (§17.2) with no separate documentation directory — **`docs/` is an example landing point** (L3, applicable when that directory convention is adopted); other forms follow the project's own documentation layout (e.g. `man/`, `share/doc/`) — the only criterion is "unique landing point, not editable in two places". Content facing neither users nor acceptance lands in `.local/` (§16.2) or in code comments (§1.6, with the carrying method decided by the project); **the `.local/` item is L2-M and is not downgraded by this paragraph** — it is the physical boundary of "internal-network information does not enter the repository".

### 1.5 Task Boundaries: Decomposition Is Execution 〔L1｜all〕

Module boundaries constrain code structure; task boundaries constrain the development process. The same principle: **one task does one thing; finish one thing before starting the next.**

Facing a complex problem, human instinct is to "solve all problems at once", and the result is context bloat, declining decision quality, and unverifiable intermediate states. Principle: a complex problem must be decomposed into independent sub-tasks with clear boundaries — each sub-task has explicit input, verifiable output, and no dependence on other sub-tasks' internal state.

**Rule:** A sub-task must be completable independently and produce a verifiable result. Tasks communicate through explicit input/output interfaces and do not share implicit state. The caller must be able to judge whether the task succeeded solely from the output result.

**Technique (AI-assisted development):** Split a large task into several concrete, single-responsibility sub-tasks, dispatch them in parallel to agents for execution, each producing an independently verifiable result, and aggregate at the end. Effect: saves context window, yields more detailed output, shortens total elapsed time, and each sub-task's correctness can be verified independently.

**Granularity fit:** The granularity of decomposition is decided by task complexity — simple tasks are not split by force. For execution-level assessment and path selection, see the Preamble "Execution-First Principle".

**Judgment criterion:** Can a sub-task be completed independently and produce a verifiable result without depending on the context of other sub-tasks? If not, the split is not fine enough. After the task completes, can the caller judge whether the task succeeded solely from the output result? If not, the output boundary is unclear.

### 1.6 Documentation Boundaries: Details in Comments, Structure in Docs 〔L1｜all〕

In the AI era, code is the first document — AI reads and writes code directly, and maintaining a detailed architecture document kept in sync with the code is both expensive and inevitably stale. The dividing line between architecture documentation and code comments is itself a boundary decision:

- **Architecture documentation**: for humans and AI. It writes module boundaries, responsibilities, and interfaces, with architecture diagrams, flow diagrams, data-flow diagrams, and swimlane diagrams — after reading it you know how the system works. It contains no implementation details.
- **Code comments**: for AI. First, explaining the logic and design rationale of key code (why it is designed this way); second, the responsibility declaration at the head of the file — drawing a clear boundary for the code file so that AI does not pile unrelated methods and classes into it during modification (this is a foolproofing device, see §2). **The requirement for the file-head responsibility declaration is in §12.4**; the trigger condition, exemptions, and judgment criterion are defined only there.

**Judgment criterion:** Can the architecture documentation explain how the system works without containing implementation details? If not, the details have not been pushed down into comments. (For the judgment criterion of the file-head responsibility declaration, see §12.4.)

---

## II. Foolproofing Design

**Foolproofing means the system does not allow people to make mistakes.** It does not rely on developers being careful, nor on users reading the docs closely — both guarantees fail under pressure.

### 2.1 Contracts as Foolproofing 〔L2·M｜all·code〕

All interactions on boundaries are constrained by **verifiable contracts**, not by conventions and tacit understanding — these are not "best practices", they are "foolproofing devices": the person writing code does not make mistakes because he is careful, but because the system does not allow him to make a mistake.

**Language-stack landing points (examples, not criteria):** pydantic models validate config fields, ABC abstract classes force subclasses to implement hooks, type annotations let the type checker (mypy) check the data flow; non-Python counterparts are JSON Schema, Protocol, trait, and type checkers. Replace them with counterparts of the same kind while the meaning is unchanged.

### 2.2 Explicitness as Foolproofing 〔L2·M｜all·code〕

There is no magic in the code. State is explicit, data flow is visible, dependencies are declared. Implicit behavior is the biggest obstacle to understanding code — for humans and AI alike. When everything is explicit, errors surface at the earliest possible point.

**Applicability condition: Python projects — three prohibitions.** Do not concatenate paths from strings; do not pass `**kwargs` all the way through (which makes the origin of parameters untraceable); do not use `hasattr` to probe **your own project's** business interfaces (that means the interface contract is unclear, and ABC or Protocol should be used to define explicit interfaces).

**Reasonable use of `**kwargs`:** In the adapter pattern for ABC abstract methods, `**kwargs` as an extension point is allowed — different subclasses may need different domain parameters, and the base class should not modify the interface for each subclass's special needs. The key: `**kwargs` must explain in the docstring the additional parameters subclasses may accept, so the caller knows what to pass.

**Reasonable use of `hasattr`:** The following three scenarios allow `hasattr` (both the prohibition above and this exemption apply only to Python projects):
1. **Runtime capability detection**: detecting whether the runtime environment supports a feature — more reliable than parsing version numbers
2. **Cross-version compatibility handling**: handling the case where upstream libraries of different versions return different types of output
3. **Duck-typing type determination**: determining an object's type affiliation without introducing a hard dependency

**Null values: a unique representation (L1, language-agnostic).** "Absent / not provided / invalid" must have a unique representation, and must not be confused with a real value — otherwise the user cannot tell "is it an invalid value or a real value", and the type checker has no way to find a missed check (validation in §2.3).

**Applicability condition: Python projects — `None` is the only legal null value.** Using non-None values such as `0`, `-1`, `""`, `[]`, `{}` to express "absent/not provided/invalid" semantics is prohibited. None is the only value in Python's type system with "null" semantics; using other sentinel values bypasses the type checker's null detection and introduces the ambiguity of "is it an invalid value or a real value". None has no such ambiguity.

**Exception:** The natural zero point of a numeric value does not belong to "null value" semantics and is not subject to this constraint. Using another non-None value as a sentinel is allowed only when that value has clear, irreplaceable semantics in the domain and cannot be expressed with None. Such exceptions must state the reason in a comment.

**Applicability condition: Python projects (when configuration uses TOML) — serialization-boundary exception:** TOML has no null literal. In base configuration, `""`, `0`, and `[]` are allowed to mean "not provided", but **only at the serialization/deserialization boundary**, and on loading they must immediately be normalized to `None` before entering business code (see §7.1). This exception does not apply to semantic expression inside Python code.

**Applicability condition: Python projects — `= None` must be paired with an optional type annotation.** When a parameter or attribute defaults to `None`, the type annotation must be written `X | None` (i.e. `x: str | None = None`, not `x: str = None`). The type annotation is part of the contract — `str = None` tells the type checker "this value is always a str", but at runtime it may be None; this is a self-contradictory contract.

**Applicability condition: Python projects — null checks:** When checking the value of an optional type (`X | None`), use `is None` / `is not None`, not `if not x`. `if not x` treats `0`, `False`, `""`, and `[]` all as "empty", causing logic errors. `is None` matches None precisely, with no semantic ambiguity.

**Judgment criterion (the first half is language-agnostic; the last three items apply only to Python projects):** Does the code use non-None values such as `0`, `-1`, `""` as "empty/invalid" semantics? If so, does each have a comment stating the reason? Are all `= None` defaults paired with an `X | None` annotation?

### 2.3 Boundary Validation as Foolproofing 〔L1｜all〕

Data must be validated when crossing a boundary — **typical boundaries**: configuration loading (validate all fields, reject unknown fields, check required items), external requests and responses (validate the format before sending, validate the structure on receipt), artifact writing to disk (check before writing whether existing data would be overwritten and whether sensitive information would leak; applicable when so). Errors are intercepted at the boundary, so that illegal data does not flow inward and sensitive data does not flow outward.

Boundary validation rejects an illegal request — this is not a "fallback", this is a "defense line".

### 2.4 Operational Foolproofing 〔L2·M｜all·unconditional〕

**Principle:** A destructive operation must, before execution, let the operator see "what is about to happen". A deletion command must not rely on the implicit expansion of wildcards — the result of wildcard expansion is invisible to the operator before execution, and this is the root cause of accidental-deletion accidents. The way to foolproof is not to trust the operator's caution, but to make it impossible for the operator not to see.

**Rule:** Before executing any deletion command, you must first list the targets to be deleted with a listing command; after confirming they are correct, delete them item by item using specific names. **Using wildcards in deletion commands is strictly prohibited** (`*`, `?`, `[...]` and other shell glob patterns).

**Technique (handling the wildcard exception):** When the number of files to delete is genuinely large and a wildcard is truly needed, output the complete deletion command to the user, who reviews it manually and then executes it themselves. AI assistants must not automatically execute deletion commands containing wildcards. This is not a question of judgment, it is a design constraint — not distrusting the driver, but giving no one the chance to make a mistake.

**Judgment criterion:** Before executing a deletion, can you name every single target about to be deleted, item by item? If not, the operation does not comply with this clause.

---

## III. Fallback Design

Fallback is a core principle: **degradation may change the cost, but must not change the result.**

**Common dividing sentence (common to the three fallbacks in this section): the criteria are set by this section, and the concrete form is determined by each project according to these criteria.** Which channel is used to notify, logs or metrics, what level, what the config key is called — all are chosen by the project according to its own form; replacing them with a form of the same kind while the criteria stay unchanged does not count as a violation. By the same reasoning it can be cited as the dividing standard for §1.4 (documentation landing point), §4.1 (startup script naming), and §6 (reproduction mechanism landing point).

### 3.1 Same-Result Fallbacks 〔L1｜all〕

**Criterion:** A degradation that keeps the result unchanged and only changes the cost (time, resources, speed) may be executed automatically by the system, without notifying the user. The concrete form is determined by each project according to this criterion (see the common dividing sentence in this section).

### 3.2 Transparent Fallbacks 〔L1｜all〕

**Criterion:** When the result may be affected, the system must clearly inform the user, and the user judges for themselves whether intervention is needed. The notification only needs to go through **any channel visible to the user** — logs, metrics, etc. are examples, not a closed list (see the common dividing sentence in this section).

### 3.3 Pre-Authorized Fallbacks 〔L2·M｜all·unconditional〕

The result will change significantly, and the user must **declare acceptance in advance** in configuration; off by default. This is not a runtime decision, it is a pre-deployment decision.


The constitution does not prescribe specific config key names — each project defines its own switch. The principle is: if the result changes significantly, the user must say "yes" before deployment, rather than discovering it only afterwards.

### 3.4 Fallbacks vs. Defense Lines 〔L1｜all〕

A rejection that belongs to boundary validation is not a fallback, it is a defense line; a degradation that changes the result while the user is unaware is a bad fallback.

---

## IV. Zero-Step Onboarding

After a new user clones the project, the fewest commands are enough to see the output result. No additional system dependencies need to be installed (**if distributed as an image, write it into the image**), no manual configuration is needed (the default values are production-grade reasonable values), and no understanding of the internal architecture is needed (**if distributed as example configuration**, copying it once is enough).

**Zero-step does not mean zero configuration; it means the default configuration is the usable configuration.** **For projects with configuration files**, the default configuration is the production-grade reasonable value. If the user must understand the meaning of 10 parameters before starting, that is a failure of zero-step.

**Judgment criterion:** How many steps does it take for a new user to go from clone to seeing the first output result? More than 5 steps (**an empirical value, an example**) is a reason to reconsider.

### 4.1 Startup Script 〔L2·M｜all·startup-script〕

**Scope of application: when the project needs no shell wrapper there is no startup script, and this section does not apply** (e.g. a documentation-only repository; a project where `pip install` followed directly by `python -m project` works also does not need `run.sh`).

**Principle:** If the project needs a shell script as the user entry point (wrapping Docker startup, environment-variable setup, CLI parameter passing, etc.), that script must be placed in the project root directory so the user sees it at a glance, without having to search the directory tree.

**Rule:**
- **At most one** startup script in the root directory (build scripts do not belong to the "startup script" of this clause, see §10.2, §14.3); **`run.sh` is the L3 recommended name — renaming it does not constitute non-compliance**. This is the project's first interface to the user — after cloning, it is visible with `ls`.
- This script is part of the user contract and is subject to the institutionalization criterion of §10.2: it is referenced by the README and used repeatedly by workflows, so it belongs to a stable interface, and its parameter signature must not be changed casually.
- The CLI parameters passed by this script must obey the three principles of §10.1 — pass only input-locating parameters, runtime-environment parameters, and run-boundary parameters (for the definitions and determination of the three kinds, see §10.1). All parameters that affect the artifacts must go into the config file and must not be hardcoded in `run.sh`.
- The startup script and developer temporary scripts **must be distinguishable**: this script does not belong to the scope of the `scripts/` directory (§10.2) — `scripts/` holds developer-facing temporary tools, while the startup script is a user-facing stable entry point. This project draws the line with `scripts/`; other forms may draw it in other ways; the criterion is that the two are not mixed.

**Technique:**
- Minimal implementation of `run.sh`: set the necessary environment variables, then start with `python -m <package>`, and pass `--config` through to the user.
- If the project also has Docker deployment (§14.3), `run.sh` may wrap the `docker run` command, so that the user can start it without knowing Docker details.

**Judgment criterion:** After a new user clones the project, can they discover the startup entry point **without reading the README and without entering a subdirectory**? Seeing the startup script at a glance with `ls` is a pass (**`run.sh` is only an example name**). If they must `cd scripts/`, leaf through the README, or search to find it, that is a failure.

### 4.2 Startup Script Localization 〔L2·M｜A/B·startup-script〕

**Principle:** `run.sh` should run in any deployment environment without modification.

**Rule:**
- Localization is preferably done through `run.sh`'s own parameters (CLI parameters, see §4.1, §10.1), or through a local override file under `.local/`; environment variables are not treated as a regular source of project configuration (the narrow exceptions for environment variables are in §7.1).
- When localization is needed, the user creates a local override script under `.local/` (**`run.local.sh` is an L3 example name; renaming it does not constitute non-compliance**), which calls the base startup script with explicit parameters. The base startup script remains the authoritative, portable entry point.
- The local override script is a localized variant — it **must** be gitignored, do only parameter forwarding or value overriding, and not copy the base logic (all three are M; the file name is decided by the project).
- Only when a third-party component (e.g. a Docker/container interface) accepts nothing but environment variables may `${VAR:-default}` be used inside that adapter boundary; such usage must be centralized, explicit, and commented, and must not be scattered across the project.

**Technique:**
- Recommended pattern: `run.sh` defines paths and settings with script variables carrying default values and exposes the corresponding `--xxx` parameters; `run.local.sh` calls the base `run.sh` with explicit parameters.
- If some third-party tool can only be configured through environment variables, export those variables in `run.local.sh` and mark "third-party adapter" in a comment, while ensuring that the base `run.sh` does not depend on them.

**Judgment criterion:** Can a new deployment environment start without editing `run.sh`? If environment variables must be set first, is it confirmed that this belongs to the third-party adapter scenario allowed by §7.1, with clear records and reasonable default values?

---

## V. Correct First, Optimize Later 〔L1｜all〕

Performance optimization is necessary, but must not come at the cost of correctness and maintainability. The principle is: **guarantee correctness first, then pursue performance. But do not design an architecture that cannot be optimized.**

The separation of computation and infrastructure already provides a natural foundation for performance optimization — the core algorithms can be tuned independently, without being coupled to distributed communication or I/O. The stable abstraction of interfaces guarantees that replacing an inefficient implementation does not affect the upper layer. If, for the sake of "elegant code", several operations that should be executed independently are coupled together, so that later, when you want to parallelize them, you find they simply cannot be separated, that is over-design — it sacrifices the room for optimization and buys nothing in return.

**Judgment criterion:** If you find that a component is a performance bottleneck, can you replace it without changing upper-layer code? If not, the architecture needs to be reviewed again.

---

## VI. Reproduction: The Effect Defined by the Requirement 〔L2·M｜all·unconditional〕

**When reproduction is needed:** Only when this result **needs to be run a second time in the future, and the second result needs to be consistent with this one**, is reproducibility pursued; otherwise reproduction is not pursued — no reproduction-specific mechanism is added, and bit-for-bit consistency is not pursued for tasks whose fluctuation is allowed; the mandatory force of mechanisms such as §14.2, §14.3, and §8.5 is independent of whether reproduction is needed, and each takes effect according to its own scope of application. The judgment is one sentence: **Will it run again? Does the second run have to be the same as this one?**

**What counts as reproduction: the effect defined by the requirement is achieved again.** Reproduction has no fixed threshold — the meaning of "consistent" is decided by **the effect defined by the requirement**. First clarify what the requirement wants, then judge on that basis whether reproduction holds:

- The requirement is "the result is completely correct" → only complete consistency with the correct answer defined by the requirement counts as reproduction;
- The requirement is "the picture looks the same" → looking the same is reproduction;
- The requirement is "the task is completed" → task completion is reproduction;
- The requirement is "a certain metric is reached" → the metric being reached is reproduction; and other **statements of the same kind (etc.)** — the four above are typical statements, not a closed list.

The key is **first clarifying what the effect defined by the requirement is**. When the requirement does not define "consistent", do not default to executing at the strictest degree (e.g. bit-for-bit consistency) — that may both exceed the requirement and drag a task that is allowed to fluctuate into pointless cost. Fluctuation itself is not a defect: as long as the effect defined by the requirement is achieved, that is reproduction. When the requirement is undefined, **do not unilaterally presume a threshold**: first clarify with the requirement owner "what effect counts as achieved"; before that clarification, do not take "no errors" as the default criterion for having reproduced; neither default to the loosest, nor default to tightening at the strictest degree — tighten only when the requirement explicitly demands stronger consistency.

**How to achieve reproduction: use this constitution's existing engineering mechanisms to make "running it again" achieve consistency conditionally.**
- **Pin dependencies and environment to definite versions (M):** interpreter/runtime version, dependency lock file, the concrete version of the run carrier (use digest for strong determinism) — this clause only requires "attach to a definite version" and **does not prescribe specific tools**. **The following are examples (L3):** for Python projects, `uv` + `uv.lock` (§14.2) + `.python-version`, with the run carrier locked to a concrete version tag per §14.3; other forms use their own locking mechanisms (npm/yarn lock, apt version pinning, upstream commit pinning, etc.)
- Version management: code and configuration go into git, and the code comes from a definite commit (the artifact is additionally decided by config and seed) (§14.4, §17.4)
- Explicit configuration: parameters that affect the artifact go into the config file (§10.1); if the task contains randomness and its effect is sensitive to randomness, the random seed is explicitly set in the configuration, not relying on system time or hardware state
- Artifact archival: the configuration of each run is backed up together with the artifact (§8.5), and when needed it is recorded together with this run's criterion for "consistent" (recorded into this run's config backup or work log, §17.5)

The presence of the mechanism is verified by the corresponding check items in `tools/`, and **the coverage is per the tool documentation**.

**Judgment criterion:** Can you state in one sentence what the effect defined by the requirement for this run's "consistent" is? Calling "consistent" "bit-for-bit identical" when the requirement does not so require is over-execution; being unable to state the effect clearly means reproduction is not yet defined.

**Boundary:** The reproduction mechanism itself is also subject to the Preamble's "risk gate" — additionally building reproduction-specific gates for a result that will not run a second time, or pursuing bit-for-bit consistency for a task whose fluctuation is allowed, costs far more than it gains and is over-execution. Parameter placement is decided by §10.1; reproduction is only a means of verification (see §10.1).

---

# Layer 2: Engineering Standards

## VII. Configuration System

### 7.1 Single Configuration Entry Point 〔L2·M｜all·config-files〕

**Principle:** Configuration has exactly one authoritative entry point: a git-tracked base configuration file (**example: `config.toml`**) serves as the default configuration, segmented by functional domain, optionally overlaid with a gitignored override configuration, and after a deep merge there is only one configuration inside the code. For the recommended configuration format see Layer 0 "Configuration Format: TOML First" (R — TOML is the standard format of the Python ecosystem; `pyproject.toml` uses the same format, and the type system natively supports nested tables and arrays; not doing so does not constitute non-compliance). Except for the environment-variable exceptions this section explicitly allows, do not use environment variables to carry configuration values, and do not use CLI arguments to implicitly override the configuration file. Configuration is configuration, environment is environment — keep them clearly apart.

> The "applicability criteria" of Layer 0 above and the definition of "Python as the reference implementation" (how L1/L2/L3 each apply) hold equally for the detailed rules that follow and are not repeated here.

**Environment-variable policy:** Environment variables are an invisible, easily out-of-control configuration channel and must not serve as the single source of truth for configuration. Only these three uses are allowed: ① standard infrastructure variables — **the exact matching is defined by `tools/check_config_system.sh`** (§15.1 first-paragraph division of labor); ② when a third-party component accepts only environment variables and cannot be adapted through configuration (as that component's adapter layer); ③ genuinely tiny projects that really have exactly one configuration. Outside these three cases, environment variables must not carry configuration or path parameters (§10.1). Any configuration that enters via an environment variable must be read centrally at startup and normalized into the same configuration-loading path; ad hoc reads at usage sites are forbidden. A user's own choice to carry local secrets in `.env` is not restricted by this, but the project must not treat it as the configuration source of truth (see §15.2).

**Layered configuration pattern:** **When a project has deployment environments and needs to separate deployment values from public values**, use two-layer configuration + dict deep merge (format per the Layer 0 recommendation, TOML as the example; other formats follow their own merge semantics). Deployment configuration contains two categories of fields:

- **Secret fields**: sensitive values that must not appear in git-tracked files.
- **Environment fields**: configuration values that vary by deployment environment but are not themselves secret.

- **Base configuration** (`config.toml`, git-tracked, read by default at startup): contains **all fields** and is the **single authoritative source** of the configuration schema. Non-deployment fields have production-grade defaults. Secret fields are left empty (**the sentinel values are an L3 example**: `""`, `0`, `[]`, normalized to `None` at load time, see §2.2). Environment fields have **development defaults** (reasonable values usable locally) rather than being left empty — this ensures the project runs out of the box in a development environment.
- **Override configuration** (**recommended location (R)**: `.local/config.override.toml` — a path example; landing it under `.local/` per §16.2 is sufficient; gitignored, deployment machine only): overrides only the fields that need deployment-specific values. Copy it from the git-tracked `config.override.sample.toml` template and fill in the real values. **A field that does not exist in the base configuration cannot be added**. By default the template lists only the common fields that need overriding; when the total number of configuration fields is small, the template may directly mirror all fields for easier comparison.
- **Merge rule:** At startup the program first loads the base configuration into a dict, then loads the override configuration and **deep merges** it into the same dict — the override dict's leaf values replace the base dict's leaf values at the same path. After merging there is only **one configuration** in the program, with no ambiguity of "two configuration sources".

**Override file location (R):** The recommended override file location is `.local/config.override.toml` (example). Other locations are supported through a user-supplied explicit `--override` argument. CLI auto-detection order (**the following order is an example, not a criterion**): explicit `--override` argument → `.local/` → adjacent path (backward compatible).

**The following example (L3): field names and values only demonstrate the shape; swapping in equivalent values does not change the meaning of the clause.**

〔L3｜template-adopted〕
```toml
# config.toml — base configuration (git-tracked), contains all fields
[device]
type = "simulation"
robot_type = "general_robot"

[streaming]
encoder = "h264"
h264_fps = 30

[task.llm]
endpoint = ""                # secret field, left empty, overridden at deployment
model = "local-model"        # environment field, development default

# .local/config.override.toml — override configuration (gitignored), overrides only deployment fields
[task.llm]
endpoint = "http://10.1.xxx.xxx:8000/v1"
model = "production-model"
```

**Null-value handling — applicability: the configuration format does not support null literals (such as TOML).** TOML has no `None`/null literal. To express the semantics of "not provided" in the base configuration, use `""` (empty string). At load time the program must uniformly convert `""` to `None`. `""` is the serialized representation of `None`, not a business-meaningful empty string. For numeric and array fields, use `0` and `[]` as the "not provided" sentinels (**the concrete sentinels are examples**), and the program must likewise convert them to `None`. The sentinels themselves may be swapped; the criterion is "there is only one representation of 'not provided'" (§2.2 null values).

**Litmus test:** Does the base configuration contain all fields (none omitted)? Can you fully understand the configuration schema by reading the base configuration? Does the override configuration only override fields that already exist in the base configuration (no added fields)? After merging, is there only one configuration in the program (a single downstream consumer)?

### 7.2 Validate at Load Time 〔L2·M｜all·config-files〕

Configuration completes **all** validation at load time, not scattered validation at usage sites. A validation failure exits with an error immediately, giving a clear error message — which field, what was expected, what was actually received.

**Language-stack implementation (R, example):** Python projects are recommended to use pydantic's `extra="forbid"` to reject misspelled field names and `model_validate()` to check the types and constraints of all fields in one pass; other language stacks use their corresponding schema validators.

**Two-way consistency of the configuration contract:** The configuration file is the user-side contract and the pydantic model is the code-side contract; the two must correspond one-to-one. Every field that appears in the configuration must be defined in the model and actually used; every field defined in the model must have a corresponding configuration source. **A field that is declared but consumed by nobody is "phantom configuration"** — the user changes it believing it takes effect, while in fact nothing happens; this is more insidious than a missing field.

### 7.3 Template as Documentation 〔L2·R｜all·config-files〕

The base configuration file is itself the template and the documentation: it contains all fields, comments, and default values, and is a configuration that runs directly — adequately commented, with sensible defaults, covering 80% (**example value**) of use cases. The deployment override template shows only the fields that need overriding (or all fields when there are fewer than about 30 fields (**example value**)), using placeholders to guide deployers. File names are decided per project (example: `config.toml`, `config.override.sample.toml`).

### 7.4 Config Parameter Design 〔L2·M｜all·config-files〕

Config parameters are the boundary between the user and the system. If parameter design is poor, no amount of clear documentation helps — users will be misled by parameter names, drowned by redundant parameters, and trapped by coupled parameters. Three principles of parameter design:

**1. Do not expose useless parameters.** If a value can be derived automatically, do not make the user specify it manually. A parameter that is uniquely determined by other parameters should not exist — every extra parameter is one more chance for the user to make a mistake. `decay_steps` is the decay span of the schedule (the semantics the user genuinely cares about), so do not make the user back-infer it from the training length; `num_layers` is known once the configuration file is loaded, so do not make the user fill it in manually. The principle is: **the user only needs to specify the parameters they genuinely care about and that the system cannot decide for them.**

**2. Orthogonal parameters.** Parameters should be independent of one another — adjusting one does not change the semantics of another. If changing `warmup_steps` requires also changing `total_steps` for the scheduler to work properly, these two parameters are coupled and the design is flawed. Orthogonal configuration lets users optimize each dimension independently, without maintaining a "parameter linkage table" in their heads.

**Litmus test:** Can the user adjust each parameter independently and get a predictable result? If changing parameter A requires also changing parameter B, they are not orthogonal and should be merged into one parameter, or the system should derive one of them automatically.

**3. Self-explanatory parameter names.** Parameter names may be long, but must let the user see the meaning at a glance without consulting documentation. `learning_rate` is better than `lr`, `warmup_steps` is better than `ws`, `min_lr_ratio` is better than `min_lr` (the latter reads as an absolute LR value rather than a ratio). Abbreviations are allowed in only one case: the abbreviation is a **universally known** general term in the domain, such as `lr`, `tp`, `pp`, `lora`. But even for these terms, using the full name as a top-level parameter name in a configuration file is recommended — `learning_rate` is less ambiguous than `lr`.

**Litmus test:** Find someone unfamiliar with the project and show them only the parameter name and its comment. Can they accurately state what the parameter does? If they get the function right but the unit or range wrong, the name is right but the comment is insufficient. If they get the function wrong, the parameter name itself is ambiguous. In addition, when this parameter is changed, does the system behavior really change as expected? If nothing changes, it was never wired into the code — that is phantom configuration, not a parameter design problem.

---

## VIII. Code Organization

### 8.1 Directory Layout 〔L2·M｜all·code〕

**The following is the recommended layout (an example), not a criterion.** Satisfying the four criteria below is sufficient; the layout may be replaced with an equivalent form.

**Four criteria (mandatory, only when the project has code):** ① The source code has a single import root (`src/<package_name>/` or an equivalent form), importable within the package; ② tests have their own directory, and the corresponding implementation can be found in one place; ③ local temporary files go to `.local/` (criterion see §16, independent of whether there is code); ④ the single-source files for dependencies and version live at the repository root (see §8.7, §14.2).

〔L3｜template-adopted〕
```
project/
├── run.sh                   # startup script (present as needed, see §4.1) · as needed (when a CLI is provided)
├── config.toml              # base default config (git-tracked, contains all fields) · as needed (when there are config files)
├── config.override.sample.toml  # override template (git-tracked, placeholders) · as needed (when there are config files)
├── src/project_name/        # source code, src-layout · required
│   ├── __init__.py          # version number + public API re-export · required
│   ├── __main__.py          # python -m entry point · as needed (when `python -m` is a supported way to run)
│   ├── py.typed             # PEP 561 marker · as needed (when published as an installable package or imported by downstream)
│   ├── cli.py               # CLI entry point (upgradeable to a cli/ directory when complex) · as needed (when a CLI is provided)
│   ├── config.py            # config model definition and loading · as needed (when there are config files)
│   ├── core/                # computation layer: pure logic, zero infrastructure dependency · required
│   ├── backends/            # infrastructure layer: distributed, GPU, network · as needed
│   └── domain/              # domain logic layer (present as needed) · as needed
├── configs/                 # example configs (needed by resident services; batch/training tasks may omit it and put example configs in samples/configs/) · as needed
├── docs/                    # user-facing documentation: how to use it, the architecture, whether it works well (§17.2); includes the statement of function and capability (§17.7) · as needed
├── tests/                   # tests (directory tree mirrors the source) · required
│   ├── core/                # corresponds to source core/ · required
│   ├── backends/            # corresponds to source backends/ · as needed
│   └── e2e/                 # end-to-end tests · as needed
├── scripts/                 # one-off utility scripts (optional: may be dropped once all tools are institutionalized, see §10.2) · as needed
├── .local/                  # local temporary files (never committed, see §16) · required
├── docker/                  # Docker build · conditional (only when a container image is provided)
├── pyproject.toml           # required
├── uv.lock                  # required
├── .python-version          # required
├── README.md                # required
├── README.zh-CN.md          # as needed (bilingual projects)
├── LICENSE                  # required
└── .gitignore               # required
```

**The `configs/` directory**: projects that need resident runtime configuration should use `configs/`; projects that obtain configuration through CLI arguments may omit the root-level `configs/` and simply put example configs under `samples/configs/`. **Machine validation of the directory layout is carried by `tools/check_directory_layout.sh`, whose check items and category differences are defined by that script. This constitution repository itself is a Category C code-less repository and is not bound by this section's layout** — its landing points are the repository-root body text, `docs/`, and `tools/`; entries premised on a code project such as `src/`, `tests/`, `docker/`, and configuration templates do not apply to it.

**Directory organization principle:** The directory structure is the navigation system of the codebase, not a filing box for files. Through the directory hierarchy and file names, a reader should be able to grasp roughly what the code does, which module it belongs to, and its inheritance relationships — without opening any file. A directory should not contain more than 10 code files (**a rule of thumb, an example, not a criterion**). When it exceeds that, the directory contains multiple independently nameable sub-domains — create categorized sub-directories and group by functional domain. This is not a hard limit but a signal: when you see the 11th file, ask yourself "can this directory's responsibility still be stated in one sentence?"

> The directory layout template lists both `README.md` and `README.zh-CN.md`. For projects exempt under §17.6, a single `README.md` may be kept.

> For `__main__.py` in the directory tree above: whether it is needed is decided by the **entry-point shape** — it must be provided when the project supports `python -m <package_name>` as a way to run; it is not required when a container image is the primary delivery vehicle and a startup script (§4.1) or CLI entry point already exists. **This clause is independent of project category.**

**`cli.py` may be upgraded to a `cli/` directory:** When the CLI logic is complex enough to need splitting into multiple sub-modules (such as subcommand dispatch, training worker process entry), follow the same logic as §8.3 (class-to-directory) — `cli/__init__.py` is responsible for external transparency, so external consumers see only the `package_name.cli:main` entry point and do not perceive whether the internals are a single file or a directory.

**`domain/` may be omitted as needed:** Not every project has an independent domain logic layer. If the project's domain logic naturally coheres in the computation modules of `core/`, or if the domain concepts themselves are not yet stable enough for a separate layer, leaving it empty is better than forcing it in. The core principle of module boundaries (§1.1) is to state responsibilities in one sentence — if you cannot state what `domain/` is responsible for, it should not exist.

### 8.2 File Granularity: Neither Too Large Nor Too Fragmented 〔L2·M｜all·code〕

A file grown to thousands of lines is hard to read and modify, and the IDE is slow to open it. Split too finely, and one feature is scattered across a dozen files — the reader jumps around everywhere and their thinking is fragmented. The ideal granularity is: **one file corresponds to one clear conceptual unit**, and opening that file lets the reader fully understand that concept.

Litmus test: Can you fully understand one concept in one file? If you must jump between multiple files to piece together the whole picture, it is too fragmented. **Keeping files under 1000 lines is recommended (an example magnitude, not a criterion)** — if it is exceeded, ask yourself whether it has crammed in two concepts. But if the logic inside the file genuinely belongs to the same conceptual unit (such as a pure-function toolkit, a complex model adapter), exceeding 1000 lines is acceptable; in that case, ensure the file is internally organized by functional domain with clear separator lines and comments, so readers can locate things quickly. **Both sides of granularity are entropy**: too large is structural entropy (one concept scattered across many places, so the whole cannot be read off), too fragmented is functional entropy (the reader has to jump more times).

### 8.3 Class-to-Directory: When a Class Is Too Large 〔L2·M｜all·code〕

When a class has so many methods that a single file swells to hundreds or even thousands of lines, do not force the methods into one file — upgrade the class into a directory:

**The following is an example (one way of dividing it, not a closed list): splitting by functional domain is enough; file names and layering may all be swapped.**

〔L3｜template-adopted〕
```
backends/models/my_model/
├── __init__.py          # re-exports MyModelAdapter from adapter.py
├── adapter.py           # main class definition + template method skeleton
├── forward.py           # forward-pass-related methods
├── generation.py        # generation-related methods
├── checkpoint.py        # save/load-related methods
└── helpers.py           # pure-function utilities
```

**Principle:** The **skeleton file** (for example `adapter.py`) keeps the class skeleton — `__init__`, template methods, abstract methods. Each file split out by functional domain contains one group of related methods of that class. External consumers only import the class name and are entirely unaware whether the internals are a single file or a directory. `__init__.py` is responsible for this "external transparency".

If internal methods need to share state, they access it through `self` — they are still methods of the same class, just physically spread across different files. Pure functions that do not need `self` state go into the pure-function utility file (example name `helpers.py`); they are independent and separately testable.

File names inside a class directory do not have to match the class name — the directory name carries the location of the domain (the body of the class name), and the internal files are named by functional domain (§12.2 mutual mapping of class names and paths).

### 8.4 OOP and FP Each Play Their Part 〔L2·M｜all·code〕

Object-oriented and functional programming have argued for decades about which is better. The answer: **they are not rivals, they are tools.** The key is to let each do what it is good at.

**OOP is good at:** scenarios that are stateful, have a lifecycle, or have multiple implementations needing a uniform interface. Class inheritance expresses "the same kind of thing, different ways of implementing it". Template methods let the base class control the flow while subclasses fill in the differences.

**FP is good at:** scenarios that are stateless, purely computational, or data-transforming. A function takes input, returns output, and has no side effects.

**Do not do OOP for OOP's sake:** If a piece of logic does not need `self` state, do not force it into a class. A standalone pure function is clearer, easier to test, and easier to reuse than a class with only one method.

**Mixed usage inside a module must be graded:**

The following mixed usage is **benign mixing** and needs no splitting:
- The file defines frozen dataclasses used only as function return types, together with pure functions that operate on those dataclasses — they naturally cohere.
- The file is mainly a set of pure functions, and the "classes" interspersed in it are essentially small data structures (typed tuples, frozen containers) rather than stateful service objects — they naturally cohere.
- Multiple classes of the same family share one file — they have the same responsibility, and keeping them together is reasonable.

The following mixed usage counts as **mixing that needs splitting**:
- A stateful, lifecycle-bearing service class sits next to unrelated standalone functions — they should be extracted into a helpers module.
- Complex state-management classes are mixed with pure computation functions, so the reader cannot tell at a glance the scope of the functions' side effects.

**Litmus test:** Can the reader tell at a glance whether the functions in this file have side effects? If you see that the file contains a class and cannot tell whether the functions depend on the class's state — that is **mixing that needs splitting**, and it should be split.

### 8.5 Output Directory Isolation 〔L2·M｜all·data-artifacts〕

This section applies to runs that produce on-disk artifacts. Source code and data are assets; run artifacts are consumables. The two must be physically isolated — the output directory is not inside the source tree, and is specified by the `output` field of the configuration file. The default value points to `outputs/` under the project root, and this directory is excluded in `.gitignore`.

**The following is an example (L3): the directory names and layering only demonstrate the shape; swapping in equivalent shapes does not change the meaning of the clause.**

〔L3｜template-adopted〕
```
outputs/<run_name>/
├── config.toml           # configuration backup of this run (artifact description, §10.1; reproduction use see §6)
├── checkpoints/          # model checkpoints
├── logs/                 # logs split into files by functional domain
└── results/              # final outputs (datasets, models, evaluation results)
```

**Every run must generate a unique `run_name`** (by default based on a timestamp) to prevent accidental overwriting; **the configuration used by this run must be backed up together with the artifacts** (M — independent of the directory tree shape above; the backup file name and location are decided per project). After the run finishes, the user can reproduce this run's effect as defined in §6 from the configuration backup under the artifact directory — no need to go back and find the original configuration file. The backup file uses the same format as the project's original configuration (for a TOML project, `config.toml`).

### 8.6 Imports and File Headers 〔L2·M｜A/B·code〕

Use absolute imports uniformly; relative imports are forbidden. `from __future__ import annotations` (PEP 563) is used only when circular imports prevent type annotations from being evaluated, and is not required in every file. In Python 3.11+ projects the `str | None` syntax is natively supported and `TYPE_CHECKING` guards already handle most circular-import scenarios, so there is no need to add boilerplate at the top of every file. `__init__.py` is responsible for re-exporting the public API, so that external consumers need not care about the internal file structure.

### 8.7 Version Number: Single Source 〔L2·M｜A/B·versioned-releases〕

**When the project is released as an installable Python package**, the project's version number **is derived automatically from git tags via `setuptools-scm`**, and `pyproject.toml` declares `dynamic = ["version"]`. This is a reinforced expression of the constitution's §1.4 (single source of truth) and §2.1 (foolproof design):

- `[tool.setuptools_scm]` in `pyproject.toml` configures the version-derivation rules (tag format, prefix, etc.); this is the **only configuration source** of the version mechanism
- The actual version string is in no file — it is derived from `git describe --tags`; at release time `git tag vX.Y.Z` is all it takes
- **Forbidden** to define `__version__` in `__init__.py` — in effect there would be two sources of truth
- **Forbidden** to write the version number in configuration comments (`config.toml`, `config.override.sample.toml`) — configuration files are for users, not a version log
- **Forbidden** to hardcode a version string in the code

At runtime the version number is obtained through the standard library's metadata interface; users can see the version via git tags or the package manager.

**Why not use the `version` field of `pyproject.toml`?** Because `pyproject.toml` would then carry two completely unrelated pieces of information: the version number and the dependency declarations. If the version number is hardcoded in `pyproject.toml`, changing the version during a Docker build changes the file hash, invalidates the dependency-layer cache, and forces all packages to be downloaded again. `setuptools-scm` + `dynamic = ["version"]` decouples the version number from the file into git tags — `pyproject.toml` contains no version string, and a version change does not change the file hash, so `pyproject.toml` can be safely placed in the dependency layer without triggering a dependency rebuild. A version change affects only the source layer (`COPY src`), while the dependency-layer cache is fully reused. This is the result of §1.4 (single source of truth) and §14.3 (Docker layer caching) working together.

**Litmus test:** How many files must be changed to make a release? If the number exceeds 0, this clause is violated.

---

## IX. Data and Interfaces

### 9.1 Data Contract: Explicit Schema 〔L2·M｜all·code〕

Business data must have an **explicit schema** and must not be passed in anonymous containers — carrying business data structures in bare `dict` or `list` is forbidden; nested structures use nested schema definitions, with no dict-of-dicts. (M, all)

**Python landing point (M, applicability: Python source code):** Core data structures are defined with pydantic `BaseModel`, and `extra = "forbid"` rejects unknown fields.

**Model purity:** Data models follow the same one-thing-one-responsibility principle as module boundaries (§1.1). A model contains only data that belongs to its conceptual scope. When unrelated metadata needs to be attached, do not add fields to the existing model — create a new model and use composition (nesting) instead of pollution.

`frozen = True` is recommended for pure data objects that are loaded from external data sources and never modified afterwards; it prevents accidental modification. But for scenarios such as configuration objects that need to be overridden by CLI arguments during the initialization phase, `frozen` is not required; in that case, ensure the configuration object is no longer modified once initialization is complete.

### 9.2 Class Inheritance: Template Method 〔L2·M｜all·multiple-implementations〕

Template method pattern: the base class defines the process skeleton (public methods), and each step calls a hook implemented by the subclass; concrete subclasses override only hooks, not public methods. **Python implementation: ABC base class + `_`-prefixed private hooks.** To extend with a new implementation, define a new class and register it, without modifying existing code.

### 9.3 Registry: Dynamic Extension 〔L2·M｜all·multiple-implementations〕

Multiple implementations of the same type are managed through a registry (a string-to-class mapping). At runtime the implementation is looked up by name and instantiated. On lookup failure, give a clear error message listing all available options. Adding a new implementation requires only one line of registration code.

---

## X. CLI Design

### 10.1 Config-Driven Commands 〔L2·M｜all·cli〕

**Principle: the config file is the sole description of run artifacts.** Run artifacts include everything written to disk as well as content output to external systems; the on-disk location is part of the artifact (output_dir and run_name are both decided by config). The only exception: content printed directly to stdout and not written to disk is not an artifact.

**Reproduction definition:** Reproduction means **the effect defined by the requirement is achieved again** (§6) — there is no fixed threshold, and the meaning of "consistent" is decided by the requirement. **Parameter placement does not depend on whether reproduction is needed**: it is decided by the principle of this section together with §1.4 (single source of truth) and §7.1 (single configuration entry point) — every parameter that participates in deciding on-disk artifacts must live in the config file; reproduction (§6) is the means of verifying that placement. Whether the config.toml backed up in the output directory (§8.5) alone can make this run's effect achieved again in a second run is the criterion of that verification.

**Corollary 1: every parameter that participates in deciding artifacts must live in the config file.** Otherwise the same config would change the effect defined by the requirement (§6) because of different CLI arguments — the one-to-one correspondence between config and artifacts breaks, and the reproduction promise of the archive in the output directory (§8.5) fails.

**Corollary 2: CLI arguments and config fields have zero intersection.** A parameter can have only one source of truth (§1.4). A mechanism where "the config holds a value and the CLI overrides it" is not allowed — override means two sources of truth. Adding a new command is allowed when it represents a fundamentally different lifecycle operation (training vs. exporting) that cannot be naturally expressed as a configuration switch, but the command itself is equally bound by this section.

**Three principles of CLI arguments (applies to all CLI commands):**
1. **Input-locating arguments**: designate input files or data — locating the input, not configuration content. The most typical example is `--config`; whether the remaining argument names belong to this category must be judged from project semantics;
2. **Runtime-environment arguments**: not written to disk, not part of the artifact, only affecting "where it runs";
3. **Run-boundary arguments**: do not produce a complete run artifact (such as smoke verification, equivalent to a restricted run, without changing run semantics).

**`--config` is the only explicitly listed argument name** — other argument names vary by project and must be reviewed item by item against the three principles above: under reproduction conditions (the same config; the same seed if the task involves randomness), does a different value of this argument change the effect defined by the requirement (§6)? If yes, it must go into config.

**Litmus test (technique):** For any argument X — under reproduction conditions (the same config; the same seed if the task involves randomness), if different values of X change the effect defined by the requirement (§6), or change the existence, location, or controllable content of any on-disk output, then X must go into config. (This criterion is independent of whether §6 reproduction is needed: participating in deciding artifacts is enough to be bound.)

**Output constraint (technique):** The on-disk output of every CLI command is decided by config — any "output-locating" argument is forbidden. Tool commands that do not participate in artifacts are equally bound, with three options: print only without writing to disk; accept `--config` and write output into the config-decided directory; or demote to a scripts/ script (§10.2).

**Foolproofing (technique):**
- CLI arguments are enumerated in exactly one place in code and locked by tests — a new CLI argument must pass a "does not change the effect" test (two runs with the same config, differing only in X, asserting that the artifacts are unaffected per the effect defined in §6: for deterministic tasks compare value by value directly; for tasks with randomness fix the seed, or compare only the parts unaffected by randomness)
- Log and record files must not contain runtime-environment metadata — they are not decided by config, are not part of the effect defined by the requirement, and belong to §16.2 environment information
- Except for the third-party adapter scenarios allowed by §7.1, custom environment variables must not carry configuration or path parameters; standard CUDA/NCCL/PyTorch infrastructure variables are unaffected; host-path injection goes through CLI arguments (e.g. run.sh `--model-dir`)
- The CLI arguments passed by `run.sh` (§4.1) are equally bound by the three principles of this clause — it is a launcher of config, not a substitute for config

### 10.2 The Boundary Between CLI and scripts 〔L2·M｜all·cli〕

**CLI is the stable user-facing interface; scripts are temporary developer-facing tools.** CLI arguments and output formats are contracts and must not be changed casually. Scripts are one-off, experimental, deletable at any time, and need no backward compatibility.

**Institutionalization criteria:** A script becomes an institutionalized interface as soon as any of the following holds, and must then be upgraded to a CLI subcommand or deleted:
- It is pinned by tests (a corresponding test exists in tests/)
- It is referenced by the README or docs/
- It is used repeatedly by workflows, with a scope beyond the developer themselves

scripts/ keeps only one-off, experimental, non-institutionalized tools. Scripts upgraded to CLI subcommands are likewise bound by §10.1 (input-locating arguments + config-decided output).

**Root-level startup scripts are not part of `scripts/`:** `run.sh` (§4.1) and `build.sh` (§14.3) are stable user-facing entry points placed at the root level and do not fall within the scope of the `scripts/` directory. Their lifecycle is synchronized with the project, and the "temporary tool" designation does not apply to them.

---

## XI. Testing

### 11.1 Toolchain 〔L2·M｜A/B·code〕

**Having Python code means there must be tests and static checks** (M).

**Default tools (R):** pytest runs tests, ruff formats + lints (`ruff format` + `ruff check --fix`), mypy performs type checking; all three are configured in `pyproject.toml`, with versions pinned in the dev dependencies. Equivalent tools may be substituted, but **versions must be pinned**.

### 11.2 Directory Structure 〔L2·R｜A/B·automated-tests〕

**For projects with automated tests**, the `tests/` directory tree is recommended to mirror the source directory tree (when the source is in `src/`, this is exactly the recommended layout of §8.1). Finding a test file requires no thought: the test for `src/project/core/schema.py` is at `tests/core/test_schema.py`. End-to-end tests go in a separate `tests/e2e/` directory.

### 11.3 Testing Standards 〔L2·M｜all·automated-tests〕

Unit tests cover public interfaces, with external dependencies replaced by mocks. End-to-end tests cover the complete pipeline. Parametrized tests cover boundary conditions. Test function names describe three elements: what was done, under what conditions, and what result is expected. Each test is independent and does not depend on execution order. For the methodology of how tests drive algorithm development, see §11.4.

### 11.4 Test-Data-Driven Development 〔L2·M｜all·automated-tests〕

For complex algorithms whose generalization completeness is extremely hard to exhaust through formal analysis, test-data-driven development is an effective alternative path.

**Principle:** Use continuously enriched test scenarios as empirical anchors for the algorithm, in place of formal completeness proofs. The richer the test scenarios, the higher the marginal cost of "cheating" a pass through hardcoded branches, and the algorithm is forced toward genuine logical generalization. But this is not "add an if for every case you see" — for each batch of newly added test scenarios, an abstraction refactor should be done so that the algorithm covers more scenarios with simpler logic, rather than stacking patches on a branching tree.

**Rule:** Adapting to test data by cheating or hardcoding is forbidden. Specifically: hardcoded branches in the algorithm targeting specific test inputs are forbidden; relaxing assertions in tests in order to "pass" is forbidden; when a newly added test scenario fails, it should be covered by refactoring the algorithm's logic, not by appending conditional branches to the existing logic.

**Technique:** Start from a small number of typical scenarios, progressively expand to boundary scenarios and exception scenarios, and after each iteration examine whether the algorithm's logic has become simpler rather than more complex. If the algorithm's line count grows linearly with the number of test scenarios, cheating or patch stacking is present, and re-abstraction is needed. The sign of convergence is: when a test scenario is added, it passes without modifying the algorithm's logic.

**The legitimate standing of negative-sample fixtures:** The detection capability of the security and compliance checks (§15) itself also needs to be tested. Synthetic fixtures (negative samples) used to prove that a rule **really fails** are part of the detection capability, not noise that needs cleaning up — **fixtures must not be deleted just to make things green**, nor may assertions be relaxed to make a scan pass (see "Rule" in this clause). Such fixtures must use the **acceptable forms** defined in §15.1 item 1 (the same holds under Category A, see that item's "Category A has no named exemption channel"); a conforming form does not constitute a hit and requires no exemption list whatsoever. **Fixtures must not use real credentials, real personal information, or internal addresses** — even "just for testing". **The fixture list, and each fixture's intent and criterion, are carried by the test file's own comments and naming** (§1.6: code is the first document); no separate fixture documentation is created.

### 11.5 Acceptance Is User-Facing Acceptance 〔L2·M｜all·tiers-or-quantified-claims〕

**The purpose of acceptance is to answer "what users can use, to what degree they can achieve it under what conditions, and what is not within the commitment".** Therefore **acceptance-facing artifacts are naturally user-facing artifacts — the two are aligned, not two different kinds of thing**. This is what "acceptance is user-facing acceptance" means.

**Corollary (the only mandatory content of this clause):** When the object of acceptance **provides selectable tiers, or gives quantifiable performance/effect/capacity conclusions**, the acceptance output is **not merely an acceptance record** — the conclusions and evidence must be captured into the statement of function and capability in `docs/` (§17.2, §17.7); the form is decided by the project, and data-driven is only one optional form (**once adopted, its five constraints are mandatory and cannot be downgraded**). That one statement document carries two responsibilities: **① the acceptance record; ② the user-facing statement of function and capability**. **"Killing two birds with one stone" is a design goal, not a by-product**: one of the marks that such acceptance is complete is that users can already answer "what can be used, to what degree it can be achieved under what conditions, and what is not within the commitment".

**The division between what is committed and what is not (two clauses; do not merge):**

- **The committed part = capability, effect, and performance conclusions under project-defined criteria** — **① every such item passes under the project-defined criteria**; **② the criteria carry a basis and are reviewable**; **③ results determined by the user's own inputs and conditions are not within the commitment**. The first two are both **objects of acceptance**, and acceptance must give a conclusion on them.
- **The uncommitted part = how things will turn out under the user's own tasks, datasets, and hyperparameters.** The capability statement may and should **record** the observed conclusion values (together with their basis), but **makes no effect commitment to users on that basis**. **The effect depends on the user's own tasks, datasets, and parameters and is not within the commitment scope of acceptance** (§17.7).

**The applicability boundary of this clause (to prevent padding documents):** What this clause requires is that "**the conclusions and evidence of acceptance must be captured where users can access them**", **not** that "every acceptance must add or produce a document". The form of the output is decided by the nature of the acceptance object:

- When the acceptance object **provides selectable tiers, or gives quantifiable performance/effect/capacity conclusions**, i.e. its conclusions **have user-facing explanatory value** (capability, parameters, performance, **and whether the project-defined criteria are met**) → the conclusions and evidence are captured into the statement of function and capability in `docs/` (form decided by the project, see §17.7).
- When the acceptance object **has no user-facing explanatory value**, this clause **requires no document whatsoever**; the conclusions land in the same run's acceptance record and git commit record (§17.4), and a document **must not** be fabricated to satisfy this clause — that is exactly the "documentation that duplicates the code and therefore inevitably goes stale" that §1.6 opposes. **Documentation produced beyond need is functional entropy**, not diligence.
- The judgment needs to answer only one sentence: **Among this acceptance's conclusions, which one is something users have a right to know and that currently has nowhere to be found?** If you cannot answer, do not produce a document.
---

## XII. Code Style

### 12.1 Type Annotations 〔L2·M｜A/B·code〕

**Principle:** Type annotations are not decoration — they are contracts. Every function signature is a type contract — the caller can know the input and output types without reading the implementation. When a type is changed, mypy forces you to review every affected file — this is not a maintenance burden, it is the foolproofing device (§2.1) embodied at the type level.

**Rules:**

1. **All functions must have complete parameter and return-type annotations.** This includes public methods, private methods (`_` prefix), and utility functions. Only the following cases are exempt:
   - `__init__` methods may omit the return annotation (the Python convention `-> None` may be omitted)
   - Abstract methods may annotate the return as `None` or omit it (subclasses may return different content)
   - Functions in one-off debugging scripts

2. **Class attributes must be annotated at the declaration site.** Instance attributes first assigned in `__init__` use PEP 526 annotation syntax:
   ```python
   self.running_models: dict[str, InferenceFramework] = {}
   ```

3. **Optional types uniformly use the `X | None` syntax (PEP 604) — applicable to projects whose minimum Python version is ≥3.10.** Use `str | None` rather than `Optional[str]`. `| None` is native syntax in Python 3.10+, the standard spelling of PEP 604, and the recommended form against the backdrop of Python 3.14+ lazy annotation evaluation (PEP 649/749); `Optional` remains usable but is not the project convention, to avoid introducing further `typing` imports and `from __future__` boilerplate.

4. **Replace complex nested types with classes.** Anonymous nested types such as `dict[str, list[tuple[int, float]]]` should not exist — replace them with a pydantic BaseModel or dataclass. Classes have field names and docstrings; when something must change, only the class definition changes and every reference site stays in sync automatically. Friendly to humans and AI alike.
   ```python
   # ❌ Forbidden
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

5. **When the project is released as an installable package or imported by downstream**, **the `py.typed` marker file must exist** under `src/package_name/` (PEP 561).

6. **mypy type checking** is already required in §11.1; a `[tool.mypy]` section must be configured in `pyproject.toml` (see the §20 skeleton). Type annotations + mypy together form the complete foolproofing device — neither is sufficient alone.

7. `from __future__ import annotations` is used only when circular imports prevent type annotations from being evaluated (see §8.6).

**Litmus test:** Open any function — can you accurately state the type of every parameter and the return type from the signature alone? If not, the annotations are incomplete. Are there anonymous nested types in the code (such as `dict[str, list[tuple[...]]]`)? If so, they should be replaced with classes.

### 12.2 Naming 〔L2·M｜A/B·code〕

Classes PascalCase, functions and variables snake_case, private members `_`-prefixed, constants UPPER_SNAKE_CASE, type aliases PascalCase, module files snake_case.

**Naming as documentation:** File names are the first line of documentation for the codebase. Through the directory hierarchy and file names, a reader should be able to infer the file's purpose, its owning module, and its inheritance relationships. File names are not labels for yourself — they are navigation signals for future readers (including AI agents). When a file has to be renamed for a new reader to understand its responsibility, the original naming was a failure.

A class name should decompose into path components — the CamelCase words of the class name correspond in order to package name → directory name → file name (snake_case), one word per level. **The concrete validation is implemented by `tools/check_class_file_naming.sh`** (§15.1 first-paragraph division of labor). **The exempt categories** (files inside a class directory, mixin classes, files shared by multiple classes of the same family, data containers, test helper classes) are kept as-is.

**Why constrain classes but not functions?** Functions get their domain context from the file they live in — the responsibility for locating them lies with the file. Classes are self-locating units referenced across files, and may be upgraded into a directory (§8.3) — a class name must carry its own locating information.

**Litmus test:** Given a class name, can you say where it should live without looking at the code? Given a path, can you say which class families it should contain? Naming only passes if both directions can be answered.

### 12.3 Language Convention 〔L2·M｜all·code〕

**The `README` bilingual rule (§17.6's exemption conditions, the two versions mirroring each other's content) see §17.1 (the only authority); this clause does not restate it.**

All other files — comments, docstrings, architecture documentation, configuration comments — **Chinese or English, either one, at the author's discretion**. No other language is permitted. Keep the language broadly consistent within a single file; a small number of technical terms, code references, or structural separators may remain in English.

**This constitution's own two language versions are not bound by this clause's "either one" rule** — the Chinese version is the sole source of truth and the English version is a full translation of the Chinese version, see §21.1.

**Configuration comments** (base configuration and override template, file names see §7) **are recommended to use English** (R) — English is recommended when facing the public community, while internal projects follow the team's language; they are a user-facing interface, and English is the common language of the global developer community.

**For the language of commit messages see §19.1 (the only authority); this clause does not restate it.**

Technical terms, algorithm names, framework names, and academic concepts keep their original English form — their original English is the common language of engineers in the field, and forcing a translation loses information density instead. The principle is: **accuracy first; do not sacrifice technical expression for language purity.**

Comments write **why**, not **what**. Useless comments are forbidden.

### 12.4 File Header Comments: Responsibility Declaration 〔L2·M｜all·code〕

**For projects that have source files and whose language supports file-header comments**, every source file must open with a comment declaring the file's function and scope of responsibility, stated in one sentence. This is a boundary declaration for AI (and for humans too) — when AI wants to stuff unrelated methods or classes into a file, the file header is the first line of defense (foolproof design, see §2). If the responsibility cannot be stated in one sentence → the file should be split (§1.1).

- The file header may be a module docstring or a comment block; the language follows §12.3
- `__init__.py` is exempt — its responsibility is exactly to re-export the public API (§8.6), and no repeated declaration is needed
- **One-off scripts, auto-generated files, and test fixture data are not required** — they have no responsibility boundary that needs long-term guarding
- A responsibility declaration is navigation and foolproofing information, not the "useless comment" forbidden by §12.3 — it answers "why does this file exist, and what content belongs in it"

**Litmus test:** Can the file header's responsibility declaration state in one sentence "should this piece of code go into this file"? If not, either the comment is not clear enough, or the file boundary has already been breached.

---

## XIII. Error Handling and Logging

### 13.1 Exceptions: Do Not Swallow 〔L2·M｜all·code〕

**Absolutely forbidden:** `except Exception: pass` or a bare `except: pass`. Every `except` block must contain explicit handling logic (retry, degrade, or convert into user-readable information and then exit). In principle exceptions are handled uniformly at boundary layers and exposed as early as possible in internal layers.

### 13.2 Log Levels 〔L2·M｜all·data-artifacts+long-running〕

DEBUG is for developers troubleshooting bugs, INFO for users to understand the run state, WARNING for users to evaluate run quality, ERROR to tell users why something failed.

**Projects that produce run artifacts or run for a long time (processes expected to keep running rather than ending after a single call)** must provide at least one standard log channel (for Python projects, the standard library `logging`), using these four levels. This ensures compatibility with log aggregation tools, CI pipelines, and debugging workflows. Beyond this required channel, the project may add domain-specific log files (structured JSONL for metrics, time-series event logs, raw rollout records, etc.) — these are system-personalized extensions and are not bound by the four-level scheme.

### 13.3 Log Files by File 〔L2·M｜all·data-artifacts〕

The split granularity of log files matches module boundaries (§1.1): **mutually independent modules log separately, while tightly coupled pipeline steps share the same log file.** Each independent log domain distinguishes **readable logs** (human-readable, INFO level) from **raw logs** (machine-parseable, full DEBUG). ERROR is aggregated into a common error log file. All log files live in the `logs/` subdirectory under the output directory (**when the output directory of §8.5 exists**; see §8.5 Output Directory Isolation).

The concrete file names and module divisions are decided by each project according to its own architecture.

**Core principle: splitting exists so that an investigator does not have to open the logs of unrelated modules at the same time, but it must not force an investigator tracing one causal chain to stitch a timeline together across files.** Structured domain-specific logs (such as JSONL rollout records, time-series event logs) are system-personalized extensions (see 13.2) and are not bound by this constraint — they serve machine analysis, not human investigation.

**Litmus test:** When investigating one event, how many log files must be opened at the same time to correlate the timeline across files? If you have to jump back and forth repeatedly, the split is too fine and the files should be merged.

### 13.4 Debugging: Simple Is Reliable 〔L2·M｜all·code〕

**Principle:** The complexity of the debugging means must not exceed the complexity of the system being debugged. For the general methodology (entropy criterion, assess before acting) see the Preamble "Entropy and complexity discipline" and "Execution-First Principle". Debugging tools are themselves code and can have bugs too. When a complex logging framework, distributed tracing, or async sampler itself becomes the source of the failure, fall back to the simplest reliable means.

**Technique:** `print()` + stdout redirection is the last and most reliable fallback. This is not a step backward; it is fallback design (§3.1) applied to the debugging domain — degrade to a simpler but more reliable approach so that debugging information is never lost.

**Litmus test:** How long does it take to set up the debugging environment? If the debugging environment itself is more complex than the bug being debugged, the debugging means are the problem.

---

## XIV. Dependencies and Deployment

### 14.1 License Constraints 〔L2·M｜all·unconditional〕

All dependency packages must be under **permissive licenses suitable for commercial use**; **viral (copyleft) licenses** are forbidden. Check license compatibility before introducing a new dependency. The **categories and severity levels of licenses are defined by this clause**; the concrete license list, metadata fields, search paths, and the implementation of the strict tier are carried by `tools/check_dependencies.sh` (§15.1 first-paragraph division of labor) — there is no second license statement document beyond this clause (§21.1 "the single landing point of constitution content").

**Strong copyleft is always FAIL, with no switch.** Strong copyleft (viral licenses) with no commercially usable permissive branch is a **FAIL**; no environment variable, command-line argument, or registry list can downgrade it.

**Weak copyleft and unknown texts default to WARN.** Weak copyleft and license texts that cannot be classified default to **WARN** — print the package name, version, and the license text that produced the determination item by item, and let a human decide whether that dependency may be used; unknown texts must not be silently accepted, nor treated as a proven problem. **An optional strict tier** (off by default; it can only tighten, never relax): under that tier, known weak copyleft is **FAIL**, while the two cases "cannot be classified" and "no data found" do not change with it — it must not turn ignorance into failure.

**The determination must be offline.** The license check reads only the license metadata of distributions already installed in the local environment; **it must not query a registry and must not make HTTP requests**.

**No data must not be reported as passing.** When no license metadata at all could actually be found, the check must report "§14.1 unverified" (WARN, together with how to obtain the dependencies), and **must not** output `[OK]` or "pass" — treating "did not see it" as "no problem" is a false pass. Only when the metadata of at least one distribution was actually checked and none of the three categories (strong copyleft, weak copyleft, unclassifiable) was found is reporting a pass allowed.

### 14.2 Dependency Management: uv 〔L2·M｜A/B·code〕

**Python package projects:** The single source of truth for dependency declarations = package declaration + lock file, locked to **exact versions** — there is no other dependency declaration; both files are committed to git. (M)

**Default implementation (R, equivalent tools may be substituted, but exact versions must be pinned):** `pyproject.toml` declares the dependency constraints (package name + version range), `uv.lock` is **generated from `pyproject.toml` via `uv lock`** and records the fully resolved dependency graph with exact versions and content hashes; `.python-version` pins the Python version; `uv sync` sets up the development environment in one command.

**The lock file is a generated artifact; manual editing is forbidden.** Dependency change workflow: change the declaration → regenerate the lock file (for Python/uv that is `pyproject.toml` → `uv lock` → `uv.lock`). `pyproject.toml` + `uv.lock` form the single source of truth for dependencies — **there is no other dependency declaration**; **the concrete forbidden dependency-declaration file names are defined by `tools/check_dependencies.sh`.**

### 14.3 Container Images 〔L2·M｜all·container〕

**Whether to deploy in containers is decided by the project's shape and release method; this constitution makes no requirement** — Category C does not apply §7–§21 by default (Layer 0), and if a Category A/B project builds no image, this clause likewise has nothing to govern. But **once** a project provides a container image, **all** constraints of this clause take effect: the base image is pinned to a concrete version tag or digest (do not use `latest`; tags can be overwritten — use a digest when strong determinism is required), two-layer build with layer caching (the Dockerfile separates a dependency layer from a source layer; dependency installation uses `uv sync` or `uv pip install` with `uv.lock` to ensure the dependency versions inside the container match the development environment — **Python/uv projects**), `build.sh` injects the version from git tags, BuildKit cache mounts, build-time parameters do not pollute the runtime, and the three kinds of residue are empty after the build. Environment contamination and secret leakage are correctness problems of the image itself, **independent of project category**.

**Docker layer cache design:** The dependency layer copies both `uv.lock` and `pyproject.toml`. The version number is derived by `setuptools-scm` from git tags (§8.7), and `dynamic = ["version"]` in `pyproject.toml` contains no version string, so a version change does not change the file hash of `pyproject.toml`. The dependency layer is rebuilt only when `uv.lock` or `pyproject.toml` actually changes — routine version releases and code changes never trigger a dependency-layer rebuild.

All dependency-installation commands use BuildKit cache mounts, so that packages are read from the local cache instead of going over the network (the concrete mount targets are defined by `tools/check_dockerfile.sh`).

`build.sh` obtains the version number from a git tag and injects it at build time, for build environments without `.git`, while keeping the version number single-sourced (the mechanism is verified by `tools/check_docker_version.sh`).

**Dockerfile template (example (L3); when this template is adopted, the base-image pinning, two-layer build, and cache mounts in the first paragraph are embodied by it):**

〔L3｜template-adopted〕
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

**build.sh template (example (L3); when this template is adopted, the "inject the version from git tags" in the first paragraph is embodied by it):**

〔L3｜template-adopted〕
```bash
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")
IMAGE_NAME="${IMAGE_NAME:-project:${VERSION}}"
docker build --build-arg VERSION="${VERSION}" -t "${IMAGE_NAME}" -f docker/Dockerfile .
```

- **build.sh version:** The version number must be obtained via `git describe --tags` and must not be hardcoded. The `IMAGE_NAME` environment-variable override remains usable for manual testing, but the default value must come from a git tag.

**Proxies and build-time parameters must not pollute the runtime:** If a proxy is needed at build time to reach external networks (such as `HTTP_PROXY`, `HTTPS_PROXY`), the proxy environment variables **must not** be written into the Dockerfile's `ENV` instruction, and no proxy configuration may remain in the image after the build. Internal proxy addresses themselves are also secret information as defined in §15.1 — writing them into a Dockerfile is equivalent to cementing internal addresses into git history. **For how to pass them, choose per the "Value-Passing Rules" table below; this is not restated here; for which metadata location `ENV` and `ARG` values each land in, see "The two kinds of metadata for build-time parameters" below.** Runtime environment contamination must be avoided completely: **proxy-class variables must not be passed via `ENV`**; for the complete constraints see "Proxies Must Not Pollute the Runtime" below.


**Correct example 1 (recommended) — secret scenario: Category A / public repository, or any proxy carrying credentials, goes through secret.**

In the Dockerfile, each `RUN` that needs the proxy mounts it separately (a secret is visible only inside the `RUN` that mounts it):
〔L3｜template-adopted〕
```dockerfile
RUN --mount=type=secret,id=proxy,env=HTTP_PROXY \
    --mount=type=secret,id=proxy,env=HTTPS_PROXY \
    --mount=type=secret,id=proxy,env=NO_PROXY \
    --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev
```

In build.sh (proxy values live in a gitignored file, entering neither git nor the image):
〔L3｜template-adopted〕
```bash
docker build \
    --secret id=proxy,src="${PROXY_FILE}" \
    -t "${IMAGE_NAME}" -f docker/Dockerfile .
```

**Correct example 2 (usable) — non-secret scenario: Category B / private Category C, addresses that are reachable only on the internal network and carry no credentials, may use `--build-arg`.**

In the Dockerfile:
〔L3｜template-adopted〕
```dockerfile
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
```

In build.sh:
〔L3｜template-adopted〕
```bash
docker build \
    --build-arg HTTP_PROXY="${HTTP_PROXY:-}" \
    --build-arg HTTPS_PROXY="${HTTPS_PROXY:-}" \
    --build-arg NO_PROXY="${NO_PROXY:-}" \
    -t "${IMAGE_NAME}" -f docker/Dockerfile .
```
> Usable only when these addresses **carry no credentials** and are not pushed to a public repository. It does **not** pollute the runtime environment (`ARG` does not enter `Config.Env`), but it does appear in `docker history` (see below), and it **must never** be switched to passing the values via `ENV`.

This rule applies to all configuration that is needed only at build time and should not exist at runtime — proxies are the most typical scenario, but it also covers private pip mirror sources, build cache configuration, and the like. Litmus test: is this configuration still needed when the container runs? If not, it must not appear in the final image.

**The two kinds of metadata for build-time parameters: configuration metadata and build history metadata.** "`ARG` does not enter the image" is an incomplete statement — what it does not enter is **configuration metadata**; what it does enter is **build history metadata**. To judge whether a value pollutes the runtime environment or leaks, the two locations must be judged separately:

- **Configuration metadata** (`Config.Env`/`CMD`/`LABEL` of `docker inspect`, the image configuration exported by `docker save`): `ENV` values enter it, and the running container inherits them; `ARG` / `--build-arg` values **do not enter** — which is why passing a proxy via `ARG` does not pollute the runtime environment.
- **Build history metadata** (`docker history`, the image's layer records): the **literal values** of `ARG` / `--build-arg` do enter. BuildKit writes them into the history as a standalone `ARG NAME=VALUE` entry and as the `RUN |N NAME=VALUE /bin/sh -c …` prefix, **even if the parameter is never referenced by any instruction**; `docker inspect` cannot see these values, but `docker history --no-trunc` shows them at a glance. (The index `N` is decided by the build process and is not necessarily 1. In addition, BuildKit emits a `SecretsUsedInArgOrEnv` warning when an ARG carries sensitive data.)

**Value-Passing Rules (graded by the nature of the value and the project category, not decided by the single dimension of "build time or runtime"):**

| Nature of the build-time value | Category A / any public repository | Category B / Category C not pushed to a public repository | Rationale |
|---|---|---|---|
| **Credential kind** (§15.1): keys, passwords, tokens, private keys, private source URLs with credentials or signatures | **Must** use a BuildKit secret: `--mount=type=secret,id=<id>,env=<VAR>` | **Must** use a BuildKit secret (no relaxation) | A secret's value enters neither configuration metadata nor build history metadata; credentials are not eligible for any graded exception (§15.4) |
| **Credential-free internal addresses**: internal proxy addresses, internal mirror-source addresses, internal domain names / IPs | Counts as secret under §15.1, **must** use a BuildKit secret or switch to a public source; `--build-arg` is **forbidden** | `ARG` + `--build-arg` is allowed (the value enters `docker history`); the value is internal topology information, and the **push scope is the confidentiality boundary** (§15.4) | Images of Category A and public repositories may be made public, so internal addresses must not enter an uncontrolled scope; B/C is not published publicly by default, so the risk is bounded by the push scope |
| **Non-secret**: version numbers, build switches, public source addresses | `ARG` + `--build-arg` (the existing rule is retained) | `ARG` + `--build-arg` (the existing rule is retained) | The value being visible in history is beneficial: it makes the build process traceable (§1.4 single source of truth) and reproducible (§6) |

> The relaxation for Category B and Category C is bounded by repository visibility: once the repository becomes public, it is handled as Category A (§15.4).

**The transmission method is governed by the table above. Confidentiality grading does not change the runtime non-pollution constraint — the two are separate matters** — grading only governs "how the value is passed", while runtime non-pollution only governs "the value must not remain in the runtime environment"; neither substitutes for the other. For the complete constraints see "Proxies Must Not Pollute the Runtime" below.

**When a controlled value is passed via `ARG` because of toolchain limitations or a graded relaxation:** the image's **push scope** must be managed as the confidentiality boundary (push only to controlled registries, never to public repositories); "flattening/deleting the layer history" **must not** be treated as a secrecy mechanism — it is only a cleanup measure, not secret protection. Writing secret values into a Dockerfile's `ARG NAME=default` or `ENV` is **forbidden** — that would enter git (§15.1).

**BuildKit / buildx notes:**
1. A clean `docker inspect` **does not equal** no leak — `ARG` values are not in `Config.Env`, but they are in `docker history`. "It is not in `inspect`" **must not** be used to prove that a secret was not carried into the image.
2. A `--mount=type=secret` value enters neither configuration metadata nor build history; but a secret is **visible only inside the `RUN` that mounts it** — if multiple `RUN` instructions need the proxy, all of them must mount it, and this is the common cause of "the build-time proxy stops working" after switching to secret.
3. `--no-cache` is only a cleanup measure; it does not change the fact that "the value has already been generated during the build and may already have left traces in pushes, caches, or CI logs" (the same holds for flattening measures such as `--squash`; for the prohibitive statement see "When a controlled value is passed via `ARG` because of toolchain limitations or a graded relaxation" above).
4. Whether `max`-mode provenance attestations and `--cache-to` cache metadata carry build parameters **has not been measured**; confirm it yourself before use, and it **must not** be treated as a known conclusion.

**Proxies must not pollute the runtime (applies to every project that builds an image; not relaxed by project category):**

> **Scope:** See the first paragraph of this section — it applies to every project that builds a container image, **not relaxed by project category**; projects that build no image have nothing for it to govern. The applicability precondition of the "Category B / Category C not pushed to a public repository" column in the Value-Passing Rules table above is likewise **that the project provides a container image**.

1. **Forbidden** to pass build-time variables (proxies, private mirror sources, registries, etc., including upper and lower case) via `ENV`; the equivalent form of `ENV X=$X` after `ARG X` is **likewise forbidden**. They write the value into the container's runtime environment; once the runtime depends on that variable it fails, and troubleshooting can hardly locate the cause back to build time. **The concrete variable-name list and the class grading are defined by `tools/check_dockerfile.sh`.**
2. **Forbidden** to write build-time configuration into **persistent** files inside the image (shell startup files, package-manager/build-tool configuration, git/container configuration, etc.). If a build-time tool must read the configuration, it may be generated **only within the same `RUN`** and must be deleted before that `RUN` ends — no residue across layers. **The concrete path list is defined by `tools/check_dockerfile.sh`.**
3. Proxies take effect **only at build time**, and the transmission method **is chosen per the "Value-Passing Rules" table above**; no unconditional recommendation is given — for the complete grading see that table and §15.4, not restated here.

**Acceptance (run after the build):** Confirm item by item that there is no build-time configuration residue in the configuration metadata, the login-shell environment, or the contents of persistent configuration files — **all three outputs must be empty**. **The concrete acceptance commands are chosen by the project itself and pinned into the build chain; `tools/check_dockerfile.sh` currently performs only static Dockerfile checks and does not include runtime image acceptance — that runtime check awaits a `tools/` implementation.**

The match patterns for configuration metadata and the login-shell environment target **build-tool-class** variables (proxies, build-time mirror sources / registries), not runtime business variables; build-time configuration of this kind must likewise not remain in the image's runtime environment.

**The outputs of all three kinds of residue must be empty** — any matching line (even if only one kind matches) means failure, with no exception for "only irrelevant entries". **The login-shell environment kind cannot be omitted**: a login shell reads shell startup files and injects the proxy variables in them into the process environment, and looking only at configuration metadata cannot detect this contamination. **The persistent-configuration-file-content kind checks file contents**: `ls` can only prove that a file exists and cannot find the proxy inside it. **Category A / public repositories additionally require** confirmation that no literal value of an internal address or credential appears in the build history — that check serves **only** to confirm that no literal value is in the history; `ARG` carrying secrets is therefore not allowed — this is a separate matter from "not polluting the runtime environment" (the commands are chosen by the project itself; **the literal-value scan of the history of already-built images awaits a `tools/` implementation**).

> For the source-of-code constraint during image builds see §14.4 — regardless of where the image is built, the source code must come from a definite version on the development machine.

### 14.4 Code Sync: One-Way Flow 〔L2·M｜all·deployment〕

**Scope: it applies to every project that has a deployment environment and whose code must flow from a development machine to a deployment machine, regardless of category** — infrastructure repositories of Category C are equally covered; projects without a deployment environment (pure libraries, pure documentation repositories) **have nothing for it to govern**.

**Principle:** Code modifications happen in the development environment; the deployment environment only receives code. The flow direction of code from the development machine to the deployment machine is one-way — the development machine is the source of modifications, the deployment machine is the destination of modifications. This is §1.4 (single source of truth) extended into the deployment process: code content and modification behavior each have a single authoritative source.

Modifying code directly on a deployment machine is a breeding ground for engineering disasters — the modification is forgotten and gets overwritten on the next deploy; two people modify the same file on the development machine and the deployment machine respectively, and at merge time no one can say which version is correct. Code on the deployment machine must be **traceable and reproducible** (here "reproducible" means traceable to a definite commit, which belongs to §1.4 single source of truth and is not subject to §6's precondition of re-running), which means it must come from a definite version on the development machine, not from somebody's impromptu edit in an SSH session on the deployment machine. The deployment machine may have no access to git (network isolation, security policies, etc.) — this does not affect the principle: after committing with git on the development machine, packaging the code (tar/zip) and scp-ing it to the deployment machine is likewise code from a definite version. The key is not the transmission method; the key is that code modifications happen only on the development machine and the deployment machine only receives code.

**Rules:**
- Code on the deployment machine **must** come from a definite version on the development machine; editing source files directly on the deployment machine is forbidden. Preferred method: development machine git commit → deployment machine git pull (when the deployment machine can access git); alternative method: development machine git commit → package (tar/zip) → scp/rsync to the deployment machine (when the deployment machine cannot access git)
- The **only** allowed form of code modification on the deployment machine is: modify on the development machine → git commit on the development machine → sync to the deployment machine (git pull or scp/rsync). Regardless of the transmission method, the code version on the deployment machine must be traceable to a definite commit on the development machine
- Forbidden to "manually sync back to the development machine" after any source modification on the deployment machine — that is not synchronization, it is two sources of truth
- Docker image builds are recommended to be completed on the development machine or in a CI environment (push the image to a registry, and the deployment machine pulls the image); building on the deployment machine from code synced from the development machine is also acceptable, but building from code that was manually modified on the deployment machine is not allowed

**Techniques:**
- The project directory on the deployment machine should be set to read-only (for non-root users), blocking direct modification at the filesystem level — this is foolproof design (§2) applied to deployment
- The deployment script (`deploy.sh` or a CI pipeline) should start from obtaining a definite version of the code — it may be `git checkout <tag>` (when the deployment machine can access git), or a package file of a specified commit scp-ed from the development machine (when the deployment machine cannot access git). Either way, the deployment script should record the version identifier (commit hash or tag) of this deployment
- If temporary debugging is needed during deployment, reproduce the problem on the development machine, modify the code, commit, and then deploy the new version — do not take the path of "modify it on the deployment machine and then sync it back"
- If the deployment machine can access git, keeping the `.git` directory is recommended, so that `git status` can verify at any time whether the working tree is clean and `git log -1` can confirm the currently running version. If the deployment machine cannot access git, the deployment script should record the version identifier into a `VERSION` file in the deployment directory at deploy time

**Litmus test:** Can the code on the deployment machine be traced to a definite version on the development machine (a git commit, or the version marker of a package file)? Are there any source code modifications on the deployment machine that were not committed on the development machine? Code sync is healthy when the first answer is "yes" and the second answer is "no".

---

# Layer 3: Security and Project Governance

## XV. Security and Secrets

Security is not a patch bolted on just before release; it is a design premise constraining every commit. The principle is simple: **if you don't want it on GitHub, it doesn't belong in any tracked file.**

### 15.1 Pre-Commit Checks 〔L2·M｜all·git-repo〕

Every commit must pass all of the following checks. These checks should be integrated into CI or a pre-commit hook and executed automatically by the companion `tools/` scripts, not left to human memory. The constitution defines the check categories; the scripts define the concrete match patterns. **A purely local repository with no push surface** (no remote, or not shared with anyone else) may skip CI integration, but **the check categories are unchanged** — still self-check item by item per this section, only the execution mode drops from automated to manual.

> **A push publishes three things:** ① the content of tracked files; ② the entire git history (including deleted files); ③ commit metadata (author/committer names and emails) and commit messages. All three must be verified before pushing — scanning only the current working tree is not enough.

**1. Secrets scan:** No secret information may appear in any tracked file. Secrets include:
- Keys, passwords, tokens, and private keys of any form
- Internal IP addresses, internal domain names, internal paths
- Any information you would not want on GitHub after open-sourcing

(For the graded exception for Category B and private Category C projects see §15.4; credential-class information is not eligible for any exception.)

**Acceptable forms: synthetic values and reserved values.** The preceding sentence "credential-class information is not eligible for any exception" targets **real credentials**. If a value can be **mechanically determined** to be in a synthetic or reserved form, it does not belong to the credential class at the moment of determination and does not fall under this item's prohibition — such values appearing in documentation examples, templates, and test fixtures are legal, **with no exemption list required**. The exact match patterns are defined by `tools/check_secrets.sh` (see this section's first-paragraph division of labor).

**What is let through is the form, not the category.** This paragraph does not constitute an exemption for the information category "credentials"; it only separates mechanically determinable synthetic/reserved values from real credentials. In **Category A and any project pushed to a public repository**, the following are uniformly **not accepted** and must be rewritten in form: credential strings carrying a real issuance prefix, random strings or passwords indistinguishable from real values, internal addresses (including internal domain names and internal paths), real names/emails/phone numbers — they must be rewritten into documentation example addresses or placeholder forms. **Non-credential information in Category B and private Category C is handled per the §15.4 grading table; credential-class information is not accepted under any category.** The exact match patterns are defined by `tools/check_secrets.sh`.

**Category A has no named exemption channel.** The named exemption list mechanism for Category B and Category C projects not pushed to a public repository is **not loaded and does not take effect** under Category A or any project pushed to a public repository: Category A projects **must not** register false positives in any named list, nor let any hit through on the grounds that it is "already registered". The mechanism's syntax, scope of effect, and match patterns are defined by `tools/check_secrets.sh` together with its inline comments and `--help` (§15.1 first-paragraph division of labor), and no separate explanatory document is created. Category A test fixtures have only two compliant paths — use the **acceptable forms** above, or rewrite the fixture into an acceptable form (see §11.4).

**2. File-type check:** The following must not appear in tracked files, **regardless of project category**:
- `.env` files (only `.env-example` may be committed)
- IDE configuration files
- Local files generated by AI assistants (assistant-specific local instruction/draft files of any kind; they must be excluded in `.gitignore`)
- Local and temporary files — all such files must live in `.local/` (see §16)

**Projects with a build pipeline or a virtual environment** must additionally exclude build artifacts, caches, and virtual environment directories.

**3. Content checks (human + AI assisted):**
- No training data, user data, or private datasets
- No internal resource references in the README

**Definition of "training data":** the training data referred to in this item means specifically data that can be used to train a **model for a specific function** — private corpora, labeled sample sets, user behavior data, datasets used to train model weights, and the like; it does **not** include **public** seed data and Ontology data (public vocabularies, schemas, category tables, mapping tables, public corpus indexes, etc.) used to implement a feature. **Non-machine-learning projects read this per their corresponding assets (business data, user content, private corpora).** Test: can this data be obtained unconditionally from public channels, and does it not itself constitute a project-unique asset? If so, it is public seed data / Ontology data and is not subject to this item.

**4. Personal information (PII) scan:** No tracked file or git history may contain information that can locate a specific natural person, whether or not it falls under category 1 secrets:
- Personal email addresses; instant messaging accounts such as QQ or WeChat; mobile and landline phone numbers
- National ID numbers, passport numbers, bank card numbers, student IDs, employee badge numbers
- A real name combined with other identity fields (anything that alone or in combination points to a specific person)
- **Exemptions (reserved domains, reserved number ranges, and placeholders):** public project mailboxes, example and reserved domains, explicit placeholders, pure filler number ranges, reserved fictional phone number ranges — the exact match patterns are defined by `tools/check_secrets.sh`.

**Per-form basis (test fixtures and documentation examples):** This paragraph retains only four **category criteria** of "accept / do not accept"; the concrete form values are defined by `tools/check_secrets.sh` and are not restated in the clause — (a) example email addresses: a reserved-domain or placeholder form is **accepted**, an address under any real domain is **not accepted**; (b) example mobile numbers: those mechanically determinable as reserved / fictional forms are **accepted**, a number with any real country code + real structure is **not accepted**; (c) example keys / passwords: only the "acceptable forms" defined in §15.1 item 1 are accepted, and they **must not carry a real issuance prefix**; (d) internal addresses and documentation example addresses: **internal addresses are not accepted**, **documentation example address ranges are accepted** (for the basis see item 1; internal IPs fall under item 1's prohibition, not under a PII entry).


(For the graded exception for Category B and private Category C projects see §15.4; employee personal sensitive information is not eligible for any exception.)

**5. Commit metadata and commit-message privacy:** For public repositories, author/committer emails and commit messages must be included in the scan; the verification entry point is provided by `tools/check_secrets.sh` (including git history and metadata). For remediating historical leaks see §15.3.

### 15.2 Secrets Management Principles 〔L2·M｜all·unconditional〕

Secret information does not enter git. Secrets include: keys, passwords, tokens, internal IPs, internal domain names, and any other information you would not want to appear on GitHub after open-sourcing. **In Category B and private Category C projects, non-credential information is handled under the graded exception of §15.4; credential-class information is not eligible for any exception.**

**Secrets storage (choose one layered override mechanism; `.env` is an optional user-side channel):**

1. **`.env` file** (for third-party components that read nothing but environment variables, or for flat key-value cases the user chooses): store in `KEY=VALUE` format in `.env` (local, **never tracked**). `.env-example` serves as a template in git, listing all required environment variable names and descriptions, without real values. Per the §7.1 principle, `.env` is not the preferred source of truth for project configuration; configuration that can go into the TOML override must not be put here.

2. **Layered override file** (for secrets nested within configuration structures): **override files go under `.local/`** (the landing point of §7.1 is one example, gitignored), following the §7.1 layered configuration pattern — the base configuration contains all fields (secret fields left empty), the override file fills in only the secret values, and the program merges them into a single configuration view on startup. Non-Python projects implement the same layering in their own configuration format.

**Selection criteria:** Choose one **layered override mechanism** as the single source of truth for secrets (§7 uses TOML; non-Python projects use their configuration format). Use `.env` only when a third-party component accepts nothing but environment variables, or when the user explicitly chooses so. **Two sources for the same field are prohibited** — each secret field may have exactly one source.

**Rules:**
- No literal secret values may appear in any code, documentation, configuration template (including `.sample` and `.env-example`), or example file
- `.env` and override files must be excluded in `.gitignore`
- Template files (**named per the §7.1 convention**) must be tracked in git and **contain placeholders only** (placeholder forms are defined by `tools/check_secrets.sh`)
- If personal information (email, phone numbers, instant messaging accounts, etc.) must appear in configuration, prefer the layered override (§7.1); use `.env` when environment variables are genuinely required. It must not be hardcoded in the base configuration or in templates

**Litmus test:** Can an outsider clone the project and run it (in degraded mode) without access to any secret information? Does the git history contain any secret information or personal information?

### 15.3 Post-Leak Response 〔L2·M｜all·unconditional〕

If secret information was ever committed to git history:
- Confirm via `git log --all --full-history` that no sensitive file history remains
- Use a **history-rewrite tool** (BFG, git filter-repo, etc.) to purge every trace thoroughly, and rotate every leaked key — **the choice of tool is not a criterion**

> The pre-release compliance review checklist is in §19.3 and §15.1 item 3, and is **unrelated to leak handling**.

If what leaked is personal information (PII) rather than a secret, the history-rewrite exception likewise holds (see §19.1). A **history-rewrite tool** (e.g. BFG) can purge file contents only and **cannot** change author/committer emails — changing emails requires a callback-style tool such as `git filter-repo --email-callback` (or `git filter-branch --env-filter`), with tags rewritten in step. After rewriting, force-push and ask the hosting platform to purge cached pages; forks and third-party mirrors cannot be guaranteed to be purged.

### 15.4 Graded Exception: Project Category and Repository Visibility 〔L2·M｜all·unconditional〕

**Principle:** The grading baseline is the **project category** (Category A is strict; Category B and Category C not pushed to a public repository are lenient), because the latter two are not published publicly by default. Once the grade is set, what decides the consequence is whether the information can enter an **uncontrolled public scope** — once a repository becomes public, the exception immediately ceases to apply (for the concrete boundary see "Applicability" below). The real risk is not "this information is in git" but "this information is pushed into an uncontrolled public scope". §15.1 item 5 is already limited by "public repository"; this section generalizes that same approach to the remaining check items.

**Applicability:** Category B (closed-source private repositories) and Category C projects not pushed to any public repository. Category A and any project pushed to a public repository **are not eligible for any exception**. **Once a repository becomes public** (including a newly added public fork, public mirror, or public release attachment), the exception immediately ceases to apply, and history is cleaned up per §15.3.

**Red lines (all categories, all visibilities, never relaxed):**
- Keys, passwords, tokens, private keys, certificates, SSH private keys, passwords in connection strings
- Credential-bearing addresses: URLs with a username/password, token, or signature (private sources, webhooks, pre-signed links)
- `.env`, `config.override.toml`, and other override/local files — they MUST always be excluded in `.gitignore` (§16.1, §19.2)

> **Boundary with §15.1 item 1 (this does not constitute an exception):** The object of this section's red lines is the **information category** — real credentials enjoy no exemption whatsoever; §15.1 item 1's "acceptable forms" judge the **form** — a value mechanically determined to be synthetic/reserved does not belong to the credential class at the moment of determination and therefore does not fall under this section's red lines. The two are two different levels, "category vs. form", and read together they do not conflict: **no** real credential may be exempted on the grounds of being a "fixture" or an "example"; and a synthetic/reserved form **must not** be treated as a credential (that would force fixtures to be deleted, violating §11.4). Category A and public repositories have no named exemption channel (§15.1 item 1).

**Grading table:**

| Information category | Category A / public repository | Category B / private Category C |
|---|---|---|
| Credentials (keys, passwords, tokens, private keys) | Forbidden | **Forbidden** (no relaxation) |
| Internal IPs, internal domain names, internal paths | Forbidden | Allowed |
| Company mailboxes, real names, employee IDs / badge numbers, departments, internal IM group IDs | Forbidden | Allowed |
| Private datasets, internal data samples, internal documents | Forbidden (for the definition of "training data" see §15.1) | Allowed (you must confirm you hold the right to distribute internally) |
| Commit author / committer names and emails | MUST be a `noreply` or project mailbox (§15.1 item 5) | Company mailboxes allowed; `noreply` still recommended |

**Conditions that must also be met for the relaxation:**
1. `git remote -v` contains no public repository address; the repository is hosted on an internal network or under a controlled private organization
2. `.gitignore` still excludes `.env`, override configuration, and `.local/` (§16.1, §19.2)
3. **Live information about the audited project's own runtime environment** may still be written only into `.local/` per §16.2, and this exception does not relax §16.2 — what this exception relaxes is "company-internal information appearing in project content" (the non-credential information listed in the table above, i.e. every row other than the credentials row), not "runtime environment records"; the boundary between this section and §16.2 is: the information category is judged by the table above, the storage location by §16.2 (see also §17.5 for where the work log lands)
4. What is relaxed is "company-internal information", which does not include **employee personal sensitive information** — national ID numbers, passport numbers, bank card numbers, home addresses, private mobile numbers, private email addresses — which must not enter the repository even in an internal repository

**Disambiguation for §15.1 item 4:** With this item-by-item relaxation, the "**combination** of a real name with other identity fields" referred to in §15.1 item 4 **no longer by itself constitutes a violation** in Category B and Category C projects not pushed to a public repository (real names, employee IDs / badge numbers, and departments are all relaxed in the table above); however, **employee personal sensitive information** must still not appear in any form or in any combination.

**Named exemption list (opt-in).** The named exemption list for Category B and private Category C is an **engineering mechanism, not a constitution-level right** (Category A and public repositories have no such channel, see §15.1 item 1). **opt-in** — when the list does not exist, the check's behavior and output are **exactly the same** as without the mechanism; an empty list and a comments-only list are likewise inert, and no list-related line may be printed. **Downgrade only, never hide** — a hit does not disappear because it is registered: it is still printed item by item, accompanied by the reason the project gives, and the list changes only that hit's severity label and reports the number of downgraded items; it **does not change** this run's pass/fail conclusion, and red-line categories must not be let through this way. **fail-closed** — when the list is not under version control, has an invalid format, is missing fields, names a category that is not eligible for exemption, uses wildcards or absolute paths, or points to a nonexistent path, that entry **does not take effect** and is reported item by item; naming a red-line category itself constitutes failure. **stale visible** — when a valid registered entry matches no hit, stale must be reported; a registration must not outlive the hit it corresponds to. **Independent** — this list relaxes only this one check and affects no other check. The list's syntax, fields, matching method, and scope of effect are defined by `tools/check_secrets.sh` together with its `--help` / inline comments (§15.1 first-paragraph division of labor).

**Litmus test:** If this repository were made public tomorrow, what would be exposed in tracked files and git history? Only credentials and employee personal sensitive information are **unacceptable** answers; internal addresses and internal data are acceptable — but at that point the visibility change must be handled per §15.3; it cannot be left to "we'll deal with it later".

---

## XVI. Local and Temporary Files

Every project generates local files that are useful during development but do not belong in the permanent codebase — run logs, migration plans, deployment notes, deployment configuration, personal experiments. Without a designated home, these files scatter across the repository, and sooner or later one of them gets committed with an internal IP or a password in it.

### 16.1 `.local/` — the Sole Home for Local and Temporary Files 〔L2·M｜all·unconditional〕

The `.local/` directory at the project root is the **only** permitted storage location for all local and temporary files. That directory is excluded wholesale in `.gitignore`, and nothing in it is ever committed to the codebase.

`.local/` does not mean "you are advised to put it here" but "it can only go here". Any local or temporary file that appears in a tracked path outside `.local/` constitutes a violation.

**The criterion for "local and temporary" is the nature of the file, not its extension or carrier** (for the landing points of this general rule and of the six criteria see §16.2). Machine-readable data files (such as configuration data, schemas, generated contracts), generators and their deterministic outputs, and human-readable views belong to the permanent codebase, and their landing points are tracked paths such as `docs/`, `configs/`, and `tools/`; they **do not fall under this section because they are "not documentation"**. The "local and temporary files" constrained by this section mean specifically the six determination conditions listed in §16.2 — in particular "contains runtime environment information", "describes a one-off operation", "personal notes", and "any engineering file that does not belong to the permanent codebase" — and determination is by the nature of the content. **A machine-readable data file must not be judged a local file because its extension is not among Markdown's.**

`.local/` carries two kinds of files:
- **Local deployment files** (long-term): deployment-specific artifacts that persist across sessions, such as deployment configuration overrides and localized startup scripts.
- **Temporary files** (short-term): one-off artifacts such as run logs, phase materials, and debugging records.

### 16.2 What Belongs in `.local/` 〔L2·M｜all·unconditional〕

**General rule: the criterion is the nature of the file, not its extension or carrier.** Files meeting any of the following conditions (judged item by item by the nature of the content, not by extension or carrier) are local and temporary files and must be placed in `.local/`:
- Serves as a runtime environment record containing runtime environment information
- Is a deployment configuration override
- Describes a one-off operation
- Personal notes, debugging records, run monitoring
- Temporary data, experiment configuration
- Any engineering file that does not belong to the permanent codebase

If a file has long-term value to the project, first decide its destination by the decision tree below; only if neither applies does it stay in `.local/`:

1. **User-facing, or referenced by `docs/`, and its content cannot be expressed by code** → convert it into formal documentation in `docs/` (§17.2).
2. **Its content can be expressed by code or tools** (the FAIL/WARN line of check rules, match patterns, tool mechanisms, usage parameters) → **do not make it a standalone document**; the code itself carries it — inline script comments, `--help`, configuration schema (§1.6 "code is the first documentation").
3. **Everything else** (personal records, phase materials, drafts nobody references) → keep it in `.local/`.

**Note: a standalone document that is maintainer-only and neither user-facing nor acceptance-facing has no landing point in the repository** — **unless it also has user-facing value (i.e. it satisfies one of the three content criteria of §17.2), in which case it may exist as the corresponding subsection in `docs/`**; otherwise it must take path 2 (sink it into code/tools) or path 3 (`.local/`); there is no third destination beyond those two. This is the direct consequence of **this section** not establishing a separate maintainer documentation directory, and also the positive requirement of §1.6: explanatory documentation that duplicates code necessarily goes stale — so do not write it.

**The sole exception: the work log (§17.5).** It has long-term value but necessarily contains environment information (resources and environment), so it may exist only in `.local/` and must not be converted into documentation in `docs/` — this is part of the data boundary (§1.4): environment information is not allowed to enter tracked files.

**Internal implementation plans and schedules do not enter the repository.** Implementation plans, schedules, and gap-closing plans that contain internal nodes, internal paths, internal accounts, or staffing **do not belong** in `docs/` — `docs/` holds only user-facing content that can be reviewed externally (for the three content criteria see §17.2), and scheduling does not fall under any of them; **in Category A and any project pushed to a public repository** it violates §15.1 item 1's prohibition on internal addresses and internal paths, and **in Category B and private Category C it still must not enter `docs/`** — for the same reason: a schedule is not user-facing content and has no `docs/` landing point under any category. The statement of function and capability in `docs/` **may** record "items still to be filled in and their target states" (for the state values see the four-state vocabulary of §17.7 "Obligation One"), but **must not** record who is to implement them, at which internal node, or via which internal path.

**Division of labor with §15.4:** This section governs the **storage location**, not the grading of information categories — "what information may enter tracked files" is decided by the §15.4 grading table (e.g. an internal service address as project content in a Category B project), while "where a file that is a runtime environment record goes" is decided by this section (only `.local/`). Read together they do not conflict: information being committable under §15.4 does not mean it may be placed outside `.local/` as a runtime environment record.

### 16.3 Relation to `scripts/` 〔L2·M｜all·unconditional〕

§10.2 defines `scripts/` as the directory for shared temporary code tools. Division of labor:
- `scripts/` — shared temporary code tools (tracked in git, no backward-compatibility obligation)
- `.local/` — private temporary files (not tracked in git, not shared, no obligation of any kind)

---

## XVII. Documentation and Records

### 17.1 Bilingual Documentation 〔L2·M｜all·readme〕

**Except for the exemption cases specified in §17.6**, `README.md` (English) and `README.zh-CN.md` (Chinese) must **mirror each other in content**, not merely in structure. The same operation guidance, configuration explanation, or FAQ entry must exist in both versions; content present in one version and absent from the other is not allowed. On every release, both READMEs must be updated in step.

> **This section governs only the project `README`, and the exemption is bounded by the conditions of §17.6.** The constitution's own two language versions are two different objects: the Chinese version is the sole source of truth and the English version is its **full translation** (direction fixed as Chinese → English), see §21.1. The two are isomorphic in that "the content sets of the two versions must be identical"; the difference is that §21.1 fixes the direction, whereas this section does not fix the order of the two README versions. **The §17.6 exemption waives only the form requirement of "bilingual coexistence" and waives no secrets-scanning requirement whatsoever** — an exempted project remains bound by all of §15.1 and §15.2, and no literal secret value may appear in its single README (§15.2).

**A README must answer at least four things**: what this is, how to install it, how to run the minimal example, and where to look for details (the section order and naming are up to the project). The seven parts below are merely one common example and **not a criterion**: introduction → quick start → data format → configuration reference → output description → development guide → FAQ (of which "data format", "output description", and "configuration reference" hold only for projects with the corresponding content).

### 17.2 User-Facing Documentation (`docs/`) 〔L2·M｜all·unconditional〕

**What `docs/` holds is material for users to read — the project's users and AI agents, not collaborators in the development process.** Users care about only three things, and these three are the content criteria for `docs/`:

1. **How to use it** — how this software is actually used: quick start, installation and configuration, user guide, command and parameter reference, minimal runnable example, typical usage, configuration examples, FAQ and troubleshooting.
2. **What the architecture looks like** — letting users understand how the system works so that they use it correctly: module boundaries, responsibilities, interfaces, data flow, key flows, with the necessary structural-level diagrams.
3. **Whether it works well** — the **statement of function and capability** (what it can do, to what degree under what conditions, where the boundaries are), and the quantified conclusions given (performance, capacity, effect; they must carry a basis, see §17.7).

**The basis for judging readers and content is "who reads it, what it is for", not "at which stage it was produced".** A document does not become an intermediate artifact just because it "was generated from machine-readable data"; conversely, **things from the development process do not go into `docs/`** — how tests are done, how development is done, the judgments and decisions reached along the way, process records of runs, review records, task plans; **users do not care**, they care only about **the finished product already built and already pushed to GitHub**: what this product is like, how to use it, what the architecture is, whether it is usable.

**Content that goes into `docs/`** (split by topic, each file focused on one concern; the following are examples, not a closed list):
- Quick start, installation and configuration, user guide, command and parameter reference
- **Statement of function and capability** — what this project can do, what it cannot do, where the limits are; the conclusion state listed item by item (capability item, function, command, interface, configuration combination, or scenario), plus the quantified conclusions given; one document carries two responsibilities at once: **① the acceptance record; ② the user-facing statement of function and capability**. See §17.7 for details; **the statement must explicitly state the commitment boundary (see §17.7 "Obligation Three: commitment boundary explicit")**.
- Examples: minimal runnable example, typical usage, configuration examples
- FAQ, troubleshooting
- User-facing architecture explanation: module boundaries, responsibilities, interfaces, data flow

**Content that does not go into `docs/`:** things from the development process — how tests are done, how development is done, the judgments and decisions reached along the way, process records of runs, review records, task plans; as well as what has only short-term value to an individual or the current phase (§16.2), and what can be expressed by code or tools and therefore needs no standalone document (§1.6). **Note: "does not go into `docs/`" does not mean "has no home"** — they land in `.local/` (§16.2) or in code/tools (§1.6). **The concrete matching rules are carried by the `tools/` scripts themselves** (§15.1 first-paragraph division of labor).

**The exception for process documentation.** When the **authoritative definition** of a process cannot be carried by code and the process needs to be **reviewed**, it may be made a standalone document in `docs/`: the document must declare at its head "this file is the sole authoritative source of this process", and the whole text describes steps only and cites only `§` numbers — it **must not restate clause content** (restating clause content violates §21.1 "the sole landing point of constitution content"). Such a document is not judged a violation on the grounds of §16.2 "maintainer-only documents have no landing point in the repository"; process documents that do not satisfy the above three conditions are handled per §16.2 (sink into `.local/` or delete).

**The boundary with §1.6 still applies:** the **architecture explanation** in `docs/` writes only the structural-level "what" and "why" (module boundaries, responsibilities, interfaces); implementation details live in code comments (§12.4); the usage documents in `docs/` serve "how to use it", and copying implementation details is not permitted just because they are user-facing.

**When documentation contains structural-level diagrams**, it must use a machine-parseable, versionable **textual diagramming language**, the specific language being chosen by the project and unified within the repository (**currently Mermaid by default**); **diagrams that exist only as images are prohibited**, and hand-drawn character diagrams that cannot be machine-parsed are not accepted either — a textual diagramming language can be generated and modified by AI, whereas images cannot. Node names must always be wrapped in English double quotes to guarantee compatibility across renderers. **The necessary structural-level diagrams (architecture, flow, data flow, etc.) are indispensable elements of an architecture explanation** — after reading them you know how the system works. Directory trees, tables, and other plain-text structures are not "diagrams" and are not subject to this section.

**Tracked documentation contains no deployment environment records.** Deployment notes, experiment records, run monitoring, and the like are local files as defined in §16.2 and should go into `.local/`. `docs/` **is allowed** to contain opaque run IDs, acceptance criteria, item-by-item conclusions, and failure attribution (acceptance is user-facing acceptance; both the conclusions and the attribution are things users have a right to know).

**The commit rules for internal-network information in `docs/` are judged per the existing division of labor between §15.4 and §16.2; this section sets up no stricter prohibition of its own.** Specifically: **whether it can enter tracked files** is decided by the §15.4 grading table according to **project category and repository visibility** (in Category B and Category C projects not pushed to a public repository, internal IPs / domain names / paths as internal service addresses in project content are allowed); **whether it is a runtime environment record** is judged by §16.2 (host paths, hostnames, container names, and other runtime environment records may go only into `.local/`); internal nodes, internal accounts, and staffing are handled per §15.1 item 1 and §16.2. **The sole exception is the landing point of the user-facing statement of function and capability** — that landing point has its own stricter basis (because it is user-facing and AI-facing), see §17.7 "Prohibition Two: desensitization floor for the landing point". For the verbatim basis see §17.7.

**Litmus test:** Can a user who **does not know this project** (human or AI), reading only `docs/`, answer three things — **① how to use this software** (install it, run the minimal example through, find the parameters)? **② what its architecture looks like**? **③ whether it works well** — what it can do, to what degree, where the boundaries are (performance dimensions are up to the project)? If all three are answerable, `docs/`'s positioning is correct.

### 17.3 AI Assistant Documentation 〔L2·R｜all·ai-assistant〕

If a project uses an AI coding assistant, it may on demand generate that assistant's dedicated local instruction file (high information density, structured) to help the AI understand the project's architecture and conventions. These files are **not committed to git** (excluded in `.gitignore`) and are part of the local development environment. If the project does not use an AI assistant, these files need not be created.

Projects that use a work log (§17.5) should place in the AI assistant's local instruction file a one-line pointer to `work_log_current.md`, explaining that the first position of its state section is the "user's original prompt" anchor and must be read at every session — so that the AI discovers the log entry point and the intent anchor at every session.

### 17.4 Version Records 〔L2·M｜all·git-repo〕

Projects do not maintain a standalone Changelog file. The git commit log is the single, authoritative change history. On release, mark the version number with `git tag`; to review changes, use `git log`. Commit messages should follow the format specification of §19.1 so that `git log --oneline` suffices to read the project history.

### 17.5 Work Log: Continuous Handover 〔L2·M｜all·unconditional〕

Handover is not an event; it is a continuous state. Instead of writing a compressed handover document at each transition, maintain a work log — essentially a continuously updated handover document that lets any successor (human or AI) continue the work at any time, without asking the original author.

The work log consists of two files under `.local/`, never tracked in git (they necessarily contain environment information, §16.2):

- **`work_log_current.md` — the state section, read at every session.** It holds only the latest values, is updated in place, and is never pruned; **the sole exception is the leading "user's original prompt" anchor — append-only, never overwritten**. Organized into the following sections (**the sections below are examples and may be trimmed per project**): user's original prompt (one sentence recording the user's original task intent, frozen after the first write, with new lines appended only when the user explicitly changes the goal; it is the intent anchor across sessions and context compactions, preventing gradual drift from the original goal in long tasks), current progress, current major difficulties and problems, task plan (checklist format, `[ ]` todo / `[x]` done), unresolved questions (decision points requiring user confirmation), planned solutions to try, resources and environment (servers, GPUs, available tool scripts, etc.), technical conventions and tooling notes (frameworks, design patterns, coding conventions). **The line ceiling is a recommended value** — keep it under about one hundred lines; it carries the "understand the state in 30 seconds" responsibility.
- **`work_log_history.md` — the event section, read on demand.** Appended incrementally with timestamps (entries start with `YYYY-MM-DD HH:MM`). It records the user's original requests, completed tasks, and resolved problems, with new entries appended at the end. When the log grows too long, prune selectively: delete from the head (oldest) entries **already absorbed into code or documentation and no longer worth referencing**; important decision context may be kept forever. **Pruning is a trade-off, not a truncation** — if after pruning a successor cannot understand the current state faster than by reading git log, you pruned too much.

Relationship with git: the git commit log is the authoritative record of change facts (immutable, §17.4); the work log is the narrative decision context (selectively compressible). The log records what git does not — why, difficulties, solutions, next steps. The log is not a Changelog replacement and carries no authority; every statement in it should be cross-verifiable against git or the code.

Division of labor between the state-section anchor and the event section: the event section keeps the **verbatim original request** (selectively prunable along with history), while the state-section anchor keeps the **stable intent summary** (not prunable). Different purposes, no duplication.

**When to update:** at the end of each working session or when a phase task completes — append 3~5 lines to the event section (**a recommended value**) and refresh the current values in the state section (the "user's original prompt" anchor stays unchanged unless the goal changes). Projects that use AI assistants place a pointer to `work_log_current.md` in the AI assistant's local instruction file (§17.3).

**Litmus test:** Can a newcomer (or new AI) fully continue the work reading only the work log and the codebase, without asking the original author? If not, the log is incomplete.

### 17.6 Single-Language and Private Projects 〔L2·R｜all·readme〕

**Principle:** Bilingual READMEs (§12.3, §17.1) serve a clear goal: letting open-source projects reach both the English and Chinese developer communities. When that goal does not exist, the bilingual requirement no longer applies — the project should choose the language of its widest target audience and keep it consistent.

**Rule:** A project meeting any of the following conditions may keep only a single `README.md`, with the language kept consistent (Chinese or English, either one):

1. **Private project**: the project is not pushed to any public repository and is used only within an intranet or a private repository.
2. **Single-language audience project**: the project's target user community is clearly a single-language community, and the maintainer judges that a bilingual README would not bring practical community-coverage benefit.

**The object of this section's exemption is the project `README`.** The constitution's own two language versions are not exempted according to project category — the Chinese version is the sole source of truth and the English version is a full translation, see §21.1.

**Techniques:**
- An exempt project should clearly state the project language in its single README, to avoid confusing readers.
- Choose the language by target audience: Chinese for Chinese-speaking communities, English for English-speaking communities
- If the project later becomes open-source or expands its audience, add a bilingual README at that point — this is not debt; it is a scope change

**Litmus test:** Does the project's target audience include both Chinese- and English-speaking communities? If not, and the project is not in a public repository, a bilingual README produces no practical value.

### 17.7 Statement of Function and Capability (`docs/`) 〔L2·M｜all·tiers-or-quantified-claims〕

**Applicability.** **When a project offers optional tiers (supported configuration combinations), or gives externally quantifiable performance / effect / capacity conclusions**, `docs/` must contain exactly one user-facing statement of function and capability. **A project with only a function list and neither tiers nor quantified conclusions does not trigger this section** — its truthfulness is covered by the L1 rule "must be true" and by the three reader questions of §17.2; this section requires it to produce no dedicated document, and tiers or metrics must not be fabricated to satisfy this section. **A fabricated tier is functional entropy**: it adds to what the user must read, and nothing to what the user can do.

**Obligation One: explicit status.** Every listed item must carry an explicit conclusion state, with only four permitted values: **verified usable / verified unusable / not yet verified / outside the commitment scope** (projects may define their own labels but must declare the mapping to the four). States must be presented in **distinguishable text** and must not rely on color, a legend, blank space, or placeholders alone. Items without a conclusion must not be omitted, and design goals, plans, or placeholders must not be passed off as usable; **items not yet verified must not be counted toward the usable total**; an item marked "verified unusable" must state which criterion it failed (it is not enough to write "failed / unusable"). Writing "unusable" for something never measured is as distorting as writing "usable" for something never measured.

**Obligation Two: quantified conclusions carry a basis.** Any number presented as a conclusion, and any criterion used to judge "pass / meets the bar", must state the conditions under which it holds (environment and configuration, inputs and data, method and parameters), the measurement method, the criterion identifier, and the decision rule; **where there is a threshold, write the threshold**; for boolean and contractual criteria (such as "the artifact loads", "byte-identical", "exit code zero") stating the decision rule suffices. When the evidence is not public, write "proprietary / not public" and give a verifiable alternative anchor (version identifier, criterion definition, sample size and evaluation method, reproducible command). **When the project has no quantified conclusions at all, this obligation does not arise** — metrics must not be fabricated to satisfy this section.

**Obligation Three: commitment boundary explicit.** The statement must contain, in body-text position and directly readable by users, a commitment-boundary statement covering three points: ① the coverage scope (which items this statement covers, and which of them are verified); ② the conclusions obtained (what conclusions were reached under what basis); ③ what is outside the commitment scope (which effects, conditions, or external factors are not committed to by this project). It must **positively state how far verification has gone**; it must not merely write "not guaranteed / for reference only" without a positive statement; it must not rely on footnotes, appendices, or hover tips; **and the converse holds too** — "outside the commitment scope" must not be used to play down failures that have actually been measured.

**Prohibition One: no disguising by aggregation.** When several items together constitute a single overall commitment, the commitment must not be declared satisfied because individual items pass; it must be stated that "this commitment is not yet met" and the items that failed and the items not yet verified must be listed. Coarse-grained items, summary rows, or percentages must not be used to merge "not yet verified" into "verified usable".

**Prohibition Two: desensitization floor for the landing point.** The readers of this landing point are users (including external users) and AI. **Allowed**: run identifiers, criteria, item-by-item conclusions, failure attribution. **Prohibited**: host paths, internal addresses / domain names / paths, machine names, personal names, internal nodes and accounts. **This landing point is not covered by the §15.4 relaxation for Category B and private Category C**. **The "landing point" in this prohibition means every user-facing statement of function and capability, not limited to the one required by this section**; non-capability content in `docs/` is still judged per §15.4 and §16.2.

**Conditional obligation: data-driven form.** **When a project declares the form "machine-readable data + generator → human-readable view", items ①–⑤ below are mandatory and non-degradable**; **a project that has not declared this form carries no such obligation**, and must not be judged non-compliant because it "has no machine-readable data file". ① **Exactly one editable source** ("both are sources of truth" is prohibited); ② **the direction is uniquely fixed** — whether the source is data or the human-readable view is declared by the project, and two mutually contradictory statements in the same repository count as undeclared; ③ **deterministic generation** (same input, same byte string; the generator reads no clock / environment / network / interaction); ④ **no hand-editing of derived views** (changes must go to the source or the generator and then be regenerated); ⑤ **byte-for-byte reconstructable** (rerun and compare byte by byte; any differing byte is a failure). Three companion items (equally mandatory): ⑥ the generation relationship is explicitly marked (machine marker in the file header + visible explanation on the first screen); ⑦ generated artifacts undergo §15.1 scanning on equal terms; ⑧ review cost falls on the diff of the source and the generator.

**Form and granularity are up to the project.** The document form (one section / one page / a table / a page generated from data), file names, landing points, minimal entry (capability item, function, command, interface, configuration combination, scenario), and field list are all up to the project. **"Tier" is only one example of entry granularity** (naturally used when the capability space is a discrete set of configuration combinations); this section does not require any project to adopt it.

**Three example cases (examples, not criteria).**

- **Training framework** (multiple VRAM tiers × parallel strategies) → a capability and usable-tier matrix; a tier = a configuration combination; criteria = runs through to completion + effect meets the bar under the project's own dataset and parameters.
- **Inference service** (concurrency / batch size / quantization tier) → a performance tier table; criteria = it starts, requests succeed, artifacts are correct + latency / throughput / VRAM meet the bar under the project's own benchmark; "accuracy on the user's business data" is outside the commitment scope.
- **Web/UI service** (a single deployment form) → **may have no separate matrix**; the three reader questions for `docs/` suffice, but any performance number given must still carry a basis.

**Division of labor with tools.** This section specifies categories and criteria only and **names no concrete script**. Any machine check must be declaratively optional: when a project has not declared the data-driven form, the machine check must not fail it for "having no machine-readable data file". Desensitization at this landing point is covered by the existing multi-category scans of §15.1 item 1 and §16.2.


---

## XVIII. Version Evolution and Debt Management

Technical debt compounds over the life of a project: today's shortcut has to be paid back many times over tomorrow, and the day after tomorrow becomes a part no one dares to touch. The core principle is just one sentence: **once the new architecture is validated, the old architecture must be eradicated.**

### 18.1 No Debt Left Behind 〔L2·M｜all·unconditional〕

- After the new architecture goes online, passes tests, and runs stably, old code is **deleted immediately**: no "compatibility mode", no old-architecture directory, no version/legacy naming, no "to be deleted" comments — **the exact matching is defined by `tools/check_legacy_cleanup.sh`**. The codebase contains exactly one current architecture (migration scripts are an explicit exception, see §18.2). **Old code is structural entropy**: while it stays, the reader must decide every time whether "this piece is still in use".
- When deleting old code, update in step: naming (no more `v2`, `new`, `legacy` prefixes/suffixes), **configuration templates (the landing points of §7.1) must reflect the current architecture**, documentation (architecture descriptions in README and docs/), tests (delete the old architecture's tests; do not keep them "just in case").
- Version numbers are updated on every release, following `MAJOR.MINOR.PATCH`: architecture refactors and incompatible configuration changes bump MAJOR, new features bump MINOR, bug fixes bump PATCH.

**Third-party code registration (opt-in).** "Compatibility" and "legacy" wording and naming that third-party or upstream code legitimately carries are not debt under this section; a project may use a **named registration list** to declare these paths and exclude them from this section's scan — this is an **engineering mechanism, not a constitution-level right**, and it relaxes only this one check. **opt-in**: when the list does not exist, the scan's behavior and output are exactly the same as without the mechanism. **refuse-closed**: when it declares absolute paths, contains `..`, points to the project's own top-level first-party source directory, or would empty out all source files in the scan, the list does not take effect and this run fails — a single declaration line must not switch the check off. **stale visible**: when a valid prefix matches no tracked file, stale must be reported. The list's syntax, parsing, and matching method are defined by `tools/check_legacy_cleanup.sh`.

### 18.2 Legacy System Migration 〔L2·M｜all·versioned-releases〕

When users of an old version need to upgrade to the new architecture, provide a one-click migration path:

- Migration scripts go in `scripts/`, and **the naming must let the source/target versions be read off** (e.g. `migrate_v1_to_v2.*`)
- The script header comment states: source version number → target version number, what is migrated (configuration file format, checkpoint format, data format), and the parts that cannot be auto-migrated (requiring manual user action)
- Migration scripts are not the old-architecture code referred to in §18.1; they are modules in the new codebase responsible for "upgrading old data / old configuration". Migration proceeds generation by generation: upgrading across several major versions may require running multiple migration scripts in order, so older migration scripts remain in `scripts/` as an upgrade chain for users who skip versions

**Litmus test:** When a newcomer clones the project, can they see traces of the old architecture? If so — leftover code, outdated comments, un-updated configuration templates — version management has failed.

---

## XIX. Open Source Management

### 19.1 Git Workflow 〔L2·M｜A/B·git-repo〕

- Direct commits to the `main` / `master` branch are prohibited
- **Solo project exception**: a project with only one active contributor may push directly to the `main` / `master` branch, with no PR workflow required. When the project gains a second contributor, it must switch to the PR workflow immediately.
- All development happens on feature branches — **the branch naming must let the type and the content be read off at a glance; the concrete prefixes are set by repository convention** (e.g. `feature/<description>`, `fix/<description>`, `docs/<description>`)
- Merging to main must go through a PR — at minimum, review the diff yourself once
- Commit messages are **recommended** to be in English, format: `type: short description` (feat, fix, docs, refactor, test, chore). English is the de facto standard of the open-source community; the `git log --oneline` toolchain is English-first, which makes it easier for international contributors to understand. A project whose primary contributor community uses another language (e.g. Chinese) may use that language, but should stay consistent within one repository.
- **History continuity takes precedence over retroactive fixing.** Commits already pushed to a public repository **must not** be retroactively rewritten to change the commit-message language — changing pushed history breaks every collaborator's local clone. The specification takes effect from the current commit forward. Exception: if historical commits contain leaked secret information or personal information, history must be rewritten (see §15.3).
- One commit does one thing

### 19.2 .gitignore Must Cover 〔L2·M｜all·git-repo〕

`.gitignore` must cover all kinds of runtime caches, virtual environments, build artifacts, environment configuration and secret overrides, outputs and data, IDE and system files, and local temporary files — **the concrete entry list and the required ignore patterns are defined by `tools/check_gitignore.sh`** (following the §15.1 first-paragraph division of labor). **`.env` and its override files never enter the repository; this is a red line and is not relaxed by the list being pushed down.**

### 19.3 Open Source License 〔L2·R｜A·public-distribution〕

**This project's own** distribution license: a **publicly distributed** project uses a permissive, commercially usable license by default; **a project not distributed externally carries no obligation under this section**. The license constraints of **dependencies** are a separate matter, see §14.1 — this section must not be read as an exemption from or a strengthening of them.

---

## XX. pyproject.toml Skeleton 〔L3｜A/B·template-adopted〕

**Applicability**: this section applies only to **projects that build a Python package** (Categories A/B); Category C does not apply. This section is a **template** (§21.1 exception category 1) — copy it and adapt it to the project; **the version floors, line width, dependency versions, lint rule set, and paths in it are all example values and not criteria**. **The `[project.scripts]` section is conditional on "provides a CLI"** — a project without a CLI deletes that section; copying it verbatim would create an empty entry point.

```toml
[project]
name = "my-project"
dynamic = ["version"]
description = "One-sentence description"
readme = "README.md"
license = {text = "MIT"}  # Category A per §19.3; Category B per company policy; Category C not applicable
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

---

## XXI. Constitution and Prompt Text

### 21.1 Language, Writing Style, and Revision of the Constitution Text 〔L2·M｜self·unconditional〕

This section governs the relationship between **this constitution's own** two language versions and its textual writing style. §17.1 governs the project `README`, §17.6 governs the `README`'s single-language exemption; the three have different objects and read together they do not conflict.

**The Chinese version is the sole source of truth.** The authoritative definition of the constitution's content is the Chinese version (`BADGE-constitution-v<version>.zh-CN.md`). The English version (`BADGE-constitution-v<version>.en.md`) is a **full translation** of the Chinese version, a derived artifact, not a second source of truth — it adds nothing, removes nothing, and independently interprets no clause.

**Revision process: first change the Chinese version and finalize it, then translate the whole thing into the English version.** Any addition, modification, or deletion of a clause is completed and finalized in the Chinese version first; the English version takes the **finalized Chinese version** as its sole input and is retranslated as a whole. **Forbidden** for the two versions to evolve independently: forbidden to change the English version first and "backfill" the Chinese version, forbidden for the two versions to separately absorb content the other does not have, forbidden to change only one place without retranslating the remaining affected clauses.

**The two versions must be consistent:**
- The version numbers are identical — two language versions with the same version number are the product of the same translation relationship and are released together
- The chapter structure and numbering are identical — §a.b points to the same clause in the English version
- The clause sets are identical — every clause the Chinese version has must exist clause by clause in the English version, and vice versa

**The writing style of the constitution text.** This constitution writes only **concepts, criteria, and general explanations**. Any expression that could be replaced by a value of the same kind without changing the clause's meaning — a specific instance, a specific number, a specific form, a literal value, and metaphors / analogies — is not written at all; except for enumerations necessary to the criteria — **the reason they cannot be deleted is explained at constitution-revision review and recorded in the revision record** (§17.4's git commit record / revision plan), **and is not repeated inside the clause**. **Specific examples that a tool can mechanically verify are all pushed down into `tools/`**: the constitution writes only the categories and criteria of checks, and the concrete determination rules are carried by the scripts themselves (§15.1 first-paragraph division of labor). This section is where the entropy criterion lands on the text itself — removing examples and removing repetition both compress the constitution's own functional entropy.

**Layer, modality, and applicability conditions must be explicit.** Each clause's **heading line carries at most one marker**, placed on the heading of that clause's **minimal normative unit** (a clause with subsections places it on the subsection heading, a clause without subsections on the section heading); **inline references appearing in the body in forms such as `(L3…)` are not markers**; **an unmarked clause is treated as `L2·M｜all·unconditional`** — a missing marker only makes the clause govern more broadly. Four requirements:

1. **Layer** may only be one of L1 / L2 / L3. A clause marked L1 **must not use** a specific technology, specific form, specific number, or file name **as the criterion**; as explanation (not as criteria), examples and executable landing points are out of scope here, but one must not infer from a single example that other cases do not hold — **analogies**, whether used as criteria or as explanation, remain bound by the ban in "The writing style of the constitution text". A clause marked L3 **must not** be treated by any clause or tool as a compliance criterion (it may serve only as the check basis "when this template is adopted"); **the reverse is equally prohibited** — a substantive requirement must not be downgraded to L3 to evade criteria.
2. **Modality** has only two levels, M (mandatory) / R (recommended) (L3 is a layer, not a modality), and it must agree with the wording of the body: a paragraph whose body says "must" must not land in a section marked R (the section marker takes the strongest modality of the section; per-paragraph wording inside the section remains the per-paragraph criterion).
3. **The applicability conditions must be directly readable from the marker** and must be self-consistent with the body — reading the clause itself must suffice to judge "does it govern my project or not". Any clause meaningful only for a certain project form (deployment form, artifact form, technology stack, audience) **must be worded as condition-triggered**; **it is prohibited** to carry form-specific requirements with "every project must…"; **and a specific form of one project (a particular file name, a particular report, a particular field list, a particular deployment method) must not be written as an unconditional requirement for all projects** — such content may appear only as L3, or be written as a conditional L2.
4. **Enumerations necessary to the criteria** must at the same time state "under what conditions it is necessary to the criteria"; when the condition is missing, the enumeration does not enjoy the exception and is handled as a "replaceable value of the same kind".

**Marker syntax.** A marker is written as `〔layer[·modality]｜category[·trigger form]〕` and **lands at the end of the heading line** (h1/h2/h3 all work, see below); when a block within a section is L3, use the block-level marker `〔L3｜template-adopted〕` **on a line of its own, immediately above that block**. The values are a **closed set**: layer `L1` / `L2` / `L3`; modality `M` / `R` (written for L2 only); category `A` / `B` / `C` / `A/B` / `all` / `self` (`self` = binds only this constitution repository itself); the trigger form is `unconditional` or one of the following words (several joined with `+`): `code`, `container`, `deployment`, `tiers-or-quantified-claims`, `data-artifacts`, `cli`, `multiple-implementations`, `config-files`, `automated-tests`, `startup-script`, `versioned-releases`, `git-repo`, `readme`, `prompt-text`, `ai-assistant`, `template-adopted`, `long-running`, `public-distribution`. **Adding a trigger word is a MINOR-level revision** and must be recorded in the revision record (`long-running`, `public-distribution`, and `prompt-text` were added this way). Joining several trigger forms with `+` means **the trigger fires if any of the listed forms is present** (coordinate, not simultaneous). **Marker landing point**: a section with subsections lands the marker on the subsection heading (h3); a section without subsections lands it on that section's heading; **a top-level unit without subsections (such as the Preamble) lands it on that h1**.

**Markers are not part of the clause content.** The applicability marker at the end of the heading line is **declarative metadata**; it takes no part in the semantic interpretation of the clause and is not bound by the preceding paragraph's "do not write specific forms" — what it describes is "whom this clause governs", not "what this clause requires".

**The sole landing point of constitution content.** All of this constitution's **clauses and the categories / principles of its criteria** exist only in the Chinese and English constitution files; **concrete match patterns, lists, and fields** are carried by `tools/` (§15.1 first-paragraph division of labor) and do not enter `docs/`. Clauses and criteria must not be defined anew, restated, or rewritten in `docs/`, `README`, skill addenda, or any other file. A project's own process documentation may exist, but it describes steps only and cites only `§` numbers, without restating clause content. Violating this section constitutes "constitution content has a second source of truth" (§1.4) and leaves the constitution skill missing entries.

**Repositories that implement the constitution**: such a repository is **forbidden** to embed constitution version references in source files — the constitution version number is maintained only in the constitution repository itself, so that it is a single source of truth just like the project version number. **Project repositories do not bear this obligation.** **The concrete literal patterns are defined by `tools/check_constitution_refs.sh`** (the hardcoded-version check for this constitution repository itself is carried by `tools/check_version.sh`).
  `tools/check_constitution_refs.sh` and `tools/check_version.sh` are part of the constitution's own content, not project code.

**Relation to the opening "How to read this constitution".** The opening passage **defines the meaning of the three layers and the applicability determination procedure**; all criteria for writing style, marker obligations, and the revision process are governed by this section. Where the two disagree, this section prevails.

**Exceptions (forms that may be kept; the reasons they cannot be replaced are uniformly explained at constitution-revision review and recorded in the revision record, see below, and are not repeated inside the clause):**
1. **Standard templates** — **executable landing points** where replacing them would change the reader's actions or the tool's behavior (directory trees, configuration file skeletons, build scripts, paste-ready command blocks, etc.). They are not "replaceable values of the same kind"; deleting or replacing them would directly change the reader's actions.
2. **Enumerations necessary to the criteria** — **category lists** without which it could not be determined "what to do / what to scan / what to compare" (such as the secret categories in §15.1 item 1, the personal-information categories in item 4, the six criteria in §16.2, the three residue locations in §14.3). Such enumerations are the criteria themselves, not examples — **but they must at the same time state under what conditions they are necessary to the criteria**; when the condition is missing, the enumeration is handled as a "replaceable value of the same kind" and must be de-exampled.
3. **Bundled examples explicitly marked "not a closed list"** — example lists that are **explicitly marked** with "the following are examples, not a closed list" or an equivalent sentence and that **do not serve as a basis for judgment** (such as the "content that goes into `docs/`" list in §17.2) are **exempt from this section**: their demonstrative value outweighs the risk of overfitting, and they have been explicitly marked as open sets. **An example list without that marking is not exempt.**

**How the reasons are recorded.** Enumerations necessary to the criteria and standard templates **may be kept**, but **their reason for not being deletable must be explained at constitution-revision review and recorded in the revision record** (§17.4's git commit record / revision plan) — **not repeated inside the clause**. The granularity of the reasons: **category 1 (standard templates) uses one unified reason** — "**executable landing points** where replacing them would change the reader's actions or the tool's behavior" (all standard templates share this one reason, not expanded one by one); **category 2 (enumerations necessary to the criteria) is explained item by item** — "what could not be determined if it were deleted"; **category 3 (examples explicitly marked "not a closed list") is exempt from the explanation obligation** (it has been marked as an open set).

**Scope of effect:** This section **takes effect immediately** for newly revised and newly added clauses. Existing clauses are **handled in batches** under the debt management of §18: the maintainers create debt entries for existing clauses (clause location, violation form, planned batch). **The full-annotation channel (layered refactoring)**: a full annotation that is **purely metadata** **does not count as** the "unplanned one-off full rewrite" prohibited by this section and may be completed for all clauses at once within **a single release**, but **must simultaneously satisfy** four conditions; missing any one returns it to batch handling: ① **planned** (the revision record states that this is a layered refactoring and lists the marker vocabulary, the determination procedure, and the entire scope of changes); ② **semantics untouched** (no criterion added or removed, no modality changed, no section numbering or order changed — only markers added); ③ **mechanical evidence** (after stripping all markers from the new version's text, compare it **byte by byte** with the same file of the previous release; differences may fall only within the list of semantic rewrites explicitly declared this time, and that list goes into the revision record); ④ **no intermediate state** (do not release a version in which "half the document is marked and half is not"). **Semantic rewrites still proceed clause by clause / batch by batch** and are not exempted by this channel; every use of this channel must be re-declared in the revision record.

**Litmus test:** Take any clause of the English version — can you find exactly one corresponding source text in the Chinese version? Does the English version contain any clause the Chinese version does not have at all? Take any clause of the Chinese version — does it contain an instance, number, literal value, or metaphor that "could be replaced by a value of the same kind without changing the clause's meaning"? If it is an exception (standard template / enumeration necessary to the criteria / example explicitly marked "not a closed list") yet its reason for not being deletable is **not explained in the revision record**, that likewise counts as a violation. If the former cannot be done, or the latter exists, or the writing-style criteria are violated, this section is violated. Take any clause that holds only for a certain kind of project — can its applicability conditions be seen by reading the clause itself (including the end-of-heading marker)? Take any clause marked L1 — does it **use** a specific technology, form, number, or file name **as the criterion**? (Examples do not count; but inferring from one example that the remaining cases do not hold is likewise a violation.) Take any sample marked L3 — does any clause or tool treat it as a compliance criterion? If any one item cannot be answered or is answered "yes", this section is violated.

### 21.2 Model-Facing Prompt Text 〔L2·M｜all·prompt-text〕

**Applicability condition and object.** When a project holds **model-facing prompt text that is committed to the repository or distributed with the project**, this section holds; local prompts that are neither committed to nor distributed with the project produce no obligation under this section.

The prompt text itself is the object of this section; the AI assistant local files of §17.3 are not — those files do not enter the repository (§16.2).

**Unique landing point.** A prompt must have exactly one authoritative landing point and be editable in exactly one place; duplicates, trimmed variants, and copies inside comments are all a second source of truth and must not exist (§1.4).

Where the landing point is is decided by the project's form — a dedicated directory inside the project is the common form; **the criterion is "unique landing point, not editable in two places", not a particular directory name**.

When the same rule needs different wording in different situations, express the difference with placeholders or parameters; **the text must not be duplicated**.

**Examples represent a class.** A prompt may contain examples, but an example must represent a class of situations and must not land on a single point.

**The criterion is a single substitution**: replace the concrete action, tool, or value in the example with one of the same kind — if the meaning changes, it lands on a single point and should be deleted or lifted into a class; if the meaning does not change, it represents a class and may be kept.

An example **must not serve as a criterion**, nor be read as a closed list — the appearance of one example does not mean that unlisted situations are excluded.

**Guidance before process.** A prompt is mainly guidance in philosophy and methodology, and the rest is left to the model's judgment; **steps are specified only where the operation must be standardized**. **Process clauses must not replace judgment.**

**Generalization acceptance.** When a new kind of situation is added, if the prompt must be changed before it can be handled correctly, this prompt still handles individual cases, not a class of situations.

**Stop at necessity.** If, after one sentence is deleted, the existing situations can still be handled correctly as before, that sentence is superfluous.

The prompt text does not repeat itself, and earlier and later parts do not contradict each other.

**Boundary with §21.1.** The "examples form a class" criterion for prompt text shares its origin with §21.1 "The writing style of the constitution text", but the objects differ: §21.1 governs this constitution's own text, while this section governs project prompts.

The scope of `self` in §21.1 **is not widened by this section**.

**Litmus test:** Take any passage of a project's prompt text: does the same rule appear in two editable copies? Replace the concrete action, tool, or value of any example with one of the same kind — does the meaning change? When a new situation of the same kind appears, must the prompt be changed first before it can be handled? Delete any one sentence — can the existing situations still be handled correctly as before? Have process clauses replaced judgment? Does the whole text repeat itself or contradict itself? If any one of these is answered "yes", this section is violated.
