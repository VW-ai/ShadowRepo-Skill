# Merge Result Contract

The output of each recursion agent. Written to a temp file, collected by the synthesizer.

## Schema

```json
{
  "scope_id": "string — matches the input scope's scope_id",
  "features": ["Feature[] — discovered/updated features at this scope level"],
  "specs": ["Spec[] — extracted specs"],
  "uncovered_files": ["string[] — files that could not be meaningfully analyzed"],
  "stats": {
    "files_read": "number",
    "specs_extracted": "number"
  }
}
```

## Temp File Protocol

Each agent writes its result to: `.shadowrepo/.tmp/{scope_id}.json`

- File name = scope_id with `/` replaced by `--` (e.g. `src--auth.json`)
- Only the agent for that scope writes to that file
- Synthesizer reads all temp files, merges, then deletes `.shadowrepo/.tmp/`

## Merge Rules

When synthesizer combines multiple merge-results:

1. **Features**: Deduplicate by `feature_id`. If two scopes discovered the same feature, keep the one with more `key_files`.
2. **Specs**: Deduplicate by anchor overlap. If two specs anchor to the same file with overlapping knowledge, keep the higher-confidence one.
3. **Uncovered files**: Union of all uncovered files.
4. **Stats**: Sum across all results.
