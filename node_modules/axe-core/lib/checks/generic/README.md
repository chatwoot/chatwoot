Generic checks are evaluate functions that are used by multiple checks. They cannot be used directly by a rule (thus there is no check meatadata file associated with them) and must be used by another check passing in the required options.

To use these checks, pass the check id (found in the metadata-function-map file) as the value of a checks `evaluate` property and pass any required options.

```json
{
  "id": "my-check",
  "evaluate": "generic-check-id",
  "options": {
    "required": true
  }
}
```
