# Output System

How to render skill output. Clean plain text with unicode markers. No external dependencies.

Load this at the Report step of any skill.

---

## Templates

### Build — Completion

```
◆ ShadowRepo Build Complete

  Repository:  {repo_name}

  Features:
    {count} features ({root} root, {sub} sub-features)
    {biz} business · {plat} platform · {cross} cross-cutting

  Specs:
    {total} specs
    intent {n} · decision {n} · constraint {n}
    contract {n} · convention {n} · context {n} · change {n}

  Coverage: {percent}% ({covered}/{total} files)

  → Written to .shadowrepo/
```

### Build — Progress

```
◆ ShadowRepo Build — {repo_name}

  ├─ ✓ Sense       {file_count} files discovered
  ├─ ✓ Understand   {feature_count} features proposed
  ├─ ● Extract      {done}/{total} files
  │   ├─ ✓ {feature}     {n} specs
  │   ├─ ✓ {feature}     {n} specs
  │   ├─ ● {feature}      processing...
  │   └─ ◌ {feature}      queued
  └─ ◌ Merge        waiting
```

### Check — Drift Found

```
◆ ShadowRepo Check
  {ref_short}..HEAD ({commit_count} commits)

  Files:  {mod} modified · {add} added · {del} deleted
  Specs:  {affected} affected · {gaps} new gaps

  Drifts:

    ▲ HIGH
      {spec_id}
      → {file} modified

    ■ MEDIUM
      {spec_id}
      → {file} modified

    ● LOW
      {spec_id}
      → {file} deleted (anchor orphaned)

  New gaps:
    {file}
    {file}

  → Run /shadowrepo-update to resolve
```

### Check — No Drift

```
◆ ShadowRepo Check
  {ref_short}..HEAD ({commit_count} commits)

  ✓ No drift detected. ShadowRepo is up to date.
```

### Update — Completion

```
◆ ShadowRepo Update Complete

  Resolved {count} drifts:
    ✓ {n} specs re-extracted
    ✓ {n} anchors updated (renames)
    ✓ {n} specs marked stale

  New: +{n} specs from {n} gap files

  Specs: {total} total ({active} active, {stale} stale)
  Coverage: {percent}%

  → .shadowrepo/ updated
```

### Feature Tree

```
◆ Feature Tree — {repo_name}

  {repo} (root)
  │
  ├─■ {feature}           business   {n} specs  {n} files
  │  ├── {sub-feature}    business   {n} specs  {n} files
  │  └── {sub-feature}    business   {n} specs  {n} files
  │
  ├─■ {feature}           platform   {n} specs  {n} files
  │
  ├─◇ {feature}           cross-cut  {n} specs
  │
  └─◇ {feature}           cross-cut  {n} specs

  ■ owns files  ◇ cross-cutting (patterns only)
```

### Help

```
◆ ShadowRepo
  Semantic Code Knowledge Graph

  Commands:

    /shadowrepo-build    Build feature tree + spec graph
    /shadowrepo-check    Detect code-spec drift
    /shadowrepo-update   Fix drifted specs
    /shadowrepo-render   Generate docs from specs
    /shadowrepo-preview  Impact assessment (coming soon)
    /shadowrepo-help     Show this screen

  Workflow:

    build → code → check → update → render
```

---

## Conventions

| Symbol | Meaning |
|--------|---------|
| `◆` | ShadowRepo branding |
| `✓` | Completed / success |
| `●` | In progress |
| `◌` | Queued / pending |
| `▲` | High severity |
| `■` | Medium severity / owns files |
| `●` | Low severity |
| `◇` | Cross-cutting feature |
| `├─` `└─` `│` | Tree connectors |
