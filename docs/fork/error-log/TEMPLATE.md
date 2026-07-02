# <Short title of the error>

- **Date**: YYYY-MM-DD
- **Phase**: (Phase 0–7 from IMPLEMENTATION_PLAN.md)
- **Area**: backend / frontend / docker / db / webhook / ci

## Symptom

Exact error message / failing command output (redact secrets):

```text
<paste here>
```

## Root cause

One or two sentences on the actual cause (not the first hypothesis).

## Fix

What changed, with file paths. Include the command if it was a
config/infra fix.

## Verification

The command that proves it's fixed, e.g.:

```sh
docker compose run --rm rails bundle exec rspec spec/custom/...
```

## Notes / related

Links to related entries, upstream issues, or docs.
