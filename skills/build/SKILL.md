---
name: shadowrepo-build
description: >
  Cold-start a ShadowRepo for a codebase. Scans the entire repo, builds a feature tree
  and spec graph, writes structured JSON to .shadowrepo/. Use when: "build shadowrepo",
  "scan this project", "create a shadow repo", or first-time setup.
---

# ShadowRepo Build

Cold-start: scan the entire repo, build feature tree + spec graph, write to `.shadowrepo/`.

## Prerequisites

1. Read `stdlib/methodology.md` — extraction rules and quality standards
2. Read `stdlib/data-model.md` — types (Spec, Feature, Anchor, Relation)
3. Read `stdlib/recursion-engine.md` — the execution pattern you will follow
4. Read `stdlib/file-discovery.md` — what to include/exclude

## Precondition Check

1. Check if `.shadowrepo/` already exists in the target repo:
   - If yes: warn user "A shadowRepo already exists. This will rebuild from scratch. Continue?"
   - If user declines: suggest `/shadowrepo check` or `/shadowrepo update` instead
2. Verify the target path is a valid directory with source files

## Execution

### Step 1: Create Root Scope

Construct the initial scope covering the entire repo:

```
scope = {
  scope_id: "root",
  parent_scope_id: null,
  depth: 0,
  target_repo_path: <current working directory>,
  files: <all source files after applying file-discovery rules>,
  context: {
    existing_features: [],
    existing_specs: [],
    parent_understanding: null
  },
  mode: "full"
}
```

Use Glob to find all files. Apply `file-discovery.md` to classify and filter.

### Step 2: Run Recursion Engine

Follow `stdlib/recursion-engine.md` with the root scope:

1. **Sense** — read manifests, README, directory structure
2. **Understand** — propose initial feature tree
3. **Extract** — read source files, extract specs
4. **Split** — if >50 source files, create sub-scopes
5. **Recurse** — spawn agents for sub-scopes (if split)
6. **Merge** — collect results, apply quality gates

The engine handles the recursive decomposition. You orchestrate the root level.

### Step 3: Write Output

After the root merge completes, write the final JSON files:

1. `.shadowrepo/features.json` — the feature tree (per `contracts/feature.md`)
2. `.shadowrepo/specs.json` — all specs (per `contracts/spec.md`)
3. `.shadowrepo/coverage.json` — file coverage map:
   ```json
   {
     "covered_files": ["string[] — files with at least one anchored spec"],
     "uncovered_files": ["string[] — files with no specs"],
     "coverage_percent": "number"
   }
   ```
4. `.shadowrepo/meta.json` — repo metadata:
   ```json
   {
     "repo_name": "string",
     "repo_path": "string",
     "last_commit_hash": "string | null",
     "built_at": "string — ISO8601",
     "stats": {
       "total_files": "number",
       "total_features": "number",
       "total_specs": "number",
       "coverage_percent": "number"
     }
   }
   ```

### Step 4: Clean Up

- Delete `.shadowrepo/.tmp/` directory (temp agent results)

### Step 5: Report

Output a summary to the user:

```
ShadowRepo built successfully.

Features:  {count} ({root_count} root, {sub_count} sub-features)
Specs:     {count} (density: {specs_per_100_files}/100 files)
Coverage:  {percent}% ({covered}/{total} files)
Types:     {intent}i / {decision}d / {constraint}cn / {contract}ct / {convention}cv / {context}cx / {change}ch

Written to .shadowrepo/
```

## Error Handling

Follow `stdlib/error-handling.md`. Key points:

- If a file can't be read: skip, note in coverage report
- If agent fails: fall back to sequential processing
- If feature tree doesn't converge: present to user for guidance
- If spec density is outside target: flag but still save (don't block on quality gate)
