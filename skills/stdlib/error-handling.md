# Error Handling

How to handle failures at each step of the recursion engine. Core principle: **degrade gracefully, never hallucinate.**

---

## By Recursion Step

### Sense Failures

| Failure | Response |
|---------|----------|
| Permission denied on file | Skip file, note in uncovered_files |
| File exceeds 100KB | Skip — likely generated or vendored |
| Scope has >1000 files | Partition into sub-scopes before sensing |
| Directory does not exist | Report error to user, abort this scope |

### Understand Failures

| Failure | Response |
|---------|----------|
| Cannot determine feature boundaries | Present file list to user, ask for guidance |
| Feature count outside 10-25 range | Present proposed tree to user for confirmation |
| Files don't cluster naturally | Use directory structure as fallback grouping |

### Extract Failures

| Failure | Response |
|---------|----------|
| File is binary or unreadable | Skip, add to uncovered_files |
| Cannot determine WHY for a file | Skip — no spec is better than a wrong spec |
| Confidence below 0.5 | Do not save the spec |
| Token/context limit approaching | Summarize remaining files, extract only high-level specs |

### Split Failures

| Failure | Response |
|---------|----------|
| Cannot create meaningful sub-scopes | Do not split, process all files at current level |
| Sub-scope would have <5 files | Merge with nearest sibling sub-scope |

### Recurse Failures

| Failure | Response |
|---------|----------|
| Agent spawn fails | Fall back to sequential processing in main context |
| Agent produces malformed output | Discard result, retry once, then skip that scope |
| Agent times out | Process that scope sequentially in main context |

### Merge Failures

| Failure | Response |
|---------|----------|
| Duplicate spec IDs | Keep higher-confidence version |
| Conflicting feature assignments | Prefer the assignment with more file affinity |
| Quality gate fails | Flag for user review, do not silently drop |

---

## General Principles

1. **Skip over hallucinate.** If you cannot confidently extract knowledge, leave it blank.
2. **Report over hide.** When something fails, include it in uncovered_files or report to user.
3. **Fallback over abort.** If parallel fails, go sequential. If git fails, use file system.
4. **Ask over guess.** When ambiguous, present the situation to the user rather than making a silent judgment call.
