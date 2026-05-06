# ShadowRepo Dashboard — Design Brief

**For:** External designer
**Status:** v0 brief, open to interpretation
**Deliverable:** Visual design + functional prototype (or annotated mockups) for the dashboard

---

## 1. What ShadowRepo is (one paragraph)

ShadowRepo scans a codebase and extracts a **semantic knowledge graph** — features (what the code does), specs (why it's written this way), and the connections between them. The dashboard is a **read-only viewer** for that graph. Its job is to let people who didn't write the code (PMs, designers, new engineers) understand the codebase **without asking the engineers**.

Think: Wikipedia for a codebase, generated automatically.

---

## 2. Who uses it

Three personas, in order of importance:

| Persona | What they want |
|---------|----------------|
| **New engineer** (Day 1-30) | Understand the codebase top-down. "What does this project do? What are the major pieces? Why is X built this way?" |
| **PM / designer** | Investigate a concept without bothering an engineer. "How does our auth work? What constraints govern data retention?" |
| **Returning engineer** | Recall context. "Why did we make this decision 6 months ago? What's changed in this area recently?" |

**Not the audience:** The original engineer who wrote the code. They already know it.

---

## 3. The data (this is what you're visualizing)

After ShadowRepo scans a repo, the output is **4 JSON files** in `.shadowrepo/`:

### `meta.json` — repo metadata
```json
{
  "repo_name": "claude-code",
  "built_at": "2026-04-13T23:33:55Z",
  "build_status": "COMPLETE",
  "stats": { "total_files": 1902, "total_features": 36, "total_specs": 629, "coverage_percent": 95 }
}
```

### `features.json` — the feature tree (~36 entries for a medium repo)
```json
[
  {
    "feature_id": "ui-components/permissions",
    "name": "UI Components / Permissions",
    "type": "business",  // or "platform" or "cross-cutting"
    "description": "16 specs covering 51 files",
    "key_files": ["src/permissions/PermissionRequest.tsx", ...],
    "parent": "ui-components"  // null for root features
  }
]
```

Features form a **tree** (parent-child). 3 types:
- **business** — core product features
- **platform** — infrastructure (auth, db, transport)
- **cross-cutting** — shared utilities

### `specs.json` — the knowledge graph (~600 entries for a medium repo)
```json
[
  {
    "spec_id": "auth/decision/jwt-over-sessions",
    "feature_name": "auth",
    "type": "decision",  // see types below
    "summary": "Use JWT instead of server sessions for stateless scaling.",
    "detail": "Long-form explanation with rationale, trade-offs, alternatives considered...",
    "anchors": [{ "file": "src/auth/jwt.ts", "line_range": [12, 45] }],
    "relations": [
      { "type": "depends_on", "target_spec_id": "auth/contract/token-format" }
    ],
    "confidence": 0.9,
    "provenance": "code_scan",  // or "documentation" or "git_history"
    "state": "active"  // or "stale"
  }
]
```

**Spec types** (this is the knowledge taxonomy):

| Type | Means | Example |
|------|-------|---------|
| `intent` | Why this feature exists | "Permission UI lets users grant/revoke per-tool access" |
| `decision` | A choice that was made | "Chose JWT over sessions for stateless scaling" |
| `constraint` | A hard rule the system must respect | "Never log auth tokens" |
| `contract` | An interface or protocol | "PermissionRequest props: { tool, scope, onGrant }" |
| `convention` | A pattern applied consistently | "All hooks live in src/hooks/, prefixed with `use`" |
| `context` | Background/situational info | "This was migrated from v1 in 2025" |
| `change` | Something in flux | "Currently refactoring routing — see ADR-042" |

### `coverage.json` — file coverage map
```json
{
  "covered_files": ["src/auth/jwt.ts", ...],     // files referenced by at least one spec
  "uncovered_files": ["src/utils/legacy.ts", ...],
  "coverage_percent": 95
}
```

---

## 4. The 7 functions the dashboard must support

Listed by priority. **Function 1 is the most important; Function 7 is nice-to-have.**

### F1 — Orient
> "I just opened this. What is this project? What are its major pieces?"

Single-screen overview a stranger can read in 30 seconds: project name, scale (size signals), top-level features grouped by type, headline stats. Should feel like a magazine cover, not a control panel.

### F2 — Navigate
> "Take me from the whole repo down to a specific spec, step by step."

Hierarchical drill-down: repo → feature → sub-feature → spec → anchored file. User must always know **where they are** (breadcrumbs or equivalent) and how to **back up**. URL should reflect location (so users can share links).

### F3 — Search
> "I want to find anything mentioning 'rate limit' or 'webhook' fast."

Strong full-text search across spec summaries, details, IDs, and feature names. Fuzzy. Keyboard-accessible (Cmd+K). Should feel like VSCode's Cmd+P or Linear's command palette — the **dominant interaction** for power users.

### F4 — Inspect a spec
> "Show me everything about this one spec."

For any single spec: summary, full detail, type, confidence, provenance, all anchors (file paths, ideally clickable to view in code), all relations to other specs (clickable). This is the "leaf" view — the most-detailed thing.

### F5 — Relate
> "Show me what's connected to this."

From any spec, jump to its related specs (relations), the feature it belongs to, and the files it anchors. From any feature, see all specs in it. From any file, see all specs anchored to it. **The graph must be navigable, not just visualized.**

### F6 — Filter by lens
> "Show me all the architectural decisions, regardless of feature."
> "Show me all specs anchored to files in src/auth/."

Three valid ways to slice the same data:
- **By feature** (functional decomposition)
- **By type** (decision / constraint / contract / etc.)
- **By file path** (code locality)

User should be able to switch lenses fluidly.

### F7 — Assess coverage & change
> "Where are the documentation gaps?"
> "What got added/changed since last build?"

Identify uncovered areas (files with no specs, features with sparse specs). Surface stale specs. Show a "what's new" view if comparing two builds is feasible (lower priority — single-build view is fine for v1).

---

## 5. Constraints

**Hard:**
- Single static HTML file. No build step. No npm install.
- Zero external dependencies (no React/Vue/D3 from CDN). All JS/CSS inline.
- Must work via `file://` protocol (data inlined into the HTML at build time — see current implementation).
- Read-only — dashboard never mutates data.
- Modern browsers only (Chrome/Safari/Firefox latest 2). No IE.

**Soft:**
- Should feel polished. Tools like Linear, Raycast, GitHub's UI are good calibration points.
- Dark mode is the default; light mode is a bonus.
- Mobile-friendly is a bonus (most users will be on desktop).
- Accessible: keyboard nav, focus rings, semantic HTML, screen reader friendly.

---

## 6. Anti-goals (please don't)

- ❌ Don't make it a generic admin dashboard. This is a **knowledge tool**, not a CRUD app.
- ❌ Don't lead with a force-directed graph. We tried it. It's vanity — looks cool, doesn't help anyone navigate.
- ❌ Don't put a giant headline number in every corner. We don't need 4 stat cards on the home view.
- ❌ Don't centerline-everything-in-cards. Avoid the SaaS template look (3-column feature grid, icon-in-circle headers, gradient blobs).
- ❌ Don't require the user to read documentation to use it. Information architecture should be self-evident.

---

## 7. Reference materials

| What | Where |
|------|-------|
| Current dashboard (v2) | `skills/build/dashboard.html` — open it locally to see what we have today |
| Sample data (real, large) | `/Users/waynewang/claude-code/.shadowrepo/` — claude-code repo, 36 features / 629 specs / 95% coverage |
| Product positioning | `spec/Core/Product.md` — one-pager on what ShadowRepo is for |
| Data model details | `skills/stdlib/data-model.md` — full schema |
| Tone references | Linear (linear.app), Raycast (raycast.com), Notion's docs, Obsidian's graph view (with caveats — see anti-goals) |

---

## 8. Deliverables we'd love

Pick the format that lets you do your best work; we don't insist:

**Option A — Annotated Figma mockups**
- 5-8 key screens (orient / feature page / spec detail / search / coverage view / etc.)
- Notes on interactions and transitions
- Component spec for cards, search, navigation

**Option B — Functional HTML prototype**
- Single HTML file we can open
- Real sample data wired in (use the claude-code dataset above)
- Doesn't need to implement every function — focus on F1-F4

**Option C — Interaction prototype + style guide**
- Style guide (typography, color, spacing, components)
- Click-through prototype showing 2-3 user journeys

We'll pair on whichever format makes sense.

---

## 9. Success criteria

We'll know it's working when:

- A new engineer can use it for 10 minutes and explain the codebase's major pieces back to us.
- A PM asks "how does X work" and finds the answer in <60 seconds without help.
- The interface holds up at 36 features and 629 specs (real scale) without feeling cluttered.
- Hovering, clicking, and typing all feel **fast** — no spinner ever shows for >100ms on local data.
- It doesn't look like a generated SaaS template. It looks like a tool someone cared about.

---

## 10. Open questions for the designer

These are things we don't have strong opinions on — we'd value your judgment:

- **Home view as feature list vs. dashboard vs. search-first?** We think search-first or feature-list, but open.
- **How prominent should `confidence` be?** It's a 0-1 score per spec. Useful for filtering low-confidence specs but might add noise.
- **How to surface `relations` between specs?** We tried a global graph (failed). Consider: in-card list, side panel, hover preview, or a focused local graph (one spec + neighbors).
- **What does a "feature page" look like?** Wikipedia article? Notion page? Card grid? Open.
- **Does the dashboard need light mode at all?** Or is dark-mode-only fine for v1?

---

## 11. Out of scope (don't worry about these)

- Authoring / editing specs (read-only)
- Multi-repo support (one repo at a time)
- Real-time updates (the data is generated by a CLI; dashboard reads a static snapshot)
- Comparing two snapshots (nice-to-have, but not required for v1)
- Server / backend work (everything is a static file)
- Building the data pipeline (that's the `/shadowrepo build` skill, not your concern)

---

## Contact

Questions: ping @waynewang. Don't be shy — the brief is intentionally light on visual prescription so you can do real design work.
