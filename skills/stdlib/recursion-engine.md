# Recursion Engine

The universal execution pattern for ShadowRepo. Every recursion level performs the same steps. Build, check, and update all invoke this engine with different scopes.

Load `methodology.md` and `data-model.md` before running this engine.

---

## Input

A Scope object (see `contracts/scope.md`):
- `scope_id`, `depth`, `files`, `mode`, and parent context

## The Recursion Step

Every level performs these six operations in order.

### 1. Sense

Read files in the current scope to understand what this code does.

**How:**
- Use Glob to inventory the scope's files
- Apply `file-discovery.md` classification rules: separate source, config, doc, test, other
- Read key files: manifests first (package.json, etc.), then README/docs, then source
- For large scopes: read directory structure + manifests + docs first, defer full source reads to Extract

**Output:** File inventory with classifications. An initial understanding of what this scope's code does.

### 2. Understand

Form or update feature understanding for this scope level.

**How:**
- Based on the file inventory and initial reading, identify features at this level
- If root level: propose the top-level feature tree (10-25 features)
- If sub-level: propose sub-features within the parent's scope
- Apply `methodology.md` feature tree rules (classification, naming, file assignment)
- In `incremental` mode: load existing features from `.shadowrepo/features.json`, only adjust affected areas

**Output:** Preliminary feature assignments for files in this scope.

### 3. Extract

Read source files and extract specs.

**How:**
- Read source files (batch: use Read tool, up to 10 files per batch for efficiency)
- For each file, apply `methodology.md` spec type triggers
- Capture WHY, not WHAT. Follow the good/bad examples in methodology
- Apply confidence calibration from methodology
- Create anchors for each spec (multi-file when applicable)
- Add `depends_on` / `conflicts_with` relations when directly observable

**Output:** Array of Spec objects for this scope.

### 4. Split (decision point)

Evaluate whether to recurse deeper.

**Criteria:**
- If scope has **> 50 source files** → SPLIT
- If scope has **<= 50 source files** → DO NOT SPLIT, this level is the leaf
- If `depth` >= 3 → DO NOT SPLIT regardless (max depth safety)

**How to split:**
- Group files by directory structure first
- Then by feature affinity (files belonging to the same feature stay together)
- Target sub-scopes of 15-25 files each
- Create a Scope object for each sub-scope (per `contracts/scope.md`)
- Pass down: current feature understanding, existing specs (for dedup), parent summary

### 5. Recurse (conditional)

If split: spawn parallel agents for each sub-scope.

**How:**
- Each agent receives: this engine definition + `methodology.md` + its sub-scope
- Each agent writes its result to `.shadowrepo/.tmp/{scope_id}.json` (per `contracts/merge-result.md`)
- Agents work independently — no cross-agent communication, no shared writes
- Each agent runs this same engine from Step 1

If not split: skip to Merge. The current level's Extract output is the final result.

### 6. Merge

Collect and synthesize results.

**If agents were spawned:**
- Read all `.shadowrepo/.tmp/{child_scope_id}.json` files
- Merge features: deduplicate by `feature_id`, keep version with more `key_files`
- Merge specs: deduplicate by anchor overlap, keep higher-confidence version
- Collect uncovered files from all children

**Always (whether agents were spawned or not):**
- Reconcile features: ensure tree invariants hold (every file assigned once, 10-25 features, etc.)
- Add cross-scope relations: `relates_to` and `supersedes` between specs from different features
- Apply `quality-gates.md` checks: density, coverage, confidence distribution
- Correct feature tree based on bottom-up discoveries (a sub-scope may reveal that the parent's feature split was wrong)

**Output:** A `merge-result.md` conforming to `contracts/merge-result.md`.

---

## Mode-Specific Behavior

### full mode (build)

- Scope starts as the entire repo
- All files are in play
- Feature tree is built from scratch

### incremental mode (update)

- Scope contains only changed files (from check result)
- Load existing features and specs from `.shadowrepo/`
- Re-extract specs for changed files
- Mark orphaned specs as `stale`
- Merge new extractions with existing data

---

## Termination

Recursion stops when:
- No scope exceeds the split threshold (50 files), OR
- Depth reaches 3

The root level's Merge step produces the final result, which the calling skill writes to `.shadowrepo/`.

---

## Error Handling

See `error-handling.md` for failure modes at each step. Key principle: **degrade gracefully, never hallucinate.** If a file can't be read, skip it. If an agent fails, fall back to sequential processing.
